//
// ServoEasingTest2.pde -- library-based attempt at doing easing
//                         in a non-blocking context
//
// 2011, TeamPneumo, Tod E. Kurt, http://todbot.com/blog/
//
//

#include <Servo.h>
#include "./ServoEaser.h"
#include <Easing.h>

const int ledPin   = 13; 
const int servoPin = 7;


// begin these all go in a class
Servo servo1; 

int servoFrameMillis = 10;  // minimum time between servo updates


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

  // can begin with a list of servo moves
  //servoEaser.begin( servo1, servoFrameMillis,myServoMoves,myServoMovesCount);
  // or begin with just a framerate and starting position
  servoEaser.begin( servo1, servoFrameMillis, 0 );
  // and then set moves list later (or not at all)
  servoEaser.setMovesList( myServoMoves, myServoMovesCount );

  // ServoEaser defaults to easeInOutCubic() but you can change it
  //servoEaser.setEasingFunc( linearTween );
  //servoEaser.setEasingFunc( easeInOutQuart );
  // can even use Easing library if you want
  servoEaser.setEasingFunc( Easing::easeInOutElastic );

  Serial.println("ServoEasingTest2 ready");

  //servoEaser.easeTo( 180, 5000);
}

//
void loop()
{
  servoEaser.update();

  /*
  // can do manual easing too
  if( millis() > 6000 && millis() < 6005 ) { 
    servoEaser.easeTo( 0, 3000 );
  }
  if( millis() > 10000 && millis() < 10005 ) {
    servoEaser.easeTo( 45, 5000 );
  }
  */

    
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