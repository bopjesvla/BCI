function [spMx]=mkspMx(classIDs,spType,compBinp,classNms)
% Generate different sets of sub-probs from the input label set
%
% spMx=mkspMx(classIDs,spType,compBinp,classNms)
% Inputs:
%  classIDs  - [nClass x 1] or {nClass x 1} set of IDs
%                (can be numeric or cell-array of strings)
%  spType -- {str} the types of sub-problem to decompse the multi-class into. ('1vR')
%            One of:
%              '1v1','1vR',
%              P==Positive only:           'Pv1','PvR'
%              Positive vs Negative only : 'PvN'
%         OR
%            [nSp x nClass] sub-problem encodeing/decoding matrix of -1/0/+1 values.
%                      with 1 for when the corrospending class should be positive case, -1
%                      for when negative and 0 for when not used in this sub-prob
%                      e.g. Yi=lab2ind(Y,[1 -1 0;1 0 -1;0 1 -1]);
%         OR 
%            {nSp x 1} cell array of class names/ids for which to construct a 1vR set of
%                      sub-problems
%                      e.g. sp=mkspMx(Y,{'c1' 'c2' 'c3'}); % make c1 v c2+c3,c2 v c1+c3,c3 v c1+c2
%         OR 
%            {nSp x {c1 c2}} cell array of 2x1 cell arrays for each sub-problem, e.g. {sp1 sp2 sp3} 
%                      Each sub-problem cell array holds the negative then positive class label 
%                      sets, either as numbers which match the numbers in classIDs or as 
%                      strings which match the labels in classNms
%                      N.B. if 'c2' is empty then this is treated as matching all classes
%                      e.g. sp=mkspMx(Y,{{1 0} {2 0} {[1 2] [3 4]}) % sp: 1v0, 2v0, [1|2]v[3|4]
%                           sp=mkspMx(Y,{{'c1' 'c2'} {'c3' {'c1' 'c2'}}},[],{'c1' 'c2' 'c3'})
%                           sp=mkspMx(Y,{{'c1' ''} {{'c1' 'c2'} ''}); %sp: c1vR, [c1|c2]vR
%  compBinp -- [bool] do we compress binary problems into single problem? (true)
% Outputs:
%  spMx   - [nSubProb x nClass] encoding/decoding matrix used to map from 
%           class labels to/from binary sub-problems.
%           N.B. to decode binary predictions use:
%                  dv([1 x nSubProb])*spMx -> [1 x nClass]
%            set of decision values which indicate the confidence in each
%            class.
if ( nargin < 2 || isempty(spType) ) spType='1vR'; end;
if ( nargin < 3 || isempty(compBinp) ) compBinp=true; end;
if ( nargin < 4 ) classNms=[]; end;
if ( ischar(spType) ) spType={spType}; end;
if ( iscell(classIDs) ) 
  if ( isempty(classNms) ) classNms=classIDs; classIDs=(1:numel(classIDs))'; 
  elseif ( numel(classIDs)==numel(classNms) ) 
    warning('Cell array of classIDs and classNms given. classIDs ignored.');
    classIDs=(1:numel(classIDs))';
  else
    error('Cant use cell array for both classIds and classNms');
  end
end

nsp=0; nClass=numel(classIDs);
if ( nClass<= 1 ) warning('Only 1 class input!'); spMx=1; end
if ( iscell(spType) && ischar(spType{1}) && ~isempty(strmatch(spType{1},{'1v1','1vR','Pv1','PvR','PvN'})) ) % cell array of type strings
   for i=1:numel(classIDs);
      % Positive only, so skip negative classIDs
      if ( ~isempty(strmatch('P',spType)) && classIDs(i)<0 ) continue; end;
      % 1v1 first
      if ( ~isempty(strmatch('1v1',spType)) || ~isempty(strmatch('Pv1',spType)) )
         for j=i+1:numel(classIDs);
            nsp=nsp+1; spMx(nsp,i)=+1; spMx(nsp,j)=-1; % fill in decoding matrix
         end
      end
      % Then 1vsRest
      if ( ~isempty(strmatch('1vR',spType)) || ~isempty(strmatch('PvR',spType)) )
         nsp=nsp+1; rest=[1:i-1 i+1:numel(classIDs)];
         spMx(nsp,i)=+1; spMx(nsp,rest)=-1; % fill in decoding matrix
      end

      % Positive vs negative only
      if ( ~isempty(strmatch('PvN',spType)) ) 
         j=find(classIDs==-classIDs(i)); % find the negative label
         if ( ~isempty(j) )
            nsp=nsp+1; spMx(nsp,i)=+1; spMx(nsp,j)=-1; 
         else
            warning('No negative label found for: %d',classIDs(i));
         end
      end   
   end

elseif( isnumeric(spType) )
   if ( ndims(spType)==2 && size(spType,1)==1 && numel(classIDs)>2 ) % vector of +ve class labels input
      nSp=numel(spType); spMx=-ones(nSp,nClass); 
      for spi=1:size(spMx,1); spMx(spi,classIDs==spType(spi))=1; end; % fill in the positive class bits
   elseif ( size(spType,2)~=numel(classIDs) )
      error('subProb matrix and classIDs dont agree!');
   elseif ( size(spType,2)==nClass ) 
     spMx=spType;
    end

elseif( iscell(spType) ) %cell array of +ve/-ve class labels
  if( numel(spType)==2 && ...
      ((isnumeric(spType{1}) && isnumeric(spType{2})) ...
       || (ischar(spType{1}) && ischar(spType{2})) ...
       || iscell(spType{1}) && iscell(spType{2}) && (numel(spType{1})~=2 || numel(spType{2})~=2) )  ) 
     spType={spType}; 
  elseif( numel(spType)==1 ) %single input=set of classes to make a 1vR decomp for
	 tmp=spType{1};
	 % regexp to expand to get the set of matching class names to use
	 if(ischar(tmp) && any(strncmp(tmp,{'%','#'},1)) && any(strncmp(tmp(end),{'%','#'},1))) 
		t=false(size(classNms));
		for ci=1:numel(classNms);
		  if( ~isempty(regexp(classNms{ci},tmp(2:end-1))) ) t(ci)=true; end;
	   end
		tmp=classNms(t); % the subset of classnames we should use
	 end
	 spType={};
	 for spi=1:numel(tmp);
		spType{spi}={tmp(spi) tmp([1:spi-1 spi+1:end])};
	 end
  end;
  nSp=numel(spType);
  spMx=zeros(nSp,nClass); % convert to spMx format
  for spi=1:size(spMx,1);
    spIds = spType{spi};
    if ( isnumeric(spIds) )
		if ( numel(spIds)==1 )     spIds   ={spIds(1) cat(1,spIds([1:spi-1]),spIds([spi+1:end]))};
		elseif ( numel(spIds)==2 ) spIds   ={spIds(1) spIds(2)}; % single 2x1 array
		end;
	 elseif ( ischar(spIds) ) % set of class-ids to use
		spIds={spType(spi) spType([1:spi-1 spi+1:end])};
	 end
    if ( iscell(spIds{1}) || ischar(spIds{1}) ) spIds{1}=classIDs(matchClassNms(spIds{1},classNms));end;
	 % empty 2nd set=Rest
	 if ( isempty(spIds{2}))                     spIds{2}=classIDs(setdiff(1:nClass,spIds{1})); 
	 elseif(iscell(spIds{2})||ischar(spIds{2}))  spIds{2}=classIDs(matchClassNms(spIds{2},classNms));end;

    spMx(spi,any(repop(classIDs(:),'==',spIds{1}(:)'),2))=1;
    spMx(spi,any(repop(classIDs(:),'==',spIds{2}(:)'),2))=-1;
  end
else error('Dont know how to handle spMx');
end

if ( compBinp && numel(classIDs)==2 ) spMx(2:end,:)=[]; end; % bin special case
return;

%---------------------------------------------------------------------------
function [tmp]=matchClassNms(spNms,classNms)
if ( ischar(spNms) ) spNms={spNms}; end;
tmp=false(numel(classNms),1);
for i=1:numel(spNms);
  tgt=spNms{i};
  t=false(numel(classNms),1);
  if ( any(strncmp(spNms{i},{'%','#'},1)) && any(strncmp(spNms{i}(end),{'%','#'})) ) % use regexp match
	 for ci=1:numel(classNms);
		if( ~isempty(regexp(classNms{ci},tgt(2:end-1))) ) t(ci)=true; end;
	 end
  else
	 t=strncmp(tgt,classNms,numel(tgt)); 
  end
  if( ~any(t) && ~isempty(spNms{i}))
	 error(sprintf('Couldnt match class name: %s',spNms{i})); %error if name
  end
  tmp = tmp(:) | t(:);
end
return;


%---------------------------------------------------------------------------
function testCase()
spMx=mkspMx([1 2 3],'1v1');
spMx=mkspMx([2 3],'1vR');

Y=ceil(rand(100,1)*2.99);
Ysp = lab2ind(Y,[1 2 3],spMx);

% convert back to 1vR format...
Yl = Ysp*spMx;
