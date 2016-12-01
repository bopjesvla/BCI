#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
buffdir=`dirname $0`

dataacq='java';
if [ $# -gt 0 ]; then dataacq=$1; fi
sigproc=0;
if [ $# -gt 1 ]; then sigproc=$2; fi

echo Starting the non-saving java buffer server \(background\)
dataAcq/startJavaNoSaveBuffer.sh &
bufferpid=$!
echo buffpid=$bufferpid
sleep 5


echo Starting the data acquisation device $dataacq \(background\)
if [ $dataacq == 'audio' ]; then
  dataAcq/startJavaAudio.sh localhost 2 &
elif [ $dataacq == 'matlab' ]; then
  dataAcq/startMatlabSignalProxy.sh &
else
  dataAcq/startJavaSignalproxy.sh &
fi
dataacqpid=$!
echo dataacqpid=$dataacqpid

if [ $sigproc -eq 1 ]; then
  echo Starting the default signal processing function \(background\)
  matlab/signalProc/startSigProcBuffer.sh &
  sigprocpid=$!
fi


echo Starting the event viewer
dataAcq/startJavaEventViewer.sh
kill $bufferpid
kill $dataacqpid
kill $sigprocpid
