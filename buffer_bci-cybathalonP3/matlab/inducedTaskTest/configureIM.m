%----------------------------------------------------------------------
% One-Time initialization code
% guard to not run the slow one-time-only config code every time...
if ( ~exist('configRun','var') || isempty(configRun) ) 

  % setup the paths
  run ../utilities/initPaths.m;

  buffhost='localhost';buffport=1972;
  % wait for the buffer to return valid header information
  hdr=[];
  while( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) %wait for the buffer to contain valid data
	 try 
		hdr=buffer('get_hdr',[],buffhost,buffport); 
	 catch
		hdr=[];
		fprintf('Invalid header info... waiting.\n');
	 end;
	 pause(1);
  end;

  % set the real-time-clock to use
  initgetwTime;
  initsleepSec;

  if ( exist('OCTAVE_VERSION','builtin') ) 
	 page_output_immediately(1); % prevent buffering output
	 if ( ~isempty(strmatch('qt',available_graphics_toolkits())) )
		graphics_toolkit('qt'); 
	 elseif ( ~isempty(strmatch('qthandles',available_graphics_toolkits())) )
		graphics_toolkit('qthandles'); 
	 elseif ( ~isempty(strmatch('fltk',available_graphics_toolkits())) )
		graphics_toolkit('fltk'); % use fast rendering library
	 end
  end

  % One-time configuration has successfully completed
  configRun=true;
end
%----------------------------------------------------------------------

%----------------------------------------------------------------------
% Application specific config
verb         =1; % verbosity level for debug messages, 1=default, 0=quiet, 2=very verbose
buffhost     ='localhost';
buffport     =1972;
% N.B. tgts *always* start from the top (12 o'clock=N) and run anti-clock
% 3-[N,SW,SE], 4-[N,W,S,E], 6-[N,NW,SW,S,SE,NE], 8-[N,NW,W,SW,S,SE,E,NE]
%symbCue      ={'RH' 'Tongue' 'Song' 'LH' 'Math' 'Feet'}; %  for 6 outputs. 
symbCue      ={'Left&Right-Hand' 'Song' 'Left-Hand' 'Left-Vis-Attn' 'Feet' 'Right-Vis-Attn' 'Right-Hand' 'Tongue'};
nSymbs       =numel(symbCue); 
baselineClass='99 rest'; % 'Rest';if set, treat baseline phase as a separate class to classify
rtbClass     =[];

calibrate_instruct ={'When instructed perform the indicated' 'actual movement'};
epochfeedback_instruct={'When instructed perform the indicated' 'actual movement.  When trial is done ' 'classifier prediction with be shown' 'with a blue highlight'};
contfeedback_instruct={'When instructed perform the indicated' 'actual movement.  The fixation point' 'will move to show the systems' 'current prediction'};
neurofeedback_instruct={'Perform mental tasks as you would like.' 'The fixation point will move to' 'show the systems current prediction'};


nSeq         =12*nSymbs; % 12 examples of each target
epochDuration   =1.5;
trialDuration   =epochDuration*5; % 12*5 = 60 classifiation trials for each target
baselineDuration=epochDuration;
intertrialDuration=epochDuration;
feedbackDuration=.5;
calibrateMaxSeqDuration=120;        %= 2min between wait-for-key-breaks

contFeedbackTrialDuration =10;
neurofeedbackTrialDuration=30;
warpCursor   = 0; % flag if in feedback BCI output sets cursor location or how the cursor moves
moveScale    = .1;
dvCalFactor  = []; % calibration factor to re-scale classifier decsion values to true probabilities

axLim        =[-1.5 1.5]; % size of the display axes
winColor     =[.0 .0 .0]; % window background color
bgColor      =[.2 .2 .2]; % background/inactive stimuli color
fixColor     =[.8  0  0];  % fixitation/get-ready cue point color
tgtColor     =[0  .7  0];  % target color
fbColor      =[0   0 .8];  % feedback color
txtColor     =[.9 .9 .9]; % color of the cue text

animateFix   = true; % do we animate the fixation point during training?
frameDuration= .25; % time between re-draws when animating the fixation point
animateStep  = diff(axLim)*.01; % amount by which to move point per-frame in fix animation

										  % classifier training options
if ( isempty(epochDuration) )
  trlen_ms      =trialDuration*1000; % amount of data in each example
else
  trlen_ms      =epochDuration*1000;
end
calibrateOpts ={'offset_ms',[250 250]};

welch_width_ms=250; % width of welch window => spectral resolution
%trainOpts={'width_ms',welch_width_ms,'badtrrm',0}; % default: 4hz res, stack of independent one-vs-rest classifiers
%trainOpts={'width_ms',welch_width_ms,'badtrrm',0,'spatialfilter','wht','objFn','lr_cg','binsp',1,'spMx','1v1'}; % all-pairwise training
trainOpts={'width_ms',welch_width_ms,'badtrrm',0,'spatialfilter','wht','objFn','mlr_cg','binsp',0,'spMx','1vR'}; % whiten + direct multi-class training


% Epoch feedback opts
%%0) Use exactly the same classification window for feedback as for training, but
%%   but also include a bias adaption system to cope with train->test transfer
earlyStopping=false;
epochFeedbackOpts={}; % raw output
%epochFeedbackOpts={'predFilt',@(x,s) biasFilt(x,s,exp(log(.5)/50))}; % bias-apaption

% different feedback configs (should all give similar results)

%%1) Use exactly the same classification window for feedback as for training, but apply more often
%contFeedbackOpts ={'step_ms',welch_width_ms}; % apply classifier more often
%%   but also include a bias adaption system to cope with train->test transfer
%contFeedbackOpts ={'predFilt',@(x,s) biasFilt(x,s,exp(log(.5)/100)),'step_ms',250};
stimSmoothFactor= 0; % additional smoothing on the stimulus, not needed with 3s trlen

%%2) Classify every welch-window-width (default 250ms), prediction is average of full trials worth of data, no-bias adaptation
%% N.B. this is numerically identical to option 1) above, but computationally *much* cheaper 
step_ms=welch_width_ms/2;% N.B. welch defaults=.5 window overlap, use step=width/2 to simulate
contFeedbackOpts ={'predFilt',-(trlen_ms/step_ms),'trlen_ms',welch_width_ms};


%%3) Classify every welch-window-width (default 500ms), with bias-adaptation
%contFeedbackOpts ={'predFilt',@(x,s) biasFilt(x,s,exp(log(.5)/400)),'trlen_ms',[]}; 
%stimSmoothFactor= -(trlen_ms/500);% actual prediction is average of trail-length worth of predictions
