% add the buffer server .jar to the java class path
dataAcq_dir=fileparts(mfilename('fullpath')); % parent directory
if ( exist(fullfile(dataAcq_dir,'buffer','java'),'dir') ) % use java buffer if it's there
  bufferjavaclassdir=fullfile(dataAcq_dir,'buffer','java');
  bufferjar = fullfile(bufferjavaclassdir,'BufferServer.jar');
  if ( exist(bufferjar,'file') ) 
      javaaddpath(bufferjar); % N.B. this will clear all variables!
  end
end
										  % start the buffer server in the java thread
port=1972;
subject='test';
datv = datevec(now);
session=sprintf('%02d%02d%02d',datv(1)-2000,datv(2:3));
block  =sprintf('%02d%02d',datv(4:5));
savepath=fullfile('~','output',subject,session,block);
if ( ~exist(savepath,'dir') ) mkdir('-p',savepath); end;

% create the object, saving to the given location
svr=javaObject('nl.fcdonders.fieldtrip.bufferserver.BufferServer',savepath,port);
% run the server
svr.run();
