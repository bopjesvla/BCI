configureIM;
if ( ~exist('epochFeedbackTrialDuration') || isempty(epochFeedbackTrialDuration) )
  epochFeedbackTrialDuration=trialDuration;
end;


rtbDuration=.5; %.5s between commands
timeframe = 3; %3s timeframe used for prediction analysis

cybathalon = struct('host','localhost','port',5555,'player',1,...
                    'cmdlabels',{{'jump' 'slide' 'speed' 'rest'}},'cmddict',[2 3 1 99],...
						  'cmdColors',[.6 0 .6;.6 .6 0;0 .5 0;.3 .3 .3]',...
                    'socket',[],'socketaddress',[]);
% open socket to the cybathalon game
[cybathalon.socket]=javaObject('java.net.DatagramSocket'); % create a UDP socket
cybathalon.socketaddress=javaObject('java.net.InetSocketAddress',cybathalon.host,cybathalon.port);
cybathalon.socket.connect(cybathalon.socketaddress); % connect to host/port
connectionWarned=0;

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
predictions = [];
t = tic;
for si=1:max(100000,nSeq);

  if ( ~ishandle(fig) || endTesting ) break; end;
  
  %set(h(tgtSeq(:,si)>0),'facecolor',tgtColor);
  set(h(end),'facecolor',tgtColor); % green fixation indicates trial running
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
	 % wait for new prediction events to process *or* end of trial time
	 [devents,state,nevents,nsamples]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],epochFeedbackTrialDuration*1000+1500);
  else
    sleepSec(epochFeedbackTrialDuration); 
	 % wait for classifier prediction event
	 [devents,state,nevents,nsamples]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],2000);
  end
  trlEndTime=getwTime();
  
  % do something with the prediction (if there is one), i.e. give feedback
  if( isempty(devents) ) % extract the decision value
    fprintf(1,'Error! no predictions after %gs, continuing (%d samp, %d evt)\n',trlEndTime-trlStartTime,state.nSamples,state.nEvents);
    set(h(end),'facecolor',bgColor);
    set(h(end),'facecolor',fbColor); % fix turns blue to show now pred recieved
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
    
    
    
    
    
    %CUSTOM CODE
    %remove predictions that are too old (more than 3s)
    while ( size(predictions,1)>0 && predictions(1,1)<(toc(t)-timeframe) )
      predictions = predictions(2:size(predictions),:);
    end
    
    %add current prediction to set of predictions
    predictions(end+1,:) = [toc(t) int2task(predTgt)];
    
    %determine target command with highest expected speed
    if size(predictions) > 0
        correct = 'true'
        bestTgt = task2int(bestCommand(predictions(:,2)));
    else
        correct = 'false'
        bestTgt = predTgt;
    end
        
    
    sendEvent('stimulus.predTgt',bestTgt);
										  % send the command to the game server
	 try;
		cybathalon.socket.send(javaObject('java.net.DatagramPacket',uint8([10*cybathalon.player+cybathalon.cmddict(bestTgt) 0]),1));
	 catch;
		if ( connectionWarned<10 )
		  connectionWarned=connectionWarned+1;
		  warning('Error sending to the Cybathalon game.  Is it running?\n');
		end
	 end
   %----------------------------------------------------------------------------------------
  
  
  
  
  
  
										  % now wait a little to give some RTB time
	 drawnow;
	 sleepSec(rtbDuration);
	 set(h(predTgt),'facecolor',cybathalon.cmdColors(:,predTgt));
	 set(h(end),'facecolor',bgColor); % clear the feedback
	 
  end % if classifier prediction  
  drawnow;
  
end % loop over sequences in the experiment
% end training marker
sendEvent('stimulus.testing','end');

if ( ishandle(fig) ) % thanks message
set(txthdl,'string',{'That ends the testing phase.','Thanks for your patience'}, 'visible', 'on', 'color',[0 1 0]);
pause(3);
end
