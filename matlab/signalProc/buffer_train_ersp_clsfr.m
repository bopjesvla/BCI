function [clsfr,res,X,Y]=buffer_train_ersp_clsfr(X,Y,hdr,varargin);
% train ERSP (frequency-domain) classifier with ft-buffer based data/events input
%
%   [clsfr,res,X,Y]=buffer_train_ersp_clsfr(X,Y,hdr,varargin);
%
% Inputs:
%  X -- [ch x time x epoch] data
%       OR
%       [struct epoch x 1] where the struct contains a buf field of buffer data
%       OR
%       {[float ch x time] epoch x 1} cell array of data
%  Y -- [epoch x 1] set of labels for the data epochs
%       OR
%       [struct epoch x 1] set of buf event structures which contain epoch labels in value field
%  hdr-- [struct] buffer header structure
% Options:
%  capFile -- [str] name of file which contains the electrode position info  ('1010')
%  overridechnms -- [bool] does capfile override names from the header    (false)
%  varargin -- all other options are passed as option arguments to train_ersp_clsfr, e.g.
%              freqband,timeband,spatialfilter,badchrm,badtrrm,detrend,etc..
% Outputs:
%  clsfr   -- [struct] a classifer structure
%           |.W      -- [size(X) x nSp] weighting over X (for each subProblem)
%           |.b      -- [nSp x 1] bias term
%           |.dim    -- [ind] dimensions of X which contain the trails
%           |.spMx   -- [nSp x nClass] mapping between sub-problems and input classes
%           |.spKey  -- [nClass] label for each class in the spMx, thus:
%                        spKey(spMx(1,:)>0) gives positive class labels for subproblem 1
%           |.spDesc -- {nSp} set of strings describing the sub-problem, e.g. 'lh v rh'
%           |.binsp  -- [bool] flag if this is treated as a set of independent binary sub-problems
%           |.fs     -- [float] sample rate of training data
%           |.detrend -- [bool] detrend the data
%           |.isbad   -- [bool nCh x 1] flag for channels detected as bad and to be removed
%           |.spatialfilt [nCh x nCh] spatial filter used
%           |.filt    -- [float] filter weights for spectral filtering (ERP only)
%           |.outsz   -- [float] info on size after spectral filter for downsampling
%           |.timeIdx -- [2x1] time range (start/end sample) to apply the classifer to
%           |.windowFn -- [float] window used in frequency domain transformation (ERsP only)
%           |.welchAveType -- [str] type of averaging used in frequency domain transformation (ERsP only)
%           |.freqIdx     -- [2x1] range of frequency to keep  (ERsP only)
%  res     -- [struct] a results structure
%  X       -- [ppch x pptime x ppepoch] pre-processed data (N.B. may/will have different size to input X)
%  Y       -- [ppepoch x 1] pre-processed labels (N.B. will have diff num examples to input!)
%
% See Also: train_ersp_clsfr
opts=struct('capFile','1010','overridechnms',0);
[opts,varargin]=parseOpts(opts,varargin);
if ( nargin<3 ) error('Insufficient arguments'); end;
% extract the data - from field begining with trainingData
if ( iscell(X) ) 
  if ( isnumeric(X{1}) ) 
    X=cat(3,X{:});
  elseif ( isstruct(X{1}) && isfield(X{1},'buf') )
	 X=cat(1,X{:});
	 X=cat(3,X.buf);
  else
    error('Unrecognised data format!');
  end
elseif ( isstruct(X) )
  X=cat(3,X.buf);
end 
X=single(X);
if ( isstruct(Y) ) % convert event struct into labels
  if ( isnumeric(Y(1).value) ) Y=cat(1,Y.value); 
  elseif(ischar(Y(1).value) )   Y=cat(1,{Y.value}); Y=Y(:);
  else error('Dont know how to handle Y value type');
  end
end; 

fs=[]; chNames={};
if ( isstruct(hdr) )
  if ( isfield(hdr,'channel_names') ) chNames=hdr.channel_names; 
  elseif( isfield(hdr,'label') )      chNames=hdr.label;
  end;
  if ( isfield(hdr,'fsample') )       fs=hdr.fsample; 
  elseif ( isfield(hdr,'Fs') )        fs=hdr.Fs;
  elseif( isfield(hdr,'SampleRate') ) fs=hdr.SampleRate; 
  else warning('Couldnt find sample rate in header, using 100'); fs=100;
  end;
elseif ( iscell(hdr) && ischar(hdr{1}) )
  chNames=hdr;
end
if ( isempty(chNames) ) 
  warning('No channel names set');
  chNames={}; for di=1:size(X,1); chNames{di}=sprintf('%d',di); end;
end
    
% get position info and identify the eeg channels
di = addPosInfo(chNames,opts.capFile,opts.overridechnms); % get 3d-coords
iseeg=false(size(X,1),1); iseeg([di.extra.iseeg])=true;
if ( any(iseeg) ) 
  ch_pos=cat(2,di.extra.pos3d); ch_names=di.vals; % extract pos and channels names    
else % fall back on showing all data
  warning('Capfile didnt match any data channels -- no EEG?');
  ch_names=di.vals; ch_pos  =[]; iseeg(:)=true;
end

% call the actual function which does the classifier training
[clsfr,res,X,Y]=train_ersp_clsfr(X,Y,'ch_names',ch_names,'ch_pos',ch_pos,'fs',fs,'badCh',~iseeg,varargin{:});
return;

%---------------------
function testCase()
load('training_data_test_160816');
[clsfr,res]=buffer_train_ersp_clsfr(traindata,traindevents,hdr,'spatialfilter','wht','objFn','mlr_cg','binsp',0,'spMx','1vR');
[clsfr,res]=buffer_train_ersp_clsfr(traindata,traindevents,hdr,'spatialfilter','trwht','adaptspatialfilt',exp(log(.1)/300),'objFn','mlr_cg','binsp',0,'spMx','1vR');
% apply to the training data with the adaptive whitener
oclsfr=clsfr;
testdata = traindata;
for ei=1:numel(testdata); % bodge in and additional noise source
   testdata(ei).buf = testdata(ei).buf + randn(size(testdata(ei).buf))*5e-1; 
end;

of = buffer_apply_ersp_clsfr(traindata,oclsfr);
c=oclsfr; c.adaptspatialfilt=1; nf = buffer_apply_ersp_clsfr(testdata,c); %non-adaptive clsfr

clsfr=oclsfr;clsfr.adaptspatialfilt=exp(log(.5)/30);
f=[];p=[];
for ei=1:numel(testdata);
   textprogressbar(ei,numel(testdata));
   [f(ei,:),ans,p(ei,:),ans,clsfr]=buffer_apply_ersp_clsfr(testdata(ei),clsfr);
end
fprintf('\n');

% compare the results
clf;image3d(cat(3,of,nf,f),2,'disptype','plot','Zvals',{'of' 'nf' 'af'})
mad(of,f)

