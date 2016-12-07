import serial
import time
import sys
import os
import random
from PIL import Image, ImageFilter, ImageGrab
#import pyscreenshot as ImageGrab
#External dependencies: pySerial, Pillow (,pyscreenshot (on linux))


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
    #print(time.time())
    #im = Image.open(os.getcwd()+"\\cybathlon.png")
    im = ImageGrab.grab()
    #print(time.time())
    #print()
    #im.show()
    #im.save("calibration.jpg", "JPEG")

    try:
        while True:
            #print("Grabbing screen")
            im = ImageGrab.grab()
            rgb = im.getpixel(POLLXY)[0:3]
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
                    if ser.readline() != ""
                        print("[+] - Motion done!")
                        continue
    except KeyboardInterrupt:
        print("\n[*] - Received KeyboardInterrupt.")


if __name__ == "__main__":
    main()
