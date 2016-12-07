#include <Servo.h>

//CONSTANTS
int servoPins[3] = {A0, A1};//{Left, Right)
Servo servo[3];

//GLOBALS
int servoAngle[3] = {0, 0};//Unused as of yet
 
enum TargetServo {
	left,
	right,
	both,
	grey
};

TargetServo ts = grey;

void setup()
{
	//Open serial communication
	Serial.begin(9600); 
	//Attach all servos
	for (int i = 0; i < 2; i++) {
		servo[i].attach(servoPins[i]);
		servo[i].write(servoAngle[i]);
	}
}

void loop() {
	get_input();
	do_motion();
}


void get_input() {
	if (Serial.available() > 0) {
		String order = Serial.readStringUntil('#');
		if (order[0] == 'L'){
			ts = left;
		}
		else if (order[0] == 'R') {
			ts = right;
		}
		else if (order[0] == 'B') {
			ts = both;
		}
	}
}

void do_motion() {
	switch(ts) {
		case left:	move_type1(0); Serial.println("Done"); break;
		case right:	move_type1(1); Serial.println("Done"); break;
		case both: 	moveboth_type1(); Serial.println("Done"); break;
		default: return;
	}
	ts = grey;
}

//Different types of motion to test and tweak:

void move_type1(int i) {
	servo[i].write(0);
	delay(500);
	servo[i].write(180);
	delay(1000);
	servo[i].write(90);
	delay(500);
}

void moveboth_type1() {
	servo[0].write(0);
        servo[1].write(0);
	delay(500);
	servo[0].write(180);
        servo[1].write(180);
	delay(1000);
	servo[0].write(90);
        servo[1].write(90);
	delay(500);
}

void move_type2(int i) {

	for(int ang = 90; ang < 180; ang++) {                            
		servo[i].write(ang);
		servo[i].write(ang);    
		delay(50);                  
	}
 
	for(int ang = 180; ang > 0; ang--) {                             
		servo[i].write(ang);        
		servo[i].write(ang);   
		delay(50);      
	}
	
	for(int ang = 0; ang < 90; ang++) {                            
		servo[i].write(ang);
		servo[i].write(ang);    
		delay(50);                  
	}
}
