set batdir=%~dp0
cd %batdir%
call ..\utilities\findMatlab.bat
echo run ../matlab/utilities/initPaths.m;buffer_fileproxy^([],[],'%1'^);quit; | %matexe% %matopts%
