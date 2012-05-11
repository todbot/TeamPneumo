/**
 *
 * BillDetectorV1a -- Bill detector, bell ringer, & spinnybit twirler for
 *                    Cash Machine
 *     - for use with the 'billdetector1e' Arduino shield
 *
 * 2011, TeamPneumo, Tod E. Kurt, http://todbot.com/blog/
 *
 *
 *
 * Note: all libraries except standard system libraries are local, 
 * not in the 'libraries' directory of user's sketchbook.  This
 * makes sketches self-contained, and you don't suffer version drift
 * when libraries get updated.  The downside is you have multiple copies
 * of the same library.
 *
 */

#include "./PinChangeInt.h"       // library for pin change interrupt
#include "./PinChangeIntConfig.h"

#include "./SoftTone.h"           // include for hacky sount library
#include "./FreqOutT2.h"          // pseudo-lib for 38kHz PWM output

#include "./EventFuse.h"

#include <Servo.h>                // system library, only uses Timer1
#include "./ServoEaser.h"

// set debug=0 to turn off Serial status msgs
// set debug=1 to turn on most Serial status msgs
// set debug=2 to turn on many Serial status msgs
const byte debug = 1;

// Pins that are used on the shield

const int ledStatusPin  = 13;
const int beepPin       = 12;

const int irEnableB1Pin = 11; 
const int irEnableB0Pin = 10; 
const int irEnableA1Pin = 9; 
const int irEnableA0Pin = 8; 

const int servo3Pin     = 7; // unused
const int servo2Pin     = 6; // blinkm on/off
const int servo1Pin     = 5; // spinny bit (if present)
const int servo0Pin     = 4; // bell ringer

const int irOutPin      = 3; // must be pin 3 (Timer out)

const int irDetectA0Pin = A0;
const int irDetectA1Pin = A1;
const int irDetectB0Pin = A2;
const int irDetectB1Pin = A3;

const int sdaPin        = A4;
const int sclPin        = A5;

// defines for BeamBreaker
const long IRFREQ_56K  = 56e3;
const long IRFREQ_38K  = 38e3;
const long IRFREQ_HZ   = IRFREQ_38K;
const int  IRFREQ_DUTY = 33;  // percent

// needs pin definitions above, which is why it's being included here
#include "./BeamBreaker.h"        // pseudo library for watching beambreaks


// the pins we use 
const int bellringerPin = servo0Pin;
const int spinnybitPin  = servo1Pin;
const int blinkmPin     = servo2Pin;

Servo bellringer;
Servo spinnybit;
ServoEaser spinnybitEaser;

int servoFrameMillis = 20;  // minimum time between servo updates
int spinnybitMovesCount = 7;
ServoMove spinnybitMoves[] = {
// angle, duration
  { 85,  1000},
  { 95,  1000},
  { 80,  1000},
  { 100, 1000},
  { 70,  1000},
  { 110, 1000},
  {  90, 1000},
};

//
void setup()
{
  pinMode( ledStatusPin, OUTPUT);
  pinMode( beepPin,      OUTPUT);
  pinMode( servo1Pin,    OUTPUT);
  pinMode( blinkmPin,    OUTPUT);

  digitalWrite( blinkmPin, LOW);

  bellringer.attach( bellringerPin );
  spinnybit.attach( spinnybitPin, 800,2200 );
  spinnybitEaser.begin( spinnybit, servoFrameMillis, 90);

  bellringer.write( 90 );

  BeamBreaker_begin( beamBreak, beamABreak, beamBBreak ); 

  Serial.begin(19200);
  Serial.println( "BillDetectorV2" );

  FreqOutT2_setFreq( IRFREQ_HZ, IRFREQ_DUTY );
  FreqOutT2_on();  // and _off() to turn off

  fanfare();
  
  BeamBreaker_enableAllIR();

  Serial.println( "Ready.");
}

unsigned long lastMillis;

//
void loop()
{
  BeamBreaker_check();

  spinnybitEaser.update();

  delay(1); // this makes event fuse time step mean "1 msec", FIXME
  eventFuse.burn(1);
}

//--------------------------------------------------------
// "doThings" begin
//--------------------------------------------------------

//int duration = 12000; // total duration of doing things, in millis; 
int duration = 12000; // total duration of doing things, in millis; 
int sliceDur =  50;  // duration of timeslice within doing things
int sliceCount;      // counter of slices, goes from 0 to sliceCountMax
int doingThingsMillis; // counter in millis from 0 to duration
int sliceCountMax = duration/sliceDur; 
boolean doingThings = false;  // used by event system to track 
//boolean doThingsReset = true;
boolean doThingsReset = false;


// called at beginning of doing things
void doThingsStart()
{
  if( debug ) Serial.println("doThingsStart");

  // deal with bell ringer
  bellringer.attach( bellringerPin );
  bellringer.write( 180 );

  // deal with spinny bit
  // start playing a moves list on a particular servo
  //spinnybitEaser.play( spinnybitMoves,spinnybitMovesCount );
  if( 1 ) { 
    spinnybitEaser.easeTo( 80,3000);
  } else {
    spinnybitEaser.easeTo( 80,6000);
  }
  // this doesn't work, something wrong with 'movesRep' code
  //spinnybitEaser.play( spinnybitMoves,spinnybitMovesCount, 1 );

  // deal with blinkm
  digitalWrite( blinkmPin, HIGH );
}

// called at end of doing things
void doThingsEnd()
{
  if( debug ) Serial.println("doThingsEnd");

  // deal with bell ringer
  bellringer.write( 90 );
  bellringer.detach();

  // deal with spinny bits
  //spinnybitEaser.stop();
  spinnybitEaser.easeTo(90,2000);  // FIXME: hack because play w/count fails

  // deal with blinkm
  digitalWrite( blinkmPin, LOW );
}

// called every sliceDur duration for sliceCountMax times
void doThingsTick() 
{
  if( debug > 1 ) {
    Serial.print("doThingsTick: ");
    Serial.print( sliceCount );
    Serial.print(" msec: ");
    Serial.println( doingThingsMillis );
  }
  
  // deal with bell ringer
  if( sliceCount == 1 ) 
    bellringer.write( 90 );

  // deal with blinkm 
  if( doingThingsMillis > 3000 ) {
    digitalWrite( blinkmPin, LOW);
  }

  // deal with spinnybit
  if( 1 ) { 
    if( doingThingsMillis > 4000 && doingThingsMillis < 4100 ) {
      Serial.println(">2000");
      spinnybitEaser.easeTo( 105, 3000);
    }
    else if( doingThingsMillis > 7000 && doingThingsMillis < 7100 ) { 
      Serial.println(">5000");
      spinnybitEaser.easeTo( 85, 3000 );
    }
  }
  else {
    if( doingThingsMillis > 6000 && doingThingsMillis < 6100 ) {
      Serial.println(">6000");
      spinnybitEaser.easeTo( 105, 6000);
    }
    else if( doingThingsMillis > 15000 && doingThingsMillis < 15100 ) { 
      Serial.println(">15000");
      spinnybitEaser.easeTo( 85, 15000 );
    }
  }    

  //spinnybit.write( 84+ (2*(sliceCountMax-sliceCount)/3));
  
}

//--------------------------------------------------------
// "doThings" end
//--------------------------------------------------------

// called periodically by eventfuse system
void thingsFuse(FuseID fuse, int userData)
{
  doingThingsMillis = sliceCount * sliceDur;
  doThingsTick();
  sliceCount++;
  if( sliceCount == sliceCountMax ) { 
    doThingsEnd();
  }
}

// called by BeamBreaker when any beam break occurs
void beamBreak()
{
  if( debug ) Serial.println("BREAK!");
  if( doingThings && doThingsReset ) {
    doThingsEnd();
  }
  doingThings = true;
  sliceCount = 0;

  doThingsStart();

  eventFuse.resetFuse( 0, sliceCountMax, sliceDur, sliceCountMax, thingsFuse);
}

// for testing, not for normal use
void beamABreak()
{
  digitalWrite( ledStatusPin, HIGH);
  playTone( beepPin, NOTE_C, 20 );
  digitalWrite( ledStatusPin, LOW);
}

// for testing, not for normal use
void beamBBreak()
{
  digitalWrite( ledStatusPin, HIGH);
  playTone( beepPin, NOTE_C1, 20 );
  digitalWrite( ledStatusPin, LOW);
}

// just a silly thing to let you know it's online
void fanfare()
{
  //digitalWrite( blinkmPin, HIGH );
  if( IRFREQ_HZ == IRFREQ_56K ) 
    playTone( beepPin, NOTE_C1, 50 );
  else 
    playTone( beepPin, NOTE_C, 50 );

  for( int i=0; i< 2; i++ ) { 
    digitalWrite( irEnableA0Pin, LOW );
    delay(50);
    digitalWrite( irEnableA0Pin, HIGH );
    delay(50);
    digitalWrite( irEnableB0Pin, LOW );
    delay(50);
    digitalWrite( irEnableB0Pin, HIGH );
    delay(50);
    digitalWrite( irEnableA1Pin, LOW );
    delay(50);
    digitalWrite( irEnableA1Pin, HIGH );
    delay(50);
    digitalWrite( irEnableB1Pin, LOW );
    delay(50);
    digitalWrite( irEnableB1Pin, HIGH );
    delay(50);
  }
  playTone( beepPin, NOTE_G,  50 );

  //digitalWrite( blinkmPin, LOW );
}


