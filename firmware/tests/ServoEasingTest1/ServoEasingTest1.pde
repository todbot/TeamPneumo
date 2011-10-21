//
// NOTE NOTE NOTE
//  this now lives at its own repo in 
//    https://github.com/todbot/ServoEaser
// NOTE NOTE NOTE
//
// ServoEasingTest1.pde -- first attempt at making Easing library usable
//                         in a non-blocking context
//
// 2011, TeamPneumo, Tod E. Kurt, http://todbot.com/blog/
//
//

#include <Easing.h>
#include <Servo.h>

const int debug = 1;

const int ledPin   = 13; 
const int servoPin = 7;


// begin these all go in a class
Servo servo1; 

int servoStartPos = 0;
int servoCurrPos;   // current servo position, best of our knowledge
int servoChangePos; // from servoMove list
int servoTime;      // from servoMove list
int servoTick;      // count of easing moves within move duration 
int servoTickCount;  // number of frames between start & end pos
unsigned long servoLastMillis;
int servoMovesIndex = 0;
int servoMovesCount;
// end these all go in a class

int servoFrameTime = 10;  // minimum time between servo updates

typedef struct _servoMove {
  int pos;      // position of servo in degrees
  int millis;   // duration in milliseconds to get to and stay at that position
} ServoMove;

// configurable list of servo moves
int myServoMovesCount = 7;
ServoMove myServoMoves[] = {
  {  0, 2000},
  {180, 2000},
  {  0, 2000},
  {180, 2000},
  { 90, 2000},
  {180, 2000},
  { 45, 3000},
};

//
void setup()
{
  Serial.begin(19200);

  servoBegin();

  Serial.println("ServoEasingTest1 ready");
}

//
void loop()
{
  //easingTest();
  servoUpdate();

}


// in a class
void servoBegin()
{
  servo1.attach( servoPin );

  servoMovesIndex = 0;

  servoStartPos = myServoMoves[ servoMovesIndex ].pos;  // get first position
  servoTime     = myServoMoves[servoMovesIndex].millis;
  servoMovesCount = myServoMovesCount;

  servoCurrPos  = servoStartPos;  // get everyone in sync
  servoChangePos = 0; 

  servoTickCount = servoTime / servoFrameTime;
  servoTick = 0;

  servo1.write( servoStartPos );  
}

// in a class
void servoGetNewPos()
{
  servoMovesIndex++;
  if( servoMovesIndex == servoMovesCount ) {
    servoMovesIndex = 0;
  }
  servoStartPos  = servoCurrPos; // current position becomes new start position

  //                    180                                 0
  //                      0                               180
  servoChangePos = myServoMoves[servoMovesIndex].pos - servoStartPos ;
  servoTime      = myServoMoves[servoMovesIndex].millis;

  servoTickCount = servoTime / servoFrameTime;
  servoTick = 0;

  if( debug ) {
    Serial.print("new start,change,time:");
    Serial.print(servoStartPos); Serial.print(",");
    Serial.print(servoChangePos); Serial.print(",");
    Serial.print(servoTime); Serial.print("\n");
  }
}

// in a class
void servoUpdate()
{
  if( millis() - servoLastMillis > servoFrameTime ) { 
    servoLastMillis = millis();

    servoCurrPos = servoEasingFunc( servoTick, 
                                    servoStartPos, 
                                    servoChangePos, 
                                    servoTickCount );

    if( debug ) {
      Serial.print("tick:"); Serial.print(servoTick);
      Serial.print(','); Serial.print(servoTickCount);
      Serial.print(':'); Serial.print(servoStartPos); 
      Serial.print(','); Serial.print(servoChangePos);
      Serial.print(':');Serial.println(servoCurrPos);
    }

    servo1.write( servoCurrPos );

    servoTick++;
    if( servoTick == servoTickCount ) { // time for new position
      servoGetNewPos();
    }
  }

}


//
// t: current time, b: beginning value, c: change in value, d: duration
// t and d can be in frames or seconds/milliseconds
//
float servoEasingFunc (float t, float b, float c, float d)
{
  return Easing::easeInOutCubic( t, b, c, d );
}


// -------------------------------------------------------------------


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
