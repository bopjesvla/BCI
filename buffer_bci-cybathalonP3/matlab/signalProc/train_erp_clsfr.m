function [clsfr,res,X,Y]=train_erp_clsfr(X,Y,varargin)
% train a simple ERP classifer.
% 
% [clsfr,res,X]=train_erp_clsfr(X,Y....);
%
% Inputs:
%  X         - [ ch x time x epoch ] data set
%  Y         - [ nEpoch x 1 ] set of data class labels
% Options:  (specify as 'name',value pairs, e.g. train_ersp_clsfr(X,Y,'fs',10);
%  ch_names  - {str} cell array of strings which label each channel
%  ch_pos    - [3 x nCh] 3-d co-ordinates of the data electrodes
%              OR
%              {str} cell array of strings which label each channel in *1010 system*
%  capFile   - 'filename' file from which to load the channel position information.
%              *this overrides* ch_pos if given
%  overridechnms - [bool] flag if channel order from 'capFile' overrides that from the 'ch_names' option
%  fs        - sampling rate of the data
%  timeband_ms- [2 x 1] band of times in milliseconds to use for classification, all if empty ([])
%  freqband  - [2 x 1] or [3 x 1] or [4 x 1] band of frequencies to use
%              EMPTY for *NO* spectral filter
%              OR
%              { nFreq x 1 } cell array of discrete frequencies to pick
%  width_ms  - [float] width in millisecs for the windows in the welch spectrum (250)
%              estimation.  
%              N.B. the output frequency resolution = 1000/width_ms, so 4Hz with 250ms
%  spatialfilter -- [str] one of 'slap','car','none','csp','ssep'              ('slap')
%       WARNING: CSP is particularly prone to *overfitting* so treat any performance estimates with care...
%  badchrm   - [bool] do we do bad channel removal    (1)
%  badchthresh - [float] threshold in std-dev units to id channel as bad (3.5)
%  badtrrm   - [bool] do we do bad trial removal      (1)
%  badtrthresh - [float] threshold in std-dev units to id trial as bad (3)
%  detrend   - [int] do we detrend/center the data          (1)
%              0 - do nothing
%              1 - detrend the data
%              2 - center the data (i.e. subtract the mean)
%  visualize - [int] visualize the data                     (1)
%               0 - don't visualize
%               1 - visualize, but don't wait
%               2 - visualize, and wait for user before continuing
%  verb      - [int] verbosity level
%  class_names - {str} names for each of the classes in Y in *increasing* order ([])
% Outputs:
%  clsfr  - [struct] structure contining the stuff necessary to apply the trained classifier
%           |.w      -- [size(X) x nSp] weighting over X (for each subProblem)
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
%  res    - [struct] results structure as returned by 'cvtrainFn'. 
%                    use: help cvtrainFn for more information on its structure
%  X      - [size(X)] the pre-processed data
  opts=struct('classify',1,'fs',[],...
				  'timeband_ms',[],'freqband',[],'downsample',[],'detrend',1,'spatialfilter','car',...
				  'badchrm',1,'badchthresh',3.1,'badchscale',2,...
				  'badtrrm',1,'badtrthresh',3,'badtrscale',2,...
				  'featFilt',[],...
				  'ch_pos',[],'ch_names',[],'verb',0,'capFile','1010','overridechnms',0,...
				  'visualize',1,'badCh',[],'nFold',10,'class_names',[],'zeroLab',1);
[opts,varargin]=parseOpts(opts,varargin);

di=[]; ch_pos=opts.ch_pos; ch_names=opts.ch_names;
if ( iscell(ch_pos) && ischar(ch_pos{1}) ) ch_names=ch_pos; ch_pos=[]; end;
% convert names to positions
if ( isempty(ch_pos) && ~isempty(opts.capFile) && (~isempty(ch_names) || opts.overridechnms) ) 
  di = addPosInfo(ch_names,opts.capFile,opts.overridechnms); % get 3d-coords
  if ( any([di.extra.iseeg]) ) 
    ch_pos=cat(2,di.extra.pos3d); ch_names=di.vals; % extract pos and channels names    
  else % fall back on showing all data
    warning('Capfile didnt match any data channels -- no EEG?');
    ch_pos=[];
  end
end

%1) Detrend
if ( opts.detrend )
  if ( isequal(opts.detrend,1) )
    fprintf('1) Detrend\n');
    X=detrend(X,2); % detrend over time
  elseif ( isequal(opts.detrend,2) )
    fprintf('1) Center\n');
    X=repop(X,'-',mean(X,2));
  end
end

%2) Bad channel identification & removal
isbadch=[]; chthresh=[];
if ( opts.badchrm || (~isempty(opts.badCh) && sum(opts.badCh)>0) )
  fprintf('2) bad channel removal, ');
  isbadch = false(size(X,1),1);
  if ( ~isempty(ch_pos) ) isbadch(numel(ch_pos)+1:end)=true; end;
  if ( ~isempty(opts.badCh) )
      isbadch(opts.badCh(1:min(end,size(isbadch,1))))=true;
      goodCh=find(~isbadch);
      if ( opts.badchrm ) 
          [isbad2,chstds,chthresh]=idOutliers(X(goodCh,:,:),1,opts.badchthresh);
          isbadch(goodCh(isbad2))=true;
      end
  elseif ( opts.badchrm ) [isbadch,chstds,chthresh]=idOutliers(X,1,opts.badchthresh); 
  end;
  X=X(~isbadch,:,:);
  if ( ~isempty(ch_names) ) % update the channel info
    if ( ~isempty(ch_pos) ) ch_pos  =ch_pos(:,~isbadch(1:numel(ch_names))); end;
    ch_names=ch_names(~isbadch(1:numel(ch_names)));
  end
  fprintf('%d ch removed\n',sum(isbadch(1:numel(ch_names))));
end

%3) Spatial filter/re-reference
R=[]; sfApplied=false;
if ( isnumeric(opts.spatialfilter) ) % user gives exact filter to use
   R=opts.spatialfilter;
elseif ( size(X,1)> 5 ) % only spatial filter if enough channels
  sftype=lower(opts.spatialfilter);
  switch ( sftype )
   case 'slap';
    fprintf('3) Slap\n');
    if ( ~isempty(ch_pos) )       
      R=sphericalSplineInterpolate(ch_pos,ch_pos,[],[],'slap');%pre-compute the SLAP filter we'll use
    else
      warning('Cant compute SLAP without channel positions!'); 
    end
   case 'car';
    fprintf('3) CAR\n');
    R=eye(size(X,1))-(1./size(X,1));
   case {'whiten','wht'};
    fprintf('3) whiten\n');
    R=whiten(X,1,1,0,0,1); % symetric whiten
   case {'trwht'};   % single-trial whitening
	 fprintf('3) trwht\n');
	 [trR,Sigma,X]=whiten(X,[1 3],1,0,0,1,1);
	 R=trR(:,:,end);
	 sfApplied=true;
   case {'adaptspatialfilt'}; % adaptive whitening
	 fprintf(' exp-trwht %g',opts.adaptspatialfilt);
			  % construct weight vector equivalent to exp-moving-average-filter
	 hl   = ceil(log(.5)./log(opts.adaptspatialfilt)); % half-life
	 wght = (1-opts.adaptspatialfilt)*(opts.adaptspatialfilt.^[2*hl:-1:0]);
    [trR,Sigma,X]=whiten(X,[1 3],1,0,0,1,wght);
	 R=trR(:,:,end);
	 sfApplied=true;
   case 'none';
   otherwise; warning(sprintf('Unrecog spatial filter type: %s. Ignored!',opts.spatialfilter ));
  end
end
if ( ~isempty(R) && ~sfApplied ) % apply the spatial filter (if not already done)
  X=tprod(X,[-1 2 3],R,[1 -1]); 
end

%4) spectrally filter to the range of interest
filt=[]; 
fs=opts.fs;
outsz=[size(X,2) size(X,2)];
if(~isempty(opts.downsample)) outsz(2)=min(outsz(2),round(trlen_samp*opts.downsample/fs)); end;
if ( ~isempty(opts.freqband) && size(X,2)>10 && ~isempty(fs) ) 
  fprintf('4) filter\n');
  len=size(X,2);
  filt=mkFilter(opts.freqband,floor(len/2),opts.fs/len);
  X   =fftfilter(X,filt,outsz,2,2);
elseif( ~isempty(opts.downsample) ) % manual downsample without filtering
  X   =subsample(X,outsz(2));   
end

%4.2) time range selection
timeIdx=[];
if ( ~isempty(opts.timeband_ms) ) 
  timeIdx = opts.timeband_ms * fs ./1000; % convert to sample indices
  timeIdx = max(min(round(timeIdx),size(X,2)),1); % ensure valid range
  timeIdx = int32(timeIdx(1):timeIdx(2));
  X    = X(:,timeIdx,:);
end

%4.5) Bad trial removal
isbadtr=[]; trthresh=[];
if ( opts.badtrrm )
  fprintf('4.5) bad trial removal');
  [isbadtr,trstds,trthresh]=idOutliers(X,3,opts.badtrthresh);
  X=X(:,:,~isbadtr);
  Y=Y(~isbadtr,:);
  fprintf(' %d tr removed\n',sum(isbadtr));
end;

% 5.9) Apply a feature filter post-processor if wanted
featFilt=opts.featFilt; ffState=[];
if ( ~isempty(featFilt) )
  if ( ~iscell(featFilt) ) featFilt={featFilt}; end;
  for ei=1:size(X,3);
	 [X(:,:,ei),ffState]=feval(featFilt{1},X(:,:,ei),ffState,featFilt{2:end});
  end
end

%5.5) Visualise the input?
aucfig=[];erpfig=[];
if ( opts.visualize )
  % Compute the labeling and set of sub-problems and classes to plot
  Yidx=Y; sidx=[]; labels=opts.class_names; auclabels=labels;
  if ( size(Y,2)==1 && ~(isnumeric(Y) && ~opts.zeroLab && all(Y(:)==1 | Y(:)==0 | Y(:)==-1)))%convert from labels to 1vR sub-problems
    uY=unique(Y,'rows'); Yidx=-ones([size(Y,1),numel(uY)],'int8');    
    for ci=1:size(uY,1); 
      if(iscell(uY)) 
        tmp=strmatch(uY{ci},Y); Yidx(tmp,ci)=1; 
      else 
        for i=1:size(Y,1); Yidx(i,ci)=isequal(Y(i,:),uY(ci,:))*2-1; end
      end;
      if ( isempty(labels) || numel(labels)<ci || isempty(labels{ci}) ) 
        if ( iscell(uY) ) labels{1,ci}=uY{ci}; else labels{1,ci}=sprintf('%d',uY(ci,:)); end
        auclabels{1,ci}=labels{1,ci};
        labels{1,ci} = sprintf('%s (%d)',labels{1,ci},sum(Yidx(:,ci)>0));
      end
    end
  else
    if ( isempty(labels) ) 
      for spi=1:size(Yidx,2); 
        labels{1,spi}=sprintf('sp%d +',spi);labels{2,spi}=sprintf('sp%d -',spi); 
        auclabels{spi}=sprintf('sp%d',spi);
      end;
    end
  end
  % Compute the averages and per-sub-problem AUC scores
  for spi=1:size(Yidx,2);
    Yci=Yidx(:,spi);
    if( size(labels,1)==1 ) % plot sub-prob positive response only
      mu(:,:,spi)=mean(X(:,:,Yci>0),3);      
    else % pos and neg sub-problem average responses
      mu(:,:,1,spi)=mean(X(:,:,Yci>0),3); mu(:,:,2,spi)=mean(X(:,:,Yci<0),3);
    end
    % if not all same class, or simple binary problem
    if(~(all(Yci(:)==Yci(1))) && ~(spi>1 && all(Yidx(:,1)==-Yidx(:,spi)))) 
      [aucci,sidx]=dv2auc(Yci,X,3,sidx); % N.B. re-seed with sidx to speed up later calls
      aucesp=auc_confidence(sum(Yci~=0),single(sum(Yci>0))./single(sum(Yci~=0)),.2);
      aucci(aucci<.5+aucesp & aucci>.5-aucesp)=.5;% set stat-insignificant values to .5
      auc(:,:,spi)=aucci;
    end
   end
   times=(1:size(mu,2))/opts.fs;
	xy=ch_pos; if (size(xy,1)==3) xy = xyz2xy(xy); end
   erpfig=figure(2); clf(erpfig);  set(erpfig,'Name','Data Visualisation: ERP');
	yvals=times;
   try; 
	  image3d(mu,1,'plotPos',xy,'Xvals',ch_names,'ylabel','time(s)','Yvals',yvals,'zlabel','class','Zvals',labels(:),'disptype','plot','ticklabs','sw');
     zoomplots; saveaspdf('ERP'); 
	catch; 
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  if ( ~isempty(le.stack) ) fprintf('%s>%s : %d',le.stack(1).file,le.stack(1).name,le.stack(1).line);end
	end;
   if ( ~(all(Yci(:)==Yci(1))) ) % only if >1 class input
     aucfig=figure(3); clf(aucfig); set(aucfig,'Name','Data Visualisation: ERP AUC');
     try;  
		 image3d(auc,1,'plotPos',xy,'Xvals',ch_names,'ylabel','time(s)','Yvals',yvals,'zlabel','class','Zvals',auclabels,'disptype','imaget','ticklabs','sw','clim',[.2 .8],'clabel',auc);
		 colormap ikelvin;
		 zoomplots; saveaspdf('AUC'); 
	  catch; 
      le=lasterror;fprintf('ERROR Caught:\n %s\n%s\n',le.identifier,le.message);
	  if ( ~isempty(le.stack) ) fprintf('%s>%s : %d',le.stack(1).file,le.stack(1).name,le.stack(1).line);end
	  end;
   end
   drawnow;
end

%6) train classifier
if ( opts.classify ) 
  fprintf('6) train classifier\n');
  [clsfr, res]=cvtrainLinearClassifier(X,Y,[],opts.nFold,'zeroLab',opts.zeroLab,'verb',opts.verb,varargin{:});
else
  clsfr=struct();
end

if ( opts.visualize ) 
  if ( size(res.tstconf,2)==1 ) % confusion matrix is correct
     % plot the confusion matrix
    confMxFig=figure(4); set(confMxFig,'name','Class confusion matrix');	 
	 if ( size(clsfr.spMx,1)==1 )
		if ( iscell(clsfr.spKey) ) clabels={clsfr.spKey{clsfr.spMx>0} clsfr.spKey{clsfr.spMx<0}};
		else                       clabels={sprintf('%g',clsfr.spKey(clsfr.spMx>0)) sprintf('%g',clsfr.spKey(clsfr.spMx<0))};
		end
	 else                         [ans,li]=find(clsfr.spMx>0); clabels=clsfr.spKey(li);
	 end
    imagesc(reshape(res.tstconf(:,1,res.opt.Ci),sqrt(size(res.tstconf,1)),[]));
    set(gca,'xtick',1:numel(clabels),'xticklabel',clabels,...
        'ytick',1:numel(clabels),'yticklabel',clabels);
    xlabel('True Class'); ylabel('Predicted Class'); colorbar;
    title('Class confusion matrix');
  end
end

%7) combine all the info needed to apply this pipeline to testing data
clsfr.type        = 'ERP';
clsfr.fs          = fs;   % sample rate of training data
clsfr.detrend     = opts.detrend; % detrend?
clsfr.isbad       = isbadch;% bad channels to be removed
clsfr.spatialfilt = R;    % spatial filter used for surface laplacian
clsfr.adaptspatialfilt=[]; % no adaption
clsfr.filt        = filt; % filter weights for spectral filtering
clsfr.outsz       = outsz; % info on size after spectral filter for downsampling
clsfr.timeIdx     = timeIdx; % time range to apply the classifer to

clsfr.windowFn    = []; % DUMMY -- so ERP and ERSP classifier have same structure fields
clsfr.welchAveType= []; % DUMMY -- so ERP and ERSP classifier have same structure fields
clsfr.freqIdx     = []; % DUMMY -- so ERP and ERSP classifier have same structure fields
clsfr.normalize   = normalize; % feature normalization type
clsfr.normpow     = normpow;

clsfr.badtrthresh = []; if ( ~isempty(trthresh) && opts.badtrscale>0 ) clsfr.badtrthresh = trthresh(end)*opts.badtrscale; end
clsfr.badchthresh = []; if ( ~isempty(chthresh) && opts.badchscale>0 ) clsfr.badchthresh = chthresh(end)*opts.badchscale; end
% record some dv stats which are useful
tstf = res.tstf(:,res.opt.Ci); % N.B. this *MUST* be calibrated to be useful
clsfr.dvstats.N   = [sum(res.Y>0) sum(res.Y<=0) numel(res.Y)]; % [pos-class neg-class pooled]
clsfr.dvstats.mu  = [mean(tstf(res.Y(:,1)>0)) mean(tstf(res.Y(:,1)<=0)) mean(tstf)];
clsfr.dvstats.std = [std(tstf(res.Y(:,1)>0))  std(tstf(res.Y(:,1)<=0))  std(tstf)];
%  bins=[-inf -200:5:200 inf]; clf;plot([bins(1)-1 bins(2:end-1) bins(end)+1],[histc(tstf(Y>0),bins) histc(tstf(Y<=0),bins)]); 

if ( opts.visualize >= 1 ) 
  summary='';
  if ( clsfr.binsp ) % print individual classifier outputs with info about what problem it is
     for spi=1:size(res.opt.tstbin,2);
        summary = [summary sprintf('%-40s=\t\t%4.1f\n',clsfr.spDesc{spi},res.opt.tstbin(:,spi)*100)];
     end
     summary=[summary sprintf('---------------\n')];
  end
  summary=[summary sprintf('\n%40s = %4.1f','<ave>',mean(res.opt.tstbin,2)*100)];
  b=msgbox({sprintf('Classifier performance : %s',summary) 'OK to continue!'},'Results');
  if ( opts.visualize > 1 )
     for i=0:.2:120; if ( ~ishandle(b) ) break; end; drawnow; pause(.2); end; % wait to close auc figure
     if ( ishandle(b) ) close(b); end;
   end
   drawnow;
end

return;

%---------------------------------
function xy=xyz2xy(xyz)
% utility to convert 3d co-ords to 2-d ones
% search for center of the circle defining the head
cent=mean(xyz,2); cent(3)=min(xyz(3,:)); 
f=inf; fstar=inf; tstar=0; 
for t=0:.05:1; % simple loop to find the right height..
   cent(3)=t*(max(xyz(3,:))-min(xyz(3,:)))+min(xyz(3,:));
   r2=sum(repop(xyz,'-',cent).^2); 
   f=sum((r2-mean(r2)).^2); % objective is variance in distance to the center
   if( f<fstar ) fstar=f; centstar=cent; end;
end
cent=centstar;
r = abs(max(abs(xyz(3,:)-cent(3)))*1.1); if( r<eps ) r=1; end;  % radius
h = xyz(3,:)-cent(3);  % height
rr=sqrt(2*(r.^2-r*h)./(r.^2-h.^2)); % arc-length to radial length ratio
xy = [xyz(1,:).*rr; xyz(2,:).*rr];
return
%---------------------------------------
function testCase()
z=jf_mksfToy('Y',sign(round(rand(600,1))-.5));
[clsfr]=train_erp_clsfr(z.X,z.Y,'fs',z.di(2).info.fs,'ch_pos',[z.di(1).extra.pos3d],'ch_names',z.di(1).vals,'freqband',[0 .1 10 12],'visualize',1,'verb',1);
f=apply_erp_clsfr(X,clsfr);
