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
verb         =0; % verbosity level for debug messages, 1=default, 0=quiet, 2=very verbose
buffhost     ='localhost';
buffport     =1972;
symbCue      ={'Feet' 'Left-Hand' 'Right-Hand' 'tongueeeeeee'};
%symbCue      ={'Alpha' 'Tongue' 'Hands'}; % config for JF
%symbCue      ={'Tong' 'Voeten' 'Rechter-hand' 'Linker-hand'}; % config for P3
nSymbs       =numel(symbCue); 
baselineClass= []%'99 Rest'; %[];% if set, treat baseline phase as a separate class to classify
rtbClass     =[];%'999 rtb';% 'trialClass';% 'trialClass+rtb'; % 'rtb';% [];% if set post-trial is separate class also

nSeq              =18*nSymbs; % 20 examples of each target
epochDuration     =.75;
trialDuration     =epochDuration*4*2; % 3*20 = 60 classification trials per class = 4.5s trials
baselineDuration  =epochDuration*2;   % = 1.5s baseline
intertrialDuration=epochDuration*2; % = 1.5s post-trial
feedbackDuration  =epochDuration*2;
errorDuration     =epochDuration*2*3; %= 3s penalty for mistake
calibrateMaxSeqDuration=150;        %= 2.5min between wait-for-key-breaks


warpCursor   = 1; % flag if in feedback BCI output sets cursor location or how the relative movement
moveScale    = .1;
dvCalFactor  = []; % calibration factor to re-scale classifier decsion values to true probabilities

axLim        =[-1.5 1.5]; % size of the display axes
winColor     =[.0 .0 .0]; % window background color
bgColor      =[.2 .2 .2]; % background/inactive stimuli color
fixColor     =[.8  0  0]; % fixitation/get-ready cue point color
tgtColor     =[0  .7  0]; % target color
fbColor      =[0   0 .8]; % feedback color
txtColor     =[.9 .9 .9]; % color of the cue text
errorColor   =[.8  0  0];  % error feedback color


animateFix   = true; % do we animate the fixation point during training?
frameDuration= .25; % time between re-draws when animating the fixation point
animateStep  = diff(axLim)*.01; % amount by which to move point per-frame in fix animation


%----------------------------------------------------------------------------------------------
% stimulus type specific configuration
calibrate_instruct ={'When instructed perform the indicated' 'actual movement'};

epochfeedback_instruct={'When instructed perform the indicated' 'actual movement.  When trial is done ' 'classifier prediction with be shown' 'with a blue highlight'};
epochFeedbackTrialDuration=epochDuration*ceil(3/epochDuration); % 3s?

contfeedback_instruct={'When instructed perform the indicated' 'actual movement.  The fixation point' 'will move to show the systems' 'current prediction'};
contFeedbackTrialDuration =epochDuration*ceil(10/epochDuration); % about 10s

neurofeedback_instruct={'Perform mental tasks as you would like.' 'The fixation point will move to' 'show the systems current prediction'};
neurofeedbackTrialDuration=epochDuration*ceil(60/epochDuration); % about 60s

centerout_instruct={'Complete the indicated tasks as rapidly as possible.' 'The fixation point will move to' 'show the current prediction' 'Trials end when fixation hits the target' 'or time runs out.' 'Hitting the wrong target incurs a time penalty'};
earlyStoppingFilt=[]; % dv-filter to determine when a trial has ended
%earlyStoppingFilt=@(x,s,e) gausOutlierFilt(x,s,2); % dv-filter to determine when a trial has ended

%----------------------------------------------------------------------------------------------
% classifier training configuration

% Calibration/data-recording options
freqband      =[6 8 28 30];
trlen_ms      =epochDuration*1000; % how much data to use in each classifier training example
offset_ms     =[0 0];%[250 250]; % give .25s for user to start/finish
calibrateOpts ={'offset_ms',offset_ms};

										% classifier training options
welch_width_ms=250; % width of welch window => spectral resolution

epochtrlen_ms =epochFeedbackTrialDuration*1000; % amount of data to apply classifier to in epoch feedback
conttrlen_ms  =epochDuration*1000;%welch_width_ms; % amount of data to apply classifier to in continuous feedback
contstep_ms   =conttrlen_ms/2;% N.B. welch defaults=.5 window overlap, use step=width/2 to simulate

% smoothing parameters for feedback in continuous feedback mode
contFeedbackFiltLen=(trialDuration*1000/contstep_ms); % accumulate whole trials data before feedback
contFeedbackFiltFactor=exp(log(.5)/(contFeedbackFiltLen/2)); % convert to exp-move-ave weighting factor, N.B. 2-hl in window=75% output

% paramters for on-line adaption to signal changes
adaptHalfLife_ms = 50*.75*1000; %50 epochs amount of data to use for adapting spatialfilter/biasadapt
conttrialAdaptHL=(adaptHalfLife_ms/contstep_ms); % half-life in number of calls to apply clsfr
conttrialAdaptFactor=exp(log(.5)./conttrialAdaptHL); % convert to exp-move-ave weighting factor 
epochtrialAdaptHL=(adaptHalfLife_ms/epochtrlen_ms); % half-life in number calls to apply-clsfr in epoch feedback
epochtrialAdaptFactor=exp(log(.5)/epochtrialAdaptHL); % convert to exp-move-ave weight factor

spMx='1vR';
if( ~isempty(rtbClass) ) % setup the training to ignore the rtb info
  % build the target names used in the event, i.e. all but rtb
  spMx={};
  for ci=1:nSymbs; spMx{ci}=sprintf('%d %s',ci,symbCue{ci}); end;
  spMx{nSymbs+1}=baselineClass;
end

%trainOpts={'width_ms',welch_width_ms,'badtrrm',0};%default: 4hz res, stack of independent one-vs-rest classifiers
trainOpts={'width_ms',welch_width_ms,'badtrrm',0,'freqband',freqband,'badchscale',0,'spatialfilter','wht','featFilt',{'relFilt',conttrialAdaptHL,1},'objFn','mlr_cg','binsp',0,'spMx',spMx,'calibrate','cr'}; % whiten + direct multi-class training
%trainOpts={'width_ms',welch_width_ms,'aveType','db','badtrrm',0,'freqband',freqband,'badtrthresh',100,'badchrm',5,'spatialfilter','wht','objFn','mlr_cg','binsp',0,'spMx',spMx}; % whiten + direct multi-class training
%trainOpts={'width_ms',welch_width_ms,'badtrrm',0,'freqband',freqband,'spatialfilter','trwht','objFn','mlr_cg','binsp',0,'spMx',spMx}; % local-whiten + direct multi-class training
%trainOpts={'width_ms',welch_width_ms,'badtrrm',0,'freqband',freqband,'spatialfilter','adaptspatialfilt','adaptspatialfilt',conttrialAdaptFactor,'objFn','mlr_cg','binsp',0,'spMx',spMx};% adaptive-whiten + direct multi-class training
%trainOpts = {'spType',{{1 3} {2 4}}}; % train 2 classifiers, 1=N vs S, 2=E vs W

% Epoch feedback opts
%%0) Use exactly the same classification window for feedback as for training, but
%%   but also include a bias adaption system to cope with train->test transfer
earlyStopping = false;
%epochFeedbackOpts={'trlen_ms',epochtrlen_ms}; % raw output, from whole trials data
epochFeedbackOpts={'trlen_ms',epochtrlen_ms,'predFilt',@(x,s,e) rbiasFilt(x,s,epochtrialAdaptFactor)}; % bias-adaption
%epochFeedbackOpts={'trlen_ms',epochtrlen_ms}; % raw output, from whole trials data
%epochFeedbackOpts={'trlen_ms',epochtrlen_ms,'predFilt',@(x,s,e) biasFilt(x,s,epochtrialAdaptFactor)}; % bias-adaption

% different feedback configs (should all give similar results)

%%2) Classify every conttrlen_ms (default 250ms), prediction is average of full trials worth of data, no-bias adaptation
%% N.B. this is numerically identical to option 1) above, but computationally *much* cheaper 
%% Also send all raw predictions out for use in, e.g. center-out training
%contFeedbackOpts ={'rawpredEventType','classifier.rawprediction','trlen_ms',conttrlen_ms,'predFilt',-contFeedbackFiltLen}; % trlDuration average
%contFeedbackOpts ={'rawpredEventType','classifier.rawprediction','trlen_ms',conttrlen_ms,'predFilt',-contFeedbackFiltLen}; % trlDuration average
% as above but include an additional bias-adaption as well as classifier output smoothing
contFeedbackOpts ={'rawpredEventType','classifier.rawprediction','trlen_ms',conttrlen_ms,'predFilt',@(x,s,e) rbiasFilt(x,s,[conttrialAdaptFactor -contFeedbackFiltLen])}; % trlDuration average
dvCalFactor = contFeedbackFiltLen; % re-scale the mean-dv back up to a sum-dv
contFeedbackOpts ={'rawpredEventType','classifier.rawprediction','trlen_ms',conttrlen_ms,'predFilt',@(x,s,e) biasFilt(x,s,[conttrialAdaptFactor contFeedbackFiltFactor])}; % trlDuration average

% Epoch feedback with early-stopping, config using the user feedback table
userFeedbackTable={'epochFeedback_es' 'cont' {'trlen_ms',welch_width_ms,'predFilt',@(x,s,e) gausOutlierFilt(x,s,3.0,contFeedbackFiltLen)}};
% Epoch feedback with early-stopping, (cont-classifer, so update adaptive whitener constant)
%userFeedbackTable={'epochFeedback_es' 'cont' {'trlen_ms',welch_width_ms,'predFilt',@(x,s,e) gausOutlierFilt(x,s,3.0,contFeedbackFiltLen),'adaptspatialfilt',conttrialAdaptFactor}};
