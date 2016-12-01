% Input:
%  a0    - absolute start time of the animation
%  visT0 - absolute start time of visImg
%       (N.B. visT0 is *start* time of the frame!, thus frame 1 runs from visT0 -> visT0+frameDuratin)
%  frameDuration -- time for each frame
%  visImg - [nSymb x nFrame x 3] image to display parts of
%  imgh   - handle for the image object to update contents of
% Output:
%  visImg - updated visImg
%  visT0  - time for the 1st frame of visImg
%  visEnd - index of the last valid frame of visImg


a0=t0+visT0; % absolute time of start of this sequence
elapsedTime=getwTime()-a0;
ofi=-1;fi=max(0,floor(elapsedTime/frameDuration))+1;
while ( elapsedTime<animateDuration )
  if ( ofi~=fi ) % only actually draw if something changed
	 set(imgh,'cdata',visImg(:,fi+(0:visDur/frameDuration-1),:)); % update display
	 drawnow;
  end
  if ( verb>1 ) fprintf('%d) f=%d t=%g t_e=%g\n',ei,fi,getwTime()-t0,getwTime()-a0); end;
  sleepSec(frameDuration*.5);
  f0=getwTime();
  elapsedTime = f0-a0; % time left to run in this trial
  ofi=fi;
  fi=max(0,floor(elapsedTime/frameDuration))+1; % get closest frame time
  if ( fi-ofi>1 )
	 fprintf('%d) Dropped frames %d...\n',fi,fi-ofi-1);
  end
end
set(imgh,'cdata',visImg(:,fi+(0:visDur/frameDuration-1),:)); % update display
drawnow;

										  % shift the image and update visEnd
if(fi>1) % remove the (fi-1) shown frames from the start of the visible image
  visImg(:,1:(visEnd-fi+1),:)=visImg(:,fi:visEnd,:);
  visEnd=visEnd-fi+1;                  % new last valid frame
  visT0 =visT0+((fi-1)*frameDuration); % new absolute time of the first frame = (fi-1) frames later
end
