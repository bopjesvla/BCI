call ..\..\utilities\findMatlab.bat
if %ismatlab%==1 (
  start "Matlab" /b %matexe% -r "configureIM;startSigProcBuffer('epochEventType','stimulus.target','freqband',freqband,'clsfr_type','ersp','trlen_ms',trlen_ms,'calibrateOpts',calibrateOpts,'trainOpts',trainOpts,'contFeedbackOpts',contFeedbackOpts,'epochFeedbackOpts',epochFeedbackOpts,'userFeedbackTable',userFeedbackTable,'useGUI',0);quit;" %matopts%
) else (
echo configureIM;startSigProcBuffer^('epochEventType','stimulus.target','freqband',freqband,'clsfr_type','ersp','trlen_ms',trlen_ms,'calibrateOpts',calibrateOpts,'trainOpts',trainOpts,'contFeedbackOpts',contFeedbackOpts,'epochFeedbackOpts',epochFeedbackOpts,'userFeedbackTable',userFeedbackTable,'useGUI',0^);quit; | %matexe% %matopts%
)
