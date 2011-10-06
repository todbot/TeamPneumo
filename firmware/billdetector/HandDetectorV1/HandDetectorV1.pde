/**
 *
 * HandDetectorV1 -- Bill detector, bell ringer, & spinnybit twirler for
 *                   Cash Machine
 *     - for use with the 'billdetector1e' Arduino shield
 *
 * 2011, TeamPneumo, Tod E. Kurt, http://todbot.com/blog/
 *                   Carlyn Maw, http://carlynorama.com/
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
#include "./TimePin.h"            // pseudo-lib of for pin timing

#include "./EventFuse.h"
#include "./SoftwareServo.h"

const int suckDurationMillis = 7000;
const int suckButtonHoldMillis = 1000;

// Pins that are used on the shield

const int ledStatusPin  = 13;
const int beepPin       = 12;

const int irEnableB1Pin = 11; 
const int irEnableB0Pin = 10; 
const int irEnableA1Pin = 9; 
const int irEnableA0Pin = 8; 

//const int servo3Pin     = 7; // unused
//const int servo2Pin     = 6; // blinkm on/off
//const int servo1Pin     = 5; // spinny bit (if present)
//const int servo0Pin     = 4; // bell ringer

const int ringlightPin  = 6;
// from carlyn's remotecontrol
const int offButtonPin = 5;
const int onButtonPin  = 4;

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




//
void setup()
{
  pinMode( ledStatusPin,  OUTPUT);
  pinMode( beepPin,       OUTPUT);
  pinMode( ringlightPin,  OUTPUT);
  pinMode( offButtonPin, OUTPUT);
  pinMode( onButtonPin,  OUTPUT);

  BeamBreaker_begin( beamBreak, beamABreak, beamBBreak ); 

  Serial.begin(19200);
  Serial.println( "HandDetectorV1" );

  FreqOutT2_setFreq( IRFREQ_HZ, IRFREQ_DUTY );
  FreqOutT2_on();  // and _off() to turn off

  fanfare();

  Serial.println( "Ready.");
}

//
void loop()
{
  BeamBreaker_check();

  checkButton();

  eventFuse.burn(1);
  delay(1); // this makes event fuse time step mean "1 msec", FIXME
}

void checkButton()
{
    //if( digitalRead( pushButton ) == LOW ) {
    //    beamBreak(); // FIXME: hack
    //}
}

//int duration = 5000; // total duration of doing things, in millis; 
int duration = suckDurationMillis + (2*suckButtonHoldMillis);
int sliceDur =  50;  // duration of timeslice within doing things
int sliceCount;      // counter of slices, goes from 0 to sliceCountMax
int doingThingsMillis; // counter in millis from 0 to duration
int sliceCountMax = duration/sliceDur; 
boolean doingThings = false;  // used by event system to track 
boolean doThingsReset = true;
//boolean doThingsReset = false;

// called at beginning of doing things
void doThingsStart()
{
  Serial.println("doThingsStart");
  digitalWrite( ringlightPin, HIGH);
}

// called at end of doing things
void doThingsEnd()
{
  Serial.println("doThingsEnd");
  digitalWrite( onButtonPin, LOW);
  digitalWrite( offButtonPin, LOW);
  digitalWrite( ringlightPin, LOW);
}

// called every sliceDur duration for sliceCountMax times
void doThingsTick() 
{
  Serial.print("doThingsTick: ");
  Serial.print( sliceCount );
  Serial.print(" msec: ");
  Serial.println( doingThingsMillis );
  
  // deal with suck on/off trigger
  if( doingThingsMillis < suckButtonHoldMillis ) { 
    digitalWrite( onButtonPin, HIGH); // begin turn-on button press
  }
  else if( doingThingsMillis > suckButtonHoldMillis &&
           doingThingsMillis < suckDurationMillis ) {
    digitalWrite( onButtonPin, LOW);  // end turn-on button press
  }
  else if( doingThingsMillis > suckDurationMillis ) { 
    digitalWrite( offButtonPin, HIGH); // begin turn-off button press
  }
  else if( doingThingsMillis > suckDurationMillis + suckButtonHoldMillis ) {
    digitalWrite( offButtonPin, LOW);  // end turn-off buutton press
  }

  // deal with ringlight
  //int lightval = (sliceCount % 3)==0;
  //digitalWrite( ringlightPin, blinkval );
  int lightval = 255-(sliceCount*15);
  analogWrite( ringlightPin, lightval);

}



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
  Serial.println("BREAK!");
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

