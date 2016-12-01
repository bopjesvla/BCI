function [foldIdxs]=gennFold(Y,nFold,varargin)
%  [foldIdxs]=gennFold(Y,nFold,...)
%
%  Generate nFolds X repeats of the given data with equal proportions of
%  each class.
%    foldIdxs is an [N x nFolds*nRepeats] indicator matrix where:
%             -1 = training point, 0 = excluded point, +1 = testing point
%  N.B. Folds   -- are non-overlapping splits of the data
%       Repeats -- are sets of folds (and hence can overlap)
%
% Inputs:
%  Y -- [N x 1] set of class labels (N.B. 0-labels are ignored!)
%       OR
%       [N x nClass] set of class indicator variables in '1 v Rest' format (see lab2ind)
%  nFold -- [1x1] number of folds to generate
%            OR
%           'loo' for leave-one-out folding, i.e. where each example is a test example exactly once
%           'llo' for leave-label-out folding, i.e. 1 fold for each unique label value
%         N.B. negative value (-ve) means use non-overlapping training sets.  +ve=non-overlapping test
% Options:
%   dim      - [ind] dimension of Y which contains subProblems (ndims(Y))
%   nFold   -- [int] same as nFold input
%   indepSP -- [bool] flag that nClass are independent sub-problems, i.e. *not* 1vR
%              and should be folded independently (false)
%   perm -- [1x1] permute the label order before generating folds (0)
%   regress - [bool] flag if this is a regression problem, so don't try 
%             to balance classes (0)
%   foldSize - [1x1] number of points in each fold (N/nFold)
%              OR
%              [nClass x 1] number of points of each class for each fold
%             N.B. -ve=set the training-set size,  +ve=set the test-set size
%   randseed - [1x1] seed for the random number generator
%   repeats  - [1x1] how many sets of nFolds to generate (1)
%   zeroLab  - [bool] do we treat 0 labels as ignored or true labels (0)
% Outputs:
%   fIdxs -- [ N x nFold*repeats ] set of +1/0/-1 indicators of membership 
%            in each fold. where:
%             -1 = training point, 0 = excluded point, +1 = testing point
%
% Note: to do a double nested cross-validation use:
%   outerfIdxs = gennFold(Y,nFold);
%   for fiout=1:size(outerfIdxs,2);
%      innerfIdxs = gennFold((Y*double(outerfIdxs(:,fi)<0)),nFold);
%      ....
%   end
%
% Copyright 2006-     by Jason D.R. Farquhar (jdrf@zepler.org)

% Permission is granted for anyone to copy, use, or modify this
% software and accompanying documents for any uncommercial
% purposes, provided this copyright notice is retained, and note is
% made of any changes that have been made. This software and
% documents are distributed without any warranty, express or
% implied
if ( nargin < 2 ) nFold=10; 
elseif ( ischar(nFold) && ~any(strcmp(nFold,{'loo','llo'})) ) varargin={nFold varargin{:}}; nFold=[];
end;
opts=struct('indepSP',0,'perm',0,'foldSize',[],'regress',0,'randseed',{[]},'repeats',[],'dim',[],'zeroLab',0,'nFold',[]);
opts=parseOpts(opts,varargin);
dim=opts.dim; if (isempty(dim) ) dim=ndims(Y); end;
if ( isempty(nFold) ) nFold=opts.nFold; end;
if ( isempty(nFold) && isempty(opts.foldSize) ) nFold=10; end;

% deal with degenerate cases
if ( nFold==1 )     foldIdxs = -ones(size(Y)); return;              % all training
elseif ( nFold==0 ) foldIdxs =  ones(size(Y)); return;              % no folding, all testing
elseif ( isequal(nFold,'loo') || isequal(opts.foldSize,1) )         % Leave-one-out
  szY=size(Y); 
  foldIdxs=eye(prod(szY(setdiff(1:end,dim))))*2-1;
  if ( numel(dim)>1) foldIdxs=reshape(foldIdxs,szY(setdiff(1:end,dim)),[]); end;
  return;
elseif ( isequal(nFold,'llo') ) % leave label out
  key=unique(Y(:));
  foldIdxs=-ones([prod(size(Y)),numel(key)]);
  for fi=1:numel(key); foldIdxs(Y(:)==key(fi),fi)=1; end;
  foldIdxs = reshape(foldIdxs,[size(Y) numel(key)]);
  return;  
end

% set rand state
if(~isempty(opts.randseed)) 
   oseed=rand('state'); rand('state',opts.randseed); 
end

if ( size(Y,dim)==1 && isequal(dim,2) ) %&& ~all(Y(:)==-1 | Y(:)==0 | Y(:)==1) ) % label set... 
   if ( opts.regress ) Y=true(size(Y)); else Y=lab2ind(Y,[],[],opts.zeroLab,0); end; 
end 

% deal with n-d inputs
if( ~isequal(dim,ndims(Y)) ) % transpose if sub-probs in the 1st dimension
  Y=permute(Y,[setdiff(1:ndims(Y),dim) dim]); dim=ndims(Y)-(0:numel(dim)-1); 
end;
szY=size(Y); szY(end+1:dim)=1;
Y  =reshape(Y,prod(szY(1:dim-1)),szY(dim)); % make n-d inputs 2-d

% convert to per-class format - robustly so works in most indepSP cases also
[Yu,ans,idx] = unique(Y,'rows'); 
oY = Y;
Y  = -ones(size(Y,1),size(Yu,1));
for ci=1:size(Y,2); Y(idx==ci,ci)=1; end;
if ( ~opts.zeroLab ) Y(:,all(Yu==0,2))=[]; Yu(all(Yu==0,2),:)=[]; end; % remove zero labelled points

% deal with special types of call

% #1: independent sub-problems are treated as set of calls
if ( opts.indepSP && size(Y,2)>1 ) 
   foldIdxs=zeros([size(Y),abs(nFold)],'single');
   for spi=1:size(Y,2);
      foldIdxs(:,spi,:)=gennFold(Y(:,spi),nFold,opts,'indepSP',0);
   end

% #2: leave-one-out folding!
elseif ( isequal(abs(nFold),size(Y,1)) || strcmp(nFold,'loo') || (isempty(nFold) && isequal(opts.foldSize,1)) )
   foldIdxs=-ones(size(Y,1)); foldIdxs(1:size(Y,1)+1:end)=1; 

% #3: normal folding
else 

  if ( ~isequal(opts.perm,0) ) %permutate the inputs if wanted 
    % generate a random permutation
    if ( isequal(opts.perm,1) ) perm=randperm(size(Y,1)); 
    elseif( opts.repeats > 1 || numel(opts.perm)~=max(size(Y)) ) 
      error('Invalid permutation specfication');
    end;
  else
    perm=1:size(Y,1); % linear initial permutation
  end;

  if ( ~isempty(opts.foldSize) ) % make each fold have at most foldSize elm
    fSize = opts.foldSize;
    if( numel(fSize)==1 && size(Y,2)>1 ) % split proportionally between classes to sum to fSize
      fSize = fSize.*[sum(Y>0,1)./sum(Y(:)>0)]; 
    end
	 if ( all(fSize>sum(Y>0,1)/2) ) fSize=-(sum(Y>0,1)-fSize); end;
  else
    fSize = sum(Y>0,1)./nFold; % compute per-lab fold size
  end

  if ( abs(nFold) > size(Y,1) ) error('More folds than datapoints!'); end;

  % number of folds per repeat  
  repFold = min(abs(nFold),floor(min(sum(Y>0,1)./abs(fSize(:))')+1e-6));
  repeats = opts.repeats;
  if ( isempty(repeats) ) repeats=ceil(nFold/repFold); end % spec from nFold
  
  foldIdxs=genFold(Y(perm,:),repFold,fSize); % generate the first repeat
  foldIdxs(perm,:)=foldIdxs;         % undo perm to, store in orginal order

  % generate the repeats if wanted
  for i=2:repeats;
    perm=randperm(size(Y,1));                  % gen rand permutation
    tfoldIdxs=genFold(Y(perm,:),repFold,fSize);  % generate this repeat
    tfoldIdxs(perm,:)=tfoldIdxs;               % undo permutation 
    foldIdxs=[foldIdxs tfoldIdxs];             % store result
  end
end

if ( ~isempty(opts.randseed) ) rand('state',oseed); end; % restore rand state

if ( numel(szY)>2 ) % deal with n-d inputs, by converting back to n-d
   if ( opts.indepSP )
      foldIdxs = reshape(foldIdxs,[szY,size(foldIdxs,ndims(foldIdxs))]);
   else
      foldIdxs = reshape(foldIdxs,[szY(1:end-1),size(foldIdxs,ndims(foldIdxs))]);
   end
end

return;

function [foldIdxs]=genFold(Y,nFold,fSize,fOffset)
% Loop to actually generate the folds
% convert binary as special case
if( nargin<4 ) fOffset=[]; end;
if( size(Y,2)==1 ) Y=[Y -Y]; end;
if( numel(fSize)==1 ) fSize=fSize*[sum(Y>0,1)./sum(Y(:)>0)]; end;
if( ~all(fSize==floor(fSize)) ) 
  % spread the non-integer part (roughly) equally over folds
  % N.B. doing this *right* to exactly equally spread examples is quite fiddly..
  if ( isempty(fOffset) ) fOffset=randperm(size(Y,2))./size(Y,2); end;
  fOffset(fSize==floor(fSize))=0; % no jitter if not needed
else
  fOffset=zeros(size(Y,2),1);
end; 
foldIdxs=zeros([size(Y,1),abs(nFold)],'single');
for l=1:size(Y,2);
  fSizel=abs(fSize(l));
  lPos=find(Y(:,l)>0); % get the pts in this class
  if ( isempty(lPos) ) continue ; end;
  % assign points in this class to the corrospending folds.
  for fold=1:abs(nFold);
     idx = floor((fold-1)*fSizel+(fold>1)*fOffset(l))+1:min(numel(lPos),floor(fold*fSizel+fOffset(l)));
     % last fold gets all the rest of the data
     if(fold==abs(nFold) && ~isempty(idx) && numel(lPos)<idx(end)+fSizel*.5 ) 
        idx = floor((fold-1)*fSizel+(fold>1)*fOffset(l))+1:numel(lPos);
     end
     % set the given points to be included in this fold. 
     foldIdxs(lPos,fold)=-1; % default to exclude these points
     foldIdxs(lPos(idx),fold)=1; % unless they're in this fold
  end
end
% negative fSize means invert sense of train/test
if ( any(fSize(:) < 0) ) foldIdxs=-foldIdxs; end;
return;

%----------------------------------------------------------------------------
function []=testCase()

% test
Y=randn(1000,1); Y(Y>.1)=1; Y(Y<-.1)=-1; Y(abs(Y)<.1)=0;

foldIdxs=gennFold(Y,10,'perm',0);

% validate the class counts
for fi=1:size(foldIdxs,2); 
  fprintf('Fold(%2d)\t',fi);
   for spi=1:size(Y,2); 
      nyi(:,spi,fi)=[sum(Y(foldIdxs(:,fi)<0,spi)>0)... % trn Y+
                     sum(Y(foldIdxs(:,fi)>0,spi)>0)... % tst Y+
                     sum(Y(foldIdxs(:,fi)<0,spi)<0)... % trn Y-
                     sum(Y(foldIdxs(:,fi)>0,spi)<0)];  % tst Y-
      fprintf('sp(%2d) trn: %g+ %g-  tst: %g+ %g-\n',spi,nyi([1 3],spi,fi),nyi([2 4],spi,fi));
    end; 
end


% Double nested cv
Y = floor(rand(100,1)*(3-eps))+1;
nFold=10;
outerfIdxs = gennFold(Y,nFold);
fi=1;
for fi=1:size(outerfIdxs,2);
   Ytrn = (Y.*double(outerfIdxs(:,fi)<0));
   Ytst = (Y.*double(outerfIdxs(:,fi)>0));
   innerfIdxs = gennFold(Ytrn,nfolds);
   
   % Inner cv to determine model parameters
   cvres(fi)=cvtrainKLR(X,Y,innerfIdxs);
   [ans optI] = max(cvres(fi).tstauc); Copt = Cs(optI);
   
   % Re-train with all training data with this model parameter
   [alphab,p,J,dv]=klr_cg(K,Ytrn,Copt,'tol',1e-8,'maxEval',10000,'verb',-1);
   
   % Outer-cv performance recording
   res.trnauc(:,fi) =dv2auc(Ytrn,p);   res.tstauc(:,fi) =dv2auc(Ytst,p);
   res.trnconf(:,fi)=dv2conf(Ytrn,p);  res.tstconf(:,fi)=dv2conf(Ytst,p);
   res.trnbin(:,fi) =conf2loss(trnconf(:,fi),'cr');
   res.tstbin(:,fi) =conf2loss(tstconf(:,fi),'cr');
end

