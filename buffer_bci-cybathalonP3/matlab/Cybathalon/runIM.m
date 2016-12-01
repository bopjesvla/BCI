configureIM;
% add the generic im experiment directory for the generic stimulus files
addpath('../imaginedMovement');
mdir=fileparts(mfilename('fullpath'));

% create the control window and execute the phase selection loop
%try
%  contFig=controller(); info=guidata(contFig); 
%catch
  contFig=figure(1);
  set(contFig,'name','BCI Controller : close to quit','color',[0 0 0],'menubar','none','toolbar','none');
  axes('position',[0 0 1 1],'visible','off','xlim',[0 1],'ylim',[0 1],'nextplot','add');
  set(contFig,'Units','pixel');wSize=get(contFig,'position');
  fontSize = .04*wSize(4);
  %        Instruct String          Phase-name
  menustr={'0) EEG'                 'eegviewer';
			  'a) Artifacts'           'artifact';
           '1) Practice'            'practice';
			  '2) Calibrate'           'calibrate'; 
			  '3) Train Classifier'    'trainersp';
			  'T) Train Classifier (offline)'    'train_offline';
			  '4) Epoch Feedback'      'epochfeedback';
			  '5) Continuous Feedback' 'contfeedback';
           '6) Center-out Feedback Training' 'centerout';
			  '7) NeuroFeedback'       'neurofeedback'
           '' '';
			  'p) Practice - runway'    'practice_runway'; 
			  'r) Calibrate - runway'   'calibrate_runway'; 
			  'f) Continuous Feedback - runway'   'contfeedback_runway';
			  'w) Cybathalon warmup->Control'    'cybathalon_warmup';
			  'c) Cybathalon Control'   'cybathalon';
           '' '';
           'K) Keyboard Control'    'keyboardcontrol';
           'E) EMG Control'         'emgcontrol';
			  'q) quit'                 'quit';
          };
  txth=text(.25,.5,menustr(:,1),'fontunits','pixel','fontsize',fontSize,...
				'HorizontalAlignment','left','color',[1 1 1]);
  ph=plot(1,0,'k'); % BODGE: point to move around to update the plot to force key processing
  % install listener for key-press mode change
  set(contFig,'keypressfcn',@(src,ev) set(src,'userdata',char(ev.Character(:)))); 
  set(contFig,'userdata',[]);
  drawnow; % make sure the figure is visible
%end
subject='test';

datestr = datevec(now); datestr = sprintf('%02d%02d%02d',datestr(1)-2000,datestr(2:3));

sendEvent('experiment.im','start');
while (ishandle(contFig))
  set(contFig,'visible','on');
  if ( ~ishandle(contFig) ) break; end;

  phaseToRun=[];
  if ( ~exist('OCTAVE_VERSION','builtin') && ~isempty(get(contFig,'tag')) )  % using the gui-figure-window
	 uiwait(contFig);
    if ( ~ishandle(contFig) ) break; end;    
	 info=guidata(contFig); 
	 subject=info.subject;
	 phaseToRun=lower(info.phaseToRun);
  else % give time to process the key presses
	 % BODGE: move point to force key-processing
	 fprintf('.');set(ph,'ydata',rand(1)*.01); drawnow;
	 if ( ~ishandle(contFig) ) break; end;
  end

  % process any key-presses
  modekey=get(contFig,'userdata'); 
  if ( ~isempty(modekey) ) 	 
	 fprintf('key=%s\n',modekey);
	 phaseToRun=[];
	 if ( ischar(modekey(1)) )
		ri = strncmpi(modekey(1),menustr(:,1),1); % get the row in the instructions
		if ( any(ri) ) 
		  phaseToRun = menustr{find(ri,1),2};
		elseif ( any(strcmp(modekey(1),{'q','Q'})) )
		  break;
		end
	 end
    set(contFig,'userdata',[]);
  end

  if ( isempty(phaseToRun) ) pause(.3); continue; end;

  fprintf('Start phase : %s\n',phaseToRun);  
  set(contFig,'visible','off');
  switch phaseToRun;
    
   %---------------------------------------------------------------------------
   case 'capfitting';
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun); % tell sig-proc what to do
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end',inf); % wait until finished

   %---------------------------------------------------------------------------
   case 'eegviewer';
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun); % tell sig-proc what to do
    % wait until capFitting is done
    buffer_newevents(buffhost,buffport,[],phaseToRun,'end',inf); % wait until finished
    
   %---------------------------------------------------------------------------
   case 'artifact';
    sendEvent('subject',subject);
    sendEvent('startPhase.cmd',phaseToRun); % tell sig-proc what to do
														  % wait until capFitting is done
	 try;
		artifactCalibrationStimulus;
	 catch
      fprintf('Error in : %s',phaseToRun);
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	if ( ~isempty(le.stack) )
	  	  for i=1:numel(le.stack);
	  		 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	  end;
	  	end
	  	msgbox({sprintf('Error in : %s',phaseToRun) 'OK to continue!'},'Error');
      sendEvent(phaseToRun,'end');    
    end
    
   %---------------------------------------------------------------------------
   case {'calibrate','calibration','practice'};
    sendEvent('subject',subject);
	  if ( ~isempty(strfind(phaseToRun,'calibrat')) ) % tell the sig-proc to go if real run
		 sendEvent('startPhase.cmd','calibrate')
	  end
    sendEvent(phaseToRun,'start');
    try
      imCalibrateStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
    end
    if ( ~isempty(strfind(phaseToRun,'calibrat')) ) sendEvent('calibrate','end'); end   

    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'calibrate_runway','practice_runway'};
    sendEvent('subject',subject);
	  if ( ~isempty(strfind(phaseToRun,'calibrat')) ) % tell the sig-proc to go if real run
		 sendEvent('startPhase.cmd','calibrate')
	  end
    sendEvent(phaseToRun,'start');
    try
      imCalibrateRunwayStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
    end
    if ( ~isempty(strfind(phaseToRun,'calibrat')) ) sendEvent('calibrate','end'); end   
	 sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'train','trainersp','trainersp_subset','train_subset'};
     sendEvent('subject',subject);
		 sendEvent('startPhase.cmd',phaseToRun); % tell sig-proc what to do
		 buffer_newevents(buffhost,buffport,[],phaseToRun,'end'); % wait until finished

%---------------------------------------------------------------------------
   case {'train_offline'};
		 % BODGE: slice data from save file and train classifier directly.....
		 % slice from the save file
		 [fn,pth]=uigetfile({'header'},'Pick data header file'); drawnow;
		 if ( ~isequal(fn,0) ); datadir=pth; end;
		 [fn,pth]=uigetfile(fullfile(mdir,'..','../resources/caps/*.txt'),'Pick cap-file'); 
		 if ( isequal(fn,0) || isequal(pth,0) ) capFile='1010.txt'; 
		 else                                   capFile=fullfile(pth,fn);
		 end
		 if(~isempty(strfind(capFile,'1010.txt')))overridechnms=0;else overridechnms=1; end; 
		 % slice the data-file
		 [traindata,traindevents]=sliceraw(datadir,... % N.B. **MUST** read header from save file!
													  'startSet','stimulus.target','trlen_ms',trlen_ms);

		 % train the classifier
		 [clsfr,res]=...
		 buffer_train_ersp_clsfr(traindata,traindevents,hdr,'spatialfilter','car',...
										 'freqband',freqband,'badchrm',1,'badtrrm',1,...
										 'capFile',capFile,'overridechnms',overridechnms,'verb',verb,...
										 trainOpts{:});

		 % save the trained classifier
		 fname=['clsfr' '_' subject '_' datestr];
       fprintf('Saving classifier to : %s\n',fname);
		 save([fname '.mat'],'-struct','clsfr');		 
		 
   %---------------------------------------------------------------------------
   case {'epochfeedback'};
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
		if ( earlyStopping ) % use the user-defined command
        sendEvent('startPhase.cmd',userFeedbackTable{1});
      else
        sendEvent('startPhase.cmd','epochfeedback');
      end
      imEpochFeedbackStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
    end
	 if ( earlyStopping ) % use the user-defined command
      sendEvent(userFeedbackTable{1},'end');
    else
      sendEvent('epochfeedback','end');
    end
    sendEvent('test','end');
    sendEvent(phaseToRun,'end');

    %---------------------------------------------------------------------------
   case {'cybathalon','cybathalon_warmup'};
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
		if ( earlyStopping ) % use the user-defined command
        sendEvent('startPhase.cmd',userFeedbackTable{1});
      else
        sendEvent('startPhase.cmd','epochfeedback');
      end
		% run warmup first if needed -- for the filters/user to bed in...
		if( strcmp(phaseToRun,'cybathalon_warmup') )
		  try;
			 imEpochFeedbackWarmupCybathalon;
		  catch;
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
		  end
		end
		% run the main cybathalon control
      imEpochFeedbackCybathalon;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
    end
    sendEvent('test','end');
    sendEvent(phaseToRun,'end');
   
   %---------------------------------------------------------------------------
   case {'contfeedback'};
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
      sendEvent('startPhase.cmd','contfeedback');
      imContFeedbackStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
    end
    sendEvent('contfeedback','end');
    sendEvent('test','end');
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'keyboardcontrol'};
    sendEvent(phaseToRun,'start');
    %try
      cybathlon_keyboard_control;
      %catch
      % fprintf('Error in : %s',phaseToRun);
      % le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	% if ( ~isempty(le.stack) )
	  	%   for i=1:numel(le.stack);
	  	% 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	%   end;
	  	% end
      %end
    sendEvent(phaseToRun,'end');


   %---------------------------------------------------------------------------
   case {'emgcontrol'};
    sendEvent(phaseToRun,'start');
    %try
       [emgdata,emgevents,emghdr]=EMGtraining();
       EMGcontroller(emgdata,emgevents,'hdr',emghdr,'difficulty',1);
       %catch
      % fprintf('Error in : %s',phaseToRun);
      % le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	% if ( ~isempty(le.stack) )
	  	%   for i=1:numel(le.stack);
	  	% 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	%   end;
	  	% end
      %end
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'neurofeedback'};
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
      sendEvent('startPhase.cmd','contfeedback');
      imNeuroFeedbackStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
    end
    sendEvent('contfeedback','end');
    sendEvent('test','end');
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'centerout' 'centeroutfeedback'};
    sendEvent('subject',subject);
    %sleepSec(.1);
    sendEvent(phaseToRun,'start');
    try
      sendEvent('startPhase.cmd','contfeedback');
      imCenterOutTrainingStimulus;
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
    end
    sendEvent('contfeedback','end');
    sendEvent('test','end');
    sendEvent(phaseToRun,'end');

   %---------------------------------------------------------------------------
   case {'feedback_runway','contfeedback_runway'};
    sendEvent('subject',subject);
    sendEvent(phaseToRun,'start');
    try
      sendEvent('startPhase.cmd','contfeedback');
      imContFeedbackRunway
    catch
       le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  	 if ( ~isempty(le.stack) )
	  	   for i=1:numel(le.stack);
	  	 	 fprintf('%s>%s : %d\n',le.stack(i).file,le.stack(i).name,le.stack(i).line);
	  	   end;
	  	 end
    end
    sendEvent('contfeedback','end');
	 sendEvent(phaseToRun,'end');
	 
   %---------------------------------------------------------------------------
   case {'quit','exit'};
    break;
    
  end
end
% shut down signal proc
sendEvent('startPhase.cmd','exit');
% give thanks
uiwait(msgbox({'Thankyou for participating in our experiment.'},'Thanks','modal'),10);
