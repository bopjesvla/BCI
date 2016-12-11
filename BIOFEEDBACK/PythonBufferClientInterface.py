#!/usr/bin/evn python
import sys
import numpy
import FieldTripPy3
import time

class PythonClientInterface:
    def __init__(self, hostname='localhost',port=1972,timeout=5000):
        self.init_time = time.time()
        self.ftc = FieldTripPy3.Client()
        # Wait until the buffer connects correctly and returns a valid header
        self.hdr = None;
        while self.hdr is None :
            print('Trying to connect to buffer on {}:{} ...'.format(hostname,port))
            try:
                self.ftc.connect(hostname, port)
                print('\nConnected - trying to read header...')
                self.hdr = self.ftc.getHeader()
            except IOError:
                pass
            
            if self.hdr is None:
                print('Invalid Header... waiting')
                time.sleep(1)
            else:
                print(self.hdr)
                print(self.hdr.labels)

    def sendMSG(self, mType, mVal):
        ev = FieldTripPy3.Event(sample = str(int((time.time() - self.init_time) * 1000)), offset=0, duration=0)
        ev.type = mType
        ev.value = mVal
        self.ftc.putEvents([ev])

    def close(self):
        self.ftc.disconnect()

    def test(self):
        ev = FieldTripPy3.Event(sample=21190, offset=0, duration=0)
        ev.type = "stimulus.target"
        ev.value = "3 Right-Hand"
        self.ftc.putEvents([ev])

if __name__ == "__main__":
    hostname='localhost'
    port=1972
    timeout=5000    
    if len(sys.argv)>1: # called with options, i.e. commandline
        hostname = sys.argv[1]
    if len(sys.argv)>2:
        try:
            port = int(sys.argv[2])
        except:
            print('Error: second argument ({}) must be a valid (=integer) port number'.format(sys.argv[2]))
            sys.exit(1)
    PCI = PythonClientInterface(hostname,port);
    PCI.test()
    PCI.close()
