% Made by Ceci Verbaarschot
%
% Function to determine the EMG threshold for action. 
% 
% perc: value between 0 and 1. Determines the difficulty level for acting. 
%
% The threshold for acting is defined as 
% the mean EMG activity in rest + (perc * the max difference between EMG in action and rest) 
function threshold = setEMGthreshold(data,devents,hdr,perc)
    % Add all necessary paths
    run ../utilities/initPaths.m % check path when ran from a different computer
    
    if ~exist('perc')
        perc = 0.8; % perc is default set to 0.8
    end
   
    X = cat(3,data.buf); % keep original data
    
    % subtract bipolar EMG channels
    % subtract bipolar EMG channels
    %X =repop(X,'-',mean(X,2)); % center
    X =repop(X(1:5,:,:),'-',X(5,:,:)); % re-ref
    
    % Filter
     if( isfield(hdr,'Fs') ) fs=hdr.Fs; elseif ( isfield(hdr,'fSample') ) fs=hdr.fSample; else fs=hdr.fs; end;
    freqband = [60 70 250 256];
    outsz=[size(X,2) size(X,2)];
  
    len=size(X,2);
    filt=mkFilter(floor(len/2),freqband,fs/len);
    X   =fftfilter(X,filt,outsz,2,1,[],1);
    
    %X   =abs(X);
    X   =cat(1,sum(X(1:2,:,:),1)/2,sum(X(3:4,:,:),1)/2);
    
    
    % Rectify the signal = take absolute value
    %X = abs(X);  
    %mean(mean(X))
    
    % Low pass filter the signal (cutoff =~ 15 Hz, since tau = 10ms for EMG), Welter et al., 2000; 1st order)
%    [B,A] = butter(1,16/128,'low');
%    X     = filter(B,A,X,[],2);
%     for ch = 1:size(X,1) % Per channel
%         X(ch,:) = filter(B,A,X(ch,:));  
%     end
%     % keep only EMG channels and subtract bipolar EMG channels
%     for t=1:length(data)
%         X(1,:) = data(t).buf(2,:)-data(t).buf(1,:); % right hand: check which channels to select
%         X(2,:) = data(t).buf(4,:)-data(t).buf(3,:); % left hand: check which channels to select
%         X(3:end,:) = [];
%     end
%     
%     % spectrally filter to the range of interest
%     if( isfield(hdr,'Fs') ) fs=hdr.Fs; elseif ( isfield(hdr,'fSample') ) fs=hdr.fSample; else fs=hdr.fs; end;
%     freqband = [47 51 250 256];
%     outsz=[size(X,2) size(X,2)];
%     if (size(X,2)>10 && ~isempty(fs)) 
%       len=size(X,2);
%       filt=mkFilter(freqband,floor(len/2),fs/len);
%       X   =fftfilter(X,filt,outsz,2,2);
%     end
%     
%     % Rectify the signal = take absolute value
%     for t=1:length(X)
%         X(t).buf = abs(X(t).buf);  
%     end
%     
%     % Low pass filter the signal (cutoff =~ 15 Hz, since tau = 10ms for EMG), Welter et al., 2000; 1st order)
%     for ch = 1:size(X(1).buf,1) % Per channel
%         for t=1:length(X)
%             [B,A] = butter(1,16/128,'low');
%             X(ch,:) = filter(B,A,X(ch,:));  
%         end
%     end
    
    rightMoveData = X(2,:,find(strcmp({devents.value},'Rechter hand'))); 
%     for t=1:length(rightMoveData)
%         rightMoveData(t).buf(1,:) = [];
%     end
    leftMoveData = X(1,:,find(strcmp({devents.value},'Linker hand')));
%     for t=1:length(leftMoveData)
%         leftMoveData(t).buf(2,:) = [];
%     end
    restData = X(:,:,find(strcmp({devents.value},'relax')));
    bothMoveData = X(:,:,find(strcmp({devents.value},'Beide handen')));
    
    % define mean EMG activity in rest and action
    meanEMGrest = mean(mean(median(restData,2)));
    meanEMGleft = mean(median(leftMoveData,2)); % select channels
    meanEMGright = mean(median(rightMoveData,2)); % select channels
    meanEMGboth = mean(median(bothMoveData,2));
    
    fprintf('Mean EMG (rest,left,right,both) = (%g,%g,%g,%g)\n',meanEMGrest,meanEMGleft,meanEMGright,meanEMGboth);
    figure(3);clf;image3d(X,3,'Zvals',{devents.value});
    
    % define max EMG activity in action
    meanEMGaction = max([meanEMGleft,meanEMGright,meanEMGboth]);
    
    % max difference between rest and action
    maxdiffEMG = abs(meanEMGrest - meanEMGaction);

    % set threshold for movement
    threshold = (meanEMGrest + (perc*maxdiffEMG));
    fprintf(['threshold: ',num2str(round(threshold))]);
end