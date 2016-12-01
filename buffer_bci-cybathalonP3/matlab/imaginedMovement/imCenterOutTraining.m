% continous feedback within a cued trial based structure, with goal to complete the training as fast as possible
configureIM;
if(~exist('centerOutTrialDuration') || isempty(centerOutTrialDuration)) centerOutTrialDuration=trialDuration; end;

% make the target sequence
tgtSeq=mkStimSeqRand(nSymbs,nSeq);

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
theta=linspace(0,2*pi,nSymbs+1);
if ( mod(nSymbs,2)==1 ) theta=theta+pi/2; end; % ensure left-right symetric by making odd 0=up
theta=theta(1:end-1);
stimPos=[cos(theta);sin(theta)];
for hi=1:nSymbs; 
  h(hi)=rectangle('curvature',[1 1],'position',[stimPos(:,hi)-stimRadius/2;stimRadius*[1;1]],...
                  'facecolor',bgColor); 
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


% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'facecolor',bgColor);

% wait for user to become ready
set(txthdl,'string', {centerout_instruct{:} '' 'Click mouse when ready'}, 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow;

sendEvent('stimulus.testing','start');

for si=1:nSeq;

  if ( ~ishandle(fig) ) break; end;
  
  sleepSec(intertrialDuration);
  % show the screen to alert the subject to trial start
  set(h(:),'faceColor',bgColor);
  set(h(end),'facecolor',fixColor); % red fixation indicates trial about to start/baseline
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.baseline','start');
  sleepSec(baselineDuration);
  sendEvent('stimulus.baseline','end');

  % show the target
  fprintf('%d) tgt=%d : ',si,find(tgtSeq(:,si)>0));
  set(h(tgtSeq(:,si)>0),'facecolor',tgtColor);
  set(h(tgtSeq(:,si)<=0),'facecolor',bgColor);
  if ( ~isempty(symbCue) )
	 set(txthdl,'string',sprintf('%s ',symbCue{tgtSeq(:,si)>0}),'color',txtColor,'visible','on');
  end
  set(h(end),'facecolor',tgtColor); % green fixation indicates trial running
  drawnow;% expose; % N.B. needs a full drawnow for some reason
  sendEvent('stimulus.target',find(tgtSeq(:,si)>0));
  sendEvent('stimulus.trial','start');
  
  % for the trial duration update the fixatation point in response to prediction events
  % initial fixation point position
  fixPos = stimPos(:,end);
  state  = [];
  dv     = zeros(nSymbs,1);
  prob   = ones(nSymbs,1)./nSymbs; % start with equal prob over everything
  trlStartTime=getwTime();
  timetogo = centerOutTrialDuration;
  while (timetogo>0)
    timetogo = trialDuration - (getwTime()-trlStartTime); % time left to run in this trial
    % wait for new prediction events to process *or* end of trial time
    [events,state,nsamples,nevents] = buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],min(1000,timetogo*1000));
    if ( isempty(events) ) 
		if ( timetogo>.1 ) fprintf('%d) no predictions!\n',nsamples); end;
    else
		[ans,si]=sort([events.sample],'ascend'); % proc in *temporal* order
      for ei=1:numel(events);
        ev=events(si(ei));% event to process
		  %fprintf('pred-evt=%s\n',ev2str(ev));
        pred=ev.value;
        % now do something with the prediction....
        if ( numel(pred)==1 )
          if ( pred>0 && pred<=nSymbs && isinteger(pred) ) % predicted symbol, convert to dv equivalent
            tmp=pred; pred=zeros(nSymbs,1); pred(tmp)=1;
          else % binary problem
            pred=[pred -pred];
          end
        end

		  % additional prediction smoothing for display, if wanted
		  if ( ~isempty(stimSmoothFactor) && isnumeric(stimSmoothFactor) && stimSmoothFactor>0 )
			 if ( stimSmoothFactor>=0 ) % exp weighted moving average
				dv=dv*stimSmoothFactor + (1-stimSmoothFactor)*pred(:);
			 else % store predictions in a ring buffer
				fbuff(:,mod(nEpochs-1,abs(stimSmoothFactor))+1)=pred(:);% store predictions in a ring buffer
				dv=mean(fbuff,2);
			 end
		  else
			 dv=pred;
		  end

		  % convert from dv to normalised probability
        prob = 1./(1+exp(-dv)); prob=prob./sum(prob); % convert from dv to normalised probability
        if ( verb>=0 ) 
			 fprintf('%d) dv:[%s]\tPr:[%s]\n',ev.sample,sprintf('%5.4f ',pred),sprintf('%5.4f ',prob));
        end;
      end

	 end % if prediction events to process

    % feedback information... simply move in direction detected by the BCI
	 if ( numel(prob)>=size(stimPos,2)-1 ) % per-target decomposition
		dx = stimPos(:,1:numel(prob))*prob(:); % change in position is weighted by class probs
	 elseif ( numel(prob)==2 ) % direct 2d decomposition
		dx = prob;
	 elseif ( numel(prob)==1 )
		dx = [prob;0];
	 end
    cursorPos=get(h(end),'position'); cursorPos=cursorPos(:);
	 fixPos   =cursorPos(1:2)+.5*cursorPos(3:4); % center of the fix-point
	 % relative or absolute cursor movement
	 if ( warpCursor ) % absolute position on the screen
		fixPos=dx;
		if(feedbackMagFactor>1) fixPos=(fixPos-stimPos(:,end))*feedbackMagFactor + stimPos(:,end); end;
	 else % relative movement
		fixPos=fixPos + dx*moveScale;
	 end;
	 set(h(end),'position',[fixPos-.5*cursorPos(3:4) cursorPos(3:4)]);
    drawnow; % update the display after all events processed    
  end % while time to go

  % reset the cue and fixation point to indicate trial has finished  
  set(h(:),'facecolor',bgColor);
  if ( ~isempty(symbCue) ) set(txthdl,'visible','off'); end
  % also reset the position of the fixation point
  set(h(end),'position',[stimPos(:,end)-stimRadius/4;stimRadius/2*[1;1]]);
  drawnow;
  sendEvent('stimulus.trial','end');
  
  ftime=getwTime();
  fprintf('\n');
end % loop over sequences in the experiment
% end training marker
sendEvent('stimulus.testing','end');

if ( ishandle(fig) ) % thanks message
set(txthdl,'string',{'That ends the feedback phase.','Thanks for your patience'},'color',[0 1 0],'visible', 'on');
pause(3);
end
