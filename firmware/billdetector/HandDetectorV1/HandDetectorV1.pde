/**
 *
 * HandDetectorV1b -- Bill detector, bell ringer, & spinnybit twirler for
 *                   Cash Machine
 *     - for use with the 'billdetector1e' Arduino shield
 *     - and the modded "Long Ranger" transmitter shield
 *
 * 2011, TeamPneumo, Tod E. Kurt, http://todbot.com/blog/
 *                   Carlyn Maw, http://carlynorama.com/
 *
 *
 *
 * On/Off button functionality
 * - ON pressed at least one times
 * - OFF pressed 3 times
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

// set debug=0 to turn off Serial status msgs
// set debug=1 to turn on most Serial status msgs
// set debug=2 to turn on many Serial status msgs
const int debug = 1;

const long suckDurationMillis = 12000;  // time
const long suckOnButtMillis   = 1000;
const long suckOffButtMillis  = 1000;


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


// for the "doingThings" functionality
// total duration of doing things, in millis; 
unsigned long duration = suckDurationMillis+(4*suckOnButtMillis)+(6*suckOffButtMillis);
int sliceDur =  50;  // duration of timeslice within doing things
int sliceCount;      // counter of slices, goes from 0 to sliceCountMax
int doingThingsMillis; // counter in millis from 0 to duration
int sliceCountMax = duration/sliceDur; 
boolean doingThings = false;  // used by event system to track 
//boolean doThingsReset = true;
boolean doThingsReset = false;

enum SuckButton {
  suckPushNone,
  suckPushOn,
  suckPushOff
};

//
void pushRemoteButton( int suckButton )
{
  if( suckButton == suckPushOn ) {
    Serial.println("ON ");
    digitalWrite( offButtonPin, LOW );
    delay(10);
    digitalWrite( onButtonPin, HIGH );
    delay(10);
  } 
  else if( suckButton == suckPushOff ) {
    Serial.println("OFF");
    digitalWrite( onButtonPin, LOW );
    delay(10);
    digitalWrite( offButtonPin, HIGH );
    delay(10);
  }
  else { // suckPushNone
    Serial.println("---");
    digitalWrite( onButtonPin, LOW );
    digitalWrite( offButtonPin, LOW );
    delay(10);
  }
}


//
void setup()
{
  pinMode( ledStatusPin, OUTPUT);
  pinMode( beepPin,      OUTPUT);
  pinMode( ringlightPin, OUTPUT);
  pinMode( offButtonPin, OUTPUT);
  pinMode( onButtonPin,  OUTPUT);

  pushRemoteButton( suckPushNone );

  BeamBreaker_begin( beamBreak, beamABreak, beamBBreak ); 

  Serial.begin(19200);
  Serial.println( "HandDetectorV1b" );

  FreqOutT2_setFreq( IRFREQ_HZ, IRFREQ_DUTY );
  FreqOutT2_on();  // and _off() to turn off

  fanfare();

  BeamBreaker_enableAllIR();

  Serial.println( "Ready.");
}

//
void loop()
{
  BeamBreaker_check();

  checkTestButton();

  eventFuse.burn(1);
  delay(1); // this makes event fuse time step mean "1 msec", FIXME
}

//
void checkTestButton()
{
  if( !debug ) return;
  //if( digitalRead( pushButton ) == LOW ) {
  //  beamBreak(); // FIXME: hack
  //}
  if( (millis() > 3000 && millis() < 3002)  || 
      (millis() > 5000 && millis() < 5002) ) {
    beamBreak();
  }
}

  
//--------------------------------------------------------
// "doThings" begin
//--------------------------------------------------------

// called at beginning of doing things
void doThingsStart()
{
  if( debug ) Serial.println("doThingsStart");
  digitalWrite( ringlightPin, HIGH);
  //pushRemoteButton( suckPushNone );
}

// called at end of doing things
void doThingsEnd()
{
  if( debug ) Serial.println("doThingsEnd");
  pushRemoteButton( suckPushNone );
  digitalWrite( ringlightPin, LOW);
}

// called every sliceDur duration for sliceCountMax times
void doThingsTick() 
{
  if( debug > 1 ) {
    Serial.print("doThingsTick:");
    Serial.print( sliceCount );
    Serial.print(" msec:");
    Serial.println( doingThingsMillis );
  }
  
  // deal with ringlight
  int lightval = 255-(sliceCount*15);  // wub wub wub
  //int lightval = (255 - (sliceCount*15)) * (sliceCountMax * sliceCount/sliceCountMax);
  analogWrite( ringlightPin, lightval);

  // deal with suck on/off trigger
  // FIXME: this huge if-then tree is a hack
  // basically we want: 
  // - ON button toggled two times,
  // - OFF button toggled 3 times
  // - duration between on and off button configurable
  // - would be nice if retriggers did The Right Thing
  //

  // first ON button press
  if(      doingThingsMillis >= (0*suckOnButtMillis) && 
           doingThingsMillis <  (1*suckOnButtMillis) ) {
    pushRemoteButton( suckPushOn ); // begin turn-on button press
  }
  else if( doingThingsMillis >= (1*suckOnButtMillis) &&
           doingThingsMillis <  (2*suckOnButtMillis) ) {
    pushRemoteButton( suckPushNone ); // end turn-on button press
  }
  // second ON button press
  else if( doingThingsMillis >= (2*suckOnButtMillis) &&
           doingThingsMillis <  (3*suckOnButtMillis) ) {
    pushRemoteButton( suckPushOn ); // begin turn-on button press
  }
  else if( doingThingsMillis >= (3*suckOnButtMillis) &&
           doingThingsMillis <  (4*suckOnButtMillis) ) {
    pushRemoteButton( suckPushNone ); // end turn-on button press
  }
  
  // suck time up
  else if( doingThingsMillis > suckDurationMillis ) { 

    digitalWrite( ringlightPin, LOW);
    unsigned long suckOffMillis = 
      doingThingsMillis - (suckDurationMillis+(4*suckOnButtMillis));
    // first OFF button press
    if(      suckOffMillis >= (0*suckOffButtMillis) && 
             suckOffMillis <  (1*suckOffButtMillis) ) {
      pushRemoteButton( suckPushOff ); // begin turn-off button press
    }
    else if( suckOffMillis >= (1*suckOffButtMillis) && 
             suckOffMillis <  (2*suckOffButtMillis) ) {
      pushRemoteButton( suckPushNone ); // end turn-off button press
    }
    // second OFF button press
    else if( suckOffMillis >= (2*suckOffButtMillis) &&
             suckOffMillis <  (3*suckOffButtMillis) ) {
      pushRemoteButton( suckPushOff ); // begin turn-off button press
    }
    else if( suckOffMillis >= (3*suckOffButtMillis) &&
             suckOffMillis <  (4*suckOffButtMillis) ) {
      pushRemoteButton( suckPushNone ); // end turn-off button press
    }
    // third OFF button press
    else if( suckOffMillis >= (4*suckOffButtMillis) &&
             suckOffMillis <  (5*suckOffButtMillis) ) {
      pushRemoteButton( suckPushOff ); // begin turn-off button press
    }
    else if( suckOffMillis >= (5*suckOffButtMillis) &&
             suckOffMillis <  (6*suckOffButtMillis) ) {
      pushRemoteButton( suckPushNone ); // end turn-off button press
    }
  }

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


