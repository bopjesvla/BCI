configureIM;

fig=figure(2);
set(fig,'Name','Imagined Movement -- close window to stop.','color',[0 0 0],'menubar','none','toolbar','none','doublebuffer','on');
clf;
ax=axes('position',[0.025 0.025 .95 .95],'units','normalized','visible','off','box','off',...
        'xtick',[],'xticklabelmode','manual','ytick',[],'yticklabelmode','manual',...
        'color',[0 0 0],'DrawMode','fast','nextplot','replacechildren',...
        'xlim',[-1.5 1.5],'ylim',[-1.5 1.5],'Ydir','normal');
stimPos=[]; h=[];
stimRadius=diff(axLim)/4;
cursorSize=stimRadius/2;
theta=linspace(0,2*pi,nSymbs+1); theta=theta(1:end-1);
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
				  'color',[0.75 0.75 0.75],'visible','off');

% play the stimulus
% reset the cue and fixation point to indicate trial has finished  
set(h(:),'facecolor',bgColor);

% wait for the user to become ready
set(txthdl,'string', 'Click mouse when ready', 'visible', 'on'); drawnow;
waitforbuttonpress;
set(txthdl,'visible', 'off'); drawnow;


sendEvent('stimulus.testing','start');
  
% show the screen to alert the subject to trial start
set(h(:),'faceColor',bgColor);
set(h(end),'facecolor',fixColor); % red fixation indicates trial about to start/baseline
drawnow;% expose; % N.B. needs a full drawnow for some reason
sendEvent('stimulus.baseline','start');
sleepSec(baselineDuration);
sendEvent('stimulus.baseline','end');
set(h(:),'faceColor',bgColor);
drawnow;% expose; % N.B. needs a full drawnow for some reason

% for the trial duration update the fixatation point in response to prediction events
% initial fixation point position
fixPos = stimPos(:,end);
trlStartTime=getwTime();
state=[];
trialDuration = 60*60; % 1hr...
timetogo=trialDuration;
nEpochs=0;
dv  = zeros(nSymbs,1);
prob= ones(nSymbs,1)./nSymbs; % start with equal prob over everything
while (timetogo>0)
  if ( ~ishandle(fig) ) break; end;
  timetogo = trialDuration - (getwTime()-trlStartTime); % time left to run in this trial
  % wait for new prediction events to process *or* end of trial
  [events,state,nsamples,nevents] = buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],min(1500,timetogo*1000));

  % process the prediction events
  if ( ~isempty(events) ) 
    [ans,si]=sort([events.sample],'ascend'); % proc in *temporal* order
    for ei=1:numel(events);
		nEpochs=nEpochs+1;

      ev=events(si(ei));% event to process
      pred=ev.value;
      % now do something with the prediction....
      if ( numel(pred)==1 )
        if ( pred>0 && pred<=nSymbs && isinteger(pred) ) % predicted symbol, convert to dv
          tmp=pred; pred=zeros(nSymbs,1); pred(tmp)=1;
        else % binary problem
          pred=[pred -pred];
        end
      end

		% additional prediction smoothing for display, if wanted
		if ( ~isempty(stimSmoothFactor) && isnumeric(stimSmoothFactor) )
        if ( stimSmoothFactor>=0 ) % exp weighted moving average
			 dv=dv*stimSmoothFactor + (1-stimSmoothFactor)*pred(:);
		  else % store predictions in a ring buffer
			 fbuff(:,mod(nEpochs-1,abs(stimSmoothFactor))+1)=pred(:); % store predictions in a ring buffer
			 dv=mean(fbuff,2);
        end
		end

		% convert from dv to normalised probability
      prob = 1./(1+exp(-dv(:))); prob=prob./sum(prob); 
      if ( verb>=0 ) 
        fprintf('%d) dv:',ev.sample);fprintf('%5.4f ',pred);fprintf('\t\tProb:');fprintf('%5.4f ',prob);fprintf('\n'); 
      end;
      
    end
  else
	 fprintf('%d) no predictions!\n',nsamples);
  end % if prediction events to process
  
  % feedback information... simply move to absolute location indicated by the BCI
  dx     = stimPos(:,1:end-1)*prob(:); % change in position is weighted by class probs
  if ( warpCursor ) fixPos=dx; else fixPos=fixPos + dx*moveScale; end; % relative or absolute cursor movement
  set(h(end),'position',[fixPos-stimRadius/4;(stimRadius/2).*[1;1]]);
  drawnow; % update the display after all events processed

end % while time to go

if ( ishandle(fig) ) % thanks message
set(txthdl,'string',{'That ends the training phase.','Thanks for your patience'}, 'visible', 'on');
pause(3);
end
% end training marker
sendEvent('stimulus.testing','end');
