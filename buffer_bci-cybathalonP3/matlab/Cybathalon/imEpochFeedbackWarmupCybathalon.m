configureIM;
if ( ~exist('epochFeedbackTrialDuration') || isempty(epochFeedbackTrialDuration) )
  epochFeedbackTrialDuration=trialDuration;
end;


rtbDuration=.5; %.5s between commands

cybathalon = struct('host','localhost','port',5555,'player',1,...
                    'cmdlabels',{{'jump' 'slide' 'speed' 'rest'}},'cmddict',[2 3 1 99],...
						  'cmdColors',[.6 0 .6;.6 .6 0;0 .5 0;.3 .3 .3]',...
                    'socket',[],'socketaddress',[]);
% open socket to the cybathalon game
[cybathalon.socket]=javaObject('java.net.DatagramSocket'); % create a UDP socket
cybathalon.socketaddress=javaObject('java.net.InetSocketAddress',cybathalon.host,cybathalon.port);
cybathalon.socket.connect(cybathalon.socketaddress); % connect to host/port
connectionWarned=0;


if ( baselineClass ) % with rest targets
  tgtSeq=mkStimSeqRand(nSymbs+1,nSeq);
else
  tgtSeq=mkStimSeqRand(nSymbs,nSeq);
end

% make the stimulus display
fig=figure(2);
clf;
set(fig,'Name','Imagined Movement','color',winColor,'menubar','none','toolbar','none','doublebuffer','on');
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',winColor,'DrawMode','fast','nextplot','replacechildren',...
        'xlim',[-1.5 1.5],'ylim',[-1.5 1.5],'Ydir','normal');

stimPos=[]; h=[];
stimRadius=diff(axLim)/4;
cursorSize=stimRadius/2;
theta=linspace(0,2*pi,nSymbs+1) + pi/2; % 1st post=N
theta=theta(1:end-1);
stimPos=[cos(theta);sin(theta)];
for hi=1:nSymbs; 
  % set tgt to the color of that part of the game
  h(hi)=rectangle('curvature',[1 1],'position',[stimPos(:,hi)-stimRadius/2;stimRadius*[1;1]],...
                  'facecolor',cybathalon.cmdColors(:,hi));

  if ( ~isempty(symbCue) ) % cue-text
	 htxt(hi)=text(stimPos(1,hi),stimPos(2,hi),{symbCue{hi} '->' cybathalon.cmdlabels{hi}},...
						'HorizontalAlignment','center',...
						'fontunits','pixel','fontsize',.05*wSize(4),...
						'color',txtColor,'visible','on');
  end  
end;
% add symbol for the center of the screen
stimPos(:,nSymbs+1)=[0 0];
h(nSymbs+1)=rectangle('curvature',[1 1],'position',[stimPos(:,end)-stimRadius/4;stimRadius/2*[1;1]],...
                      'facecolor',bgColor); 
set(gca,'visible','off');

%Create a text object with no text in it, center it, set font and color
set(fig,'Units','pixel');wSize=get(fig,'position');set(fig,'units','normalized');% win size in pixels
txthdl = text(mean(get(ax,'xlim')),mean(get(ax,'ylim')),' ',...
				  'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle',...
				  'fontunits','pixel','fontsize',.05*wSize(4),...
				  'color',txtColor,'visible','off');

set(txthdl,'string', 'Click mouse when ready', 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow;

% play the stimulus
set(h(end),'facecolor',bgColor);
sendEvent('stimulus.testing','start');
% initialize the state so don't miss classifier prediction events
state=[]; 
endTesting=false; dvs=[];
waitforkeyTime=getwTime()+calibrateMaxSeqDuration;
for si=1:max(100000,size(tgtSeq,2));

  if ( ~ishandle(fig) || endTesting ) break; end;
  
  % show the target
  tgtIdx=find(tgtSeq(:,si)>0);
  set(h(tgtSeq(:,si)>0),'facecolor',[0 1 0]); % super-green
  %set(h(tgtSeq(:,si)<=0),'facecolor',bgColor);
  if ( ~isempty(baselineClass) && tgtSeq(nSymbs+1,si)<=0 )%green fixation indicates trial running, if its not actually the target
	 set(h(end),'facecolor',tgtColor);
  end
  if ( ~isempty(symbCue) )
	 if ( all(tgtIdx<=nSymbs) )
		set(txthdl,'string',sprintf('%s ',symbCue{tgtIdx}),'color',txtColor,'visible','on');
		tgtNm = '';
		for ti=1:numel(tgtIdx);
		  if(ti>1) tgtNm=[tgtNm ' + ']; end;
		  tgtNm=sprintf('%s%d %s ',tgtNm,tgtIdx,symbCue{tgtIdx});
		end
	 elseif ( tgtIdx==nSymbs+1 ) % rest class
		tgtNm=baselineClass;
		set(txthdl,'string','rest','color',txtColor,'visible','on');
	 end
  else
	 tgtNm = tgtIdx; % human-name is position number
  end
  fprintf('%d) tgt=%10s : ',si,tgtNm);
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  if ( earlyStopping )
	 % cont-classifier, so tell it to clear the prediction filter for start new trial
	 sendEvent('classifier.reset','now'); 
  else
	 % event-classifier, so send the event which triggers to classify this data-block
	 sendEvent('classifier.apply','now'); % tell the classifier to apply from now
  end
  trlStartTime=getwTime();
  ev=sendEvent('stimulus.trial','start');
  state=buffer('poll'); % Ensure we ignore any predictions before the trial start  
  if( verb>0 )
	 fprintf(1,'Waiting for predictions after: (%d samp, %d evt)\n',...
				state.nSamples,state.nEvents);
  end;
  if ( earlyStopping )
	 sendEvent('stimulus.target',tgtNm);% TODO: make this work with early stopping

			 % wait for new prediction events to process *or* end of trial time	 
	 [devents,state,nevents,nsamples]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],epochFeedbackTrialDuration*1000+1500);
  else
	 for ei=1:ceil(trialDuration./epochDuration);
		sendEvent('stimulus.target',tgtNm);
		drawnow;% expose; % N.B. needs a full drawnow for some reason
				  % wait for trial end
		sleepSec(epochDuration);
	 end
    %sleepSec(epochFeedbackTrialDuration); 
	 % wait for classifier prediction event
	 [devents,state,nevents,nsamples]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],2000);
  end
  trlEndTime=getwTime();
  
  % do something with the prediction (if there is one), i.e. give feedback
  if( isempty(devents) ) % extract the decision value
    fprintf(1,'Error! no predictions after %gs, continuing (%d samp, %d evt)\n',trlEndTime-trlStartTime,state.nSamples,state.nEvents);
	 for hi=1:nSymbs; set(h(hi),'facecolor',cybathalon.cmdColors(:,hi)); end
    set(h(end),'facecolor',bgColor);
    drawnow;
  else
	 if ( any([devents.sample]<ev.sample) ) % check for escaping predictions
		warning('prediction from before the trial start!');
	 end
	 fprintf(1,'Prediction after %gs : %s',trlEndTime-trlStartTime,ev2str(devents(end)));
    dv = devents(end).value;
    if ( numel(dv)==1 )
      if ( dv>0 && dv<=nSymbs && isinteger(dv) ) % dvicted symbol, convert to dv equivalent
        tmp=dv; dv=zeros(nSymbs,1); dv(tmp)=1;
      else % binary problem, convert to per-class
        dv=[dv -dv];
      end
    end    
    % give the feedback on the predicted class
    prob=exp((dv-max(dv))); prob=prob./sum(prob); % robust soft-max prob computation
    if ( verb>=0 ) 
		fprintf('%d) dv:[%s]\tPr:[%s]\n',ev.sample,sprintf('%5.4f ',dv),sprintf('%5.4f ',prob));
    end;  
    [ans,predTgt]=max(dv); % prediction is max classifier output
    set(h(end),'facecolor',bgColor);
    set(h(predTgt),'facecolor',fbColor);
    drawnow;
    sendEvent('stimulus.predTgt',predTgt);
										  % send the command to the game server
	 try;
		cybathalon.socket.send(javaObject('java.net.DatagramPacket',uint8([10*cybathalon.player+cybathalon.cmddict(predTgt) 0]),1));
	 catch;
		if ( connectionWarned<10 )
		  connectionWarned=connectionWarned+1;
		  warning('Error sending to the Cybathalon game.  Is it running?\n');
		end
	 end

										  % now wait a little to give some RTB time
	 drawnow;
	 sleepSec(rtbDuration);
	 % reset the cue and fixation point to indicate trial has finished  
	 for hi=1:nSymbs; set(h(hi),'facecolor',cybathalon.cmdColors(:,hi)); end
	 set(h(end),'facecolor',bgColor); % clear the feedback
	 sendEvent('stimulus.trial','end');
	 
  end % if classifier prediction  
  drawnow;
  
end % loop over sequences in the experiment

% BODGE: don't send end-testing marker..... as we'll continue with the real part in a minute
										  %sendEvent('stimulus.testing','end');
