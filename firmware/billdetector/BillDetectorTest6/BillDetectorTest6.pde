/**
 *
 * BillDetectorTest6
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

// Pins that are used

const int ledStatusPin  = 13;
const int tonePin       = 12;

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


#include "./BeamBreaker.h"        // pseudo library for watching beambreaks


//
void setup()
{
  pinMode( ledStatusPin, OUTPUT);
  pinMode( tonePin,      OUTPUT);

  BeamBreaker_begin();

  Serial.begin(19200);
  Serial.println( "BillDetectorTest6" );

  FreqOutT2_setFreq( IRFREQ_HZ, IRFREQ_DUTY );
  FreqOutT2_on();  // and _off() to turn off

  fanfare();


  Serial.println( "Ready.");
}

void loop()
{

  BeamBreaker_check();

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
  playTone( tonePin, NOTE_C1, 50 );
  //playTone( tonePin, NOTE_C,  50 );
  playTone( tonePin, NOTE_G,  50 );
}


