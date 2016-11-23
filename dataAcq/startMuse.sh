#! /usr/bin/env bash
cd `dirname ${BASH_SOURCE[0]}`
buffdir=`dirname $0`
execname='muse-io'
if [ `uname -s` == 'Linux' ]; then
	 if  [ "`uname -a`" == 'armv6l' ]; then
		  arch='raspberrypi'
    else
		  arch='glnx86';
   fi
else # Mac
	 arch='maci'
fi
buffexe="$buffdir/buffer/bin/${execname}";
if [ -r "$buffdir/${execname}" ]; then
    buffexe="$buffdir/${execname}";
fi
if [ -r "$buffdir/buffer/bin/${arch}/${execname}" ]; then
	 buffexe="$buffdir/buffer/bin/${arch}/${execname}";
fi
if [ -r "$buffdir/buffer/${arch}/${execname}" ]; then
	 buffexe="$buffdir/buffer/${arch}/${execname}";
fi

if [ ${arch} == 'maci' ]; then
	# Argh: on mac need to ensure can find the libraries that muse-io depends on
   export DYLD_LIBRARY_PATH=${buffexe%/*}:$DYLD_LIBRARY_PATH
else
   # Argh: on linux also need the libraries that muse-io depends on
   export LD_LIBRARY_PATH=${buffexe%/*}:$LD_LIBRARY_PATH
fi

# 1) run the OSC -> ft_buffer converter with parameters for the MUSE  !in the background!
#    This will then wait for data from the MUSE and connection to the buffer
if [ $# -lt 1 ]; then 
  bufferhost=localhost:1972;
else
  bufferhost=$1;
  shift;
fi

oscport=1234
java -cp ${buffdir}/buffer/java/BufferClient.jar:${buffdir}/buffer/java/JavaOSC.jar:${buffdir}/buffer/java osc2ft /muse/eeg:${oscport} ${bufferhost} 4 220 1 10 &
# catch ctrl-c and kill the java too
trap 'kill %1' SIGTERM SIGINT SIGHUP

# 2) run the muse-io driver, by default search for device with name muse
musemac=00:06:66:6C:26:A5
echo Using the muse mac address = $musemac
echo You should change this to reflect the mac address of your specific device
echo or remove it for the muse-io to auto-search for the device \(doesn\'t work well on linux\)
$buffexe --preset ab --osc osc.udp://localhost:$oscport --50hz --device ${musemac} $@
if [ $? -ne 0 ]; then
	 echo "Error couldn't connect to the MUSE"
	 kill %1 # kill the background java job
	 exit -1
fi
