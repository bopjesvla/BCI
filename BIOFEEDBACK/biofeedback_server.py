#Originally written for py3, but because of dependencies on FieldTrip only runs in py2
#So: RUN IN PY2
import serial
import time
import sys
import os
import random
from PIL import Image, ImageFilter, ImageGrab
#import pyscreenshot as ImageGrab
#External dependencies: pySerial, Pillow (,pyscreenshot (on linux))

import PythonBufferClientInterface as PBCI


#Try to find an arduino and then create a connection.
ser = None

for i in range(4):
    try:
        ser = serial.Serial('COM'+str(i), 9600)
        break
    except serial.SerialException:
        print("[-] - Cannot find arduino at COM"+str(i))
if not ser:
    for i in range(9):
        try:
            ser = serial.Serial('/dev/ttyUSB'+str(i), 9600)
            break
        except serial.SerialException:
            print("[-] - Cannot find arduino at /dev/ttyUSB"+str(i))
if not ser:
    print("[-] - Please check the arduino is actually connected...")
    print("[-] - Exiting...")
    sys.exit(1)
print("[+] - Arduino found!")
print("[*] - Waiting for the connection to be established...")          
time.sleep(5) 
print("[+] - Done!")

PURPLE = (116, 29, 139)
CYAN = (10, 130, 141)
YELLOW = (165, 141, 9)
GREY = (121, 121, 121)
DIST_TRESHOLD = 50

#Calibration for 800x600 resolution
POLLXY = (910,960)

ACTIVATION_CHANCE = 0.0


def euclidean_dist(tup1, tup2):
    dist = 0
    for i in range(3):
        dist += abs(tup1[i] - tup2[i])
    return dist

def main():
    print("============================")
    hostname='localhost'
    port=1972
    PCI = PBCI.PythonClientInterface(hostname,port)
    print("============================")
    #print(time.time())
    #im = Image.open(os.getcwd()+"\\cybathlon.png")
    im = ImageGrab.grab()
    #print(time.time())
    #print()
    #im.show()
    #im.save("calibration.jpg","JPEG")
    
    class_last = None
    class_cur = None
    try:
        while True:
            #print("Grabbing screen")
            im = ImageGrab.grab()
            rgb = im.getpixel(POLLXY)[0:3]
            print(rgb)
            msg = None
            if euclidean_dist(rgb, PURPLE) < DIST_TRESHOLD:
                msg = "L#"
            elif euclidean_dist(rgb, CYAN) < DIST_TRESHOLD:
                msg = "R#"
            elif euclidean_dist(rgb, YELLOW) < DIST_TRESHOLD:
                msg = "B#"
            if msg:
                print("[*] - Found " + msg)
                if random.random() <= ACTIVATION_CHANCE:
                    print("[*] - Sending message: " + msg)
                    ser.write(msg.encode())
                    if ser.readline() != "":
                        print("[+] - Motion done!")
                        continue
            if msg or euclidean_dist(rgb, GREY) < DIST_TRESHOLD:
                #There is training info to send
                if not msg:
                    class_cur = "G#"
                else:
                    class_cur = msg
                if class_last is None or class_last != class_cur:
                    #The start or end of something
                    if class_last == "G#":#Stopped being grey, so end of baseline
                        PCI.sendMSG("stimulus.baseline","end")
                    elif class_last != "G#" and not class_last is None:#Stopped being nongrey, so end of trial
                        PCI.sendMSG("stimulus.trial","end")
                        
                    if class_cur == "G#":#Became grey, so start of baseline
                        PCI.sendMSG("stimulus.baseline","start")
                    elif class_cur != "G#":#Became nongrey, so start of trial
                        PCI.sendMSG("stimulus.trial","start")
                #Now just send target info
                sendval = "99 Rest"
                if class_cur == "L#":
                    sendval = "2 Left-Hand"
                elif class_cur == "R#":
                    sendval = "3 Right-Hand"
                elif class_cur =="B#":
                    sendval = "1 Both"
                PCI.sendMSG("stimulus.target",sendval)
                class_last = class_cur
                        
                        
    except KeyboardInterrupt:
        print("\n[*] - Received KeyboardInterrupt.")
        PCI.close()


if __name__ == "__main__":
    main()
