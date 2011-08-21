/**
 *
 * BillDetectorTest7 -- testing out the 'billdetector1b' board
 *
 * 2011, Tod E. Kurt, http://todbot.com/blog/
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


//#include <Scheduler.h>  
//Scheduler scheduler = Scheduler();  // create a scheduler

#include <EventFuse.h> // Include the EventFuse library


// Pins that are used

const int ledStatusPin  = 13;
const int beepPin       = 12;

const int irEnableB1Pin = 11; 
const int irEnableB0Pin = 10; 
const int irEnableA1Pin = 9; 
const int irEnableA0Pin = 8; 

const int servo3Pin     = 7;
const int servo2Pin     = 6;
const int servo1Pin     = 5;
const int servo0Pin     = 4;

const int irOutPin      = 3; // must be pin 3 (Timer out)

const int irDetectA0Pin = A0;
const int irDetectA1Pin = A1;
const int irDetectB0Pin = A2;
const int irDetectB1Pin = A3;

const int sdaPin        = A4;
const int sclPin        = A5;


//const long IRFREQ_HZ   = 56e3;
const long IRFREQ_HZ   = 38e3;
const int  IRFREQ_DUTY = 23;  // percent

// needs pin definitions above, which is why it's being included here
#include "./BeamBreaker.h"        // pseudo library for watching beambreaks


//
void setup()
{
  pinMode( ledStatusPin, OUTPUT);
  pinMode( beepPin,      OUTPUT);

  BeamBreaker_begin( beamBreak, beamABreak, beamBBreak ); 

  Serial.begin(19200);
  Serial.println( "BillDetectorTest7" );

  FreqOutT2_setFreq( IRFREQ_HZ, IRFREQ_DUTY );
  FreqOutT2_on();  // and _off() to turn off

  fanfare();

  Serial.println( "Ready.");
}

void loop()
{
  BeamBreaker_check();

  //scheduler.update(); // update scheduler, maybe time to execute a function?
  eventFuse.burn(1);
  delay(1);
}

//
//void FuseEvent(FuseID fuse, int userData)
//void doThings()
void doThings( FuseID fuse, int userData) 
{
    Serial.print("doThings!");
    Serial.println( userData );
    playTone( beepPin, NOTE_C, 20 );
    userData--;
}

void beamBreak()
{
  Serial.println("BREAK!");
  byte thingscount = 10;
  // newFuse(           userdata, fuseLen, repeatCount, callback );
  // resetFuse( fuseid, userdata, fuseLen, repeatCount, callback );
  //eventFuse.newFuse(       100, thingscount, doThings );
  eventFuse.resetFuse( 0, thingscount, 100,  thingscount, doThings );
  //doThings();
}

// for testing, not for normal use
void beamABreak()
{
  digitalWrite( ledStatusPin, HIGH);
  
  //Serial.print("detectAMillis: "); 
  //Serial.print(type); Serial.print(':');
  //Serial.println(detectAMillis);
  
  playTone( beepPin, NOTE_C, 20 );

  digitalWrite( ledStatusPin, LOW);

}

// for testing, not for normal use
void beamBBreak()
{
  digitalWrite( ledStatusPin, HIGH);
  
  //Serial.print("detectBMillis: ");
  //Serial.print(type); Serial.print(':');
  //Serial.println(detectBMillis);
  
  playTone( beepPin, NOTE_C1, 20 );

  digitalWrite( ledStatusPin, LOW);

}

// just a silly thing to let you know it's online
void fanfare()
{
   for( int i=0; i< 5; i++ ) { 
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
  playTone( beepPin, NOTE_C1, 50 );
  playTone( beepPin, NOTE_G,  50 );
}


