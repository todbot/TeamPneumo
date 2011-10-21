//
// ServoEasingTest1.pde -- first attempt at making Easing library usable
//                         in a non-blocking context
//
// 2011, TeamPneumo, Tod E. Kurt, http://todbot.com/blog/
//
//

#include <Servo.h>
#include "./ServoEaser.h"

const int debug = 1;

const int ledPin   = 13; 
const int servoPin = 7;


// begin these all go in a class
Servo servo1; 

int servoFrameTime = 10;  // minimum time between servo updates


// configurable list of servo moves
int myServoMovesCount = 8;
ServoMove myServoMoves[] = {
  {  0, 2000},
  {180, 2000},
  {  0, 2000},
  {180, 2000},
  { 90, 2000},
  {180, 2000},
  { 45, 3000},
  {135, 3000},
};

ServoEaser servoEaser;

// from Easing::linearTween()
float linearTween (float t, float b, float c, float d) {
	return c*t/d + b;
}
// from Easing::easeInOutQuart()
float easeInOutQuart (float t, float b, float c, float d) {
	if ((t/=d/2) < 1) return c/2*t*t*t*t + b;
	return -c/2 * ((t-=2)*t*t*t - 2) + b;
}


//
void setup()
{
  Serial.begin(19200);

  servo1.attach( servoPin );

  servoEaser.begin( servo1, servoFrameTime, myServoMoves, myServoMovesCount );
  servoEaser.setEasingFunc( linearTween );
  servoEaser.setEasingFunc( easeInOutQuart );

  Serial.println("ServoEasingTest2 ready");
}

//
void loop()
{
  //easingTest();
  servoEaser.update();

}






// -------------------------------------------------------------------

/*
// from Easing library example
void easingTest()
{
  //servo1.write(Easing::easeInOutCubic(pos, 0, 140, dur));
  int dur = 100; //duration is 100 loops
  for (int pos=0; pos<dur; pos++){
    //move servo from 0 and 140 degrees forward
    servo1.write(Easing::easeInOutCubic(pos, 0, 140, dur));
    delay(15); //wait for the servo to move
  }
  
  delay(1000); //wait a second, then move back using "bounce" easing
  
  for (int pos=0; pos<dur; pos++){
    //move servo -140 degrees from position 140 (back to 0)
    servo1.write(Easing::easeInOutCubic(pos, 140, -140, dur));
    //servo1.write(Easing::easeInOutBounce(pos, 140, -140, dur));
    delay(15);
  }

  delay(1000);
}
*/