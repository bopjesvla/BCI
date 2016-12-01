set batdir=%~dp0
cd %batdir%
call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "run ../utilities/initPaths.m;erpViewer();quit;" %matopts%
) else (
  echo run ../utilities/initPaths.m;erpViewer;quit; | %matexe% %matopts%
)
