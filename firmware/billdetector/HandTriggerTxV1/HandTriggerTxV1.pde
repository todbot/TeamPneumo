/**
 *
 * HandTriggerTxV1 -- Hand detector, and transmitter for Cash Machine
 *     - for use with the xbee shield
 *  
 * NOTE: Must compile with Arduino 0023
 *
 * 2011, TeamPneumo, Tod E. Kurt, http://todbot.com/blog/
 *                   Carlyn Maw, http://carlynorama.com/
 *
 *
 * TX XBee:
 * --------
 * ATID6666 = PAN ID
 * ATMY1    = my address 1
 * ATDL2    = destination address 2
 * ATD23    = DIO2 is input (pin 18)
 * ATIR14   = input sample rate 20 milliseconds (hex 14)
 * ATIT5    = samples before transmit 5
 * ATRR6    = set retry rate to 6 (most rugged)
 * ATSM1    = pin hibernate (pin 4 is hibernate pin)
 *
 * RX Xbee:
 * --------
 * ATID6666 = PAN ID
 * ATMY2    = my address 1
 * ATDL1    = destination address 1
 * ATD25    = DIO2 is output
 * ATIU1    = I/O output enabled
 * ATIA1    = I/O input from address 1
 *
 * TX Xbee: ATID6666,MY1,DL2,D23,IR14,IT5,WR,CN
 * RX Xbee: ATID6666,MY2,DL1,D25,IU1,IA1,WR,CN
 * 
 * TX XBee: (handheld)
 * -------------------
 * same as TX XBee, but also:
 * ATSM0    = disable pin hibernate
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


// set debug=0 to turn off Serial status msgs
// set debug=1 to turn on most Serial status msgs
// set debug=2 to turn on many Serial status msgs
const int debug = 1;

const long suckDurationMillis = 12000;  // time
const long suckOnButtMillis   = 700;
const long suckOffButtMillis  = 700;


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

const int xbeeSendPin   = 5;
const int xbeeSleepPin  = 4;

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
unsigned long duration = suckDurationMillis+1000;
//unsigned long duration = suckDurationMillis+(4*suckOnButtMillis)+(6*suckOffButtMillis);
int sliceDur =  50;  // duration of timeslice within doing things
int sliceCount;      // counter of slices, goes from 0 to sliceCountMax
int doingThingsMillis; // counter in millis from 0 to duration
int sliceCountMax = duration/sliceDur; 
int suckSliceCountMax = (suckDurationMillis)/sliceDur;
boolean doingThings = false;  // used by event system to track 
//boolean doThingsReset = true;
boolean doThingsReset = false;

//----------------------------------------------------------
void xbeeBegin()
{
  // Xbee connection
  pinMode( xbeeSendPin, OUTPUT); 
  pinMode( xbeeSleepPin, OUTPUT); 
}

void xbeeEnable()
{
    digitalWrite( xbeeSleepPin, LOW );  // turn off sleep
}
void xbeeDisable()
{
    digitalWrite( xbeeSleepPin, HIGH );  // turn on sleep
}

void xbeeSendOn(int ms)
{
    xbeeEnable();
    digitalWrite( xbeeSendPin, HIGH );
    delay(ms);
    xbeeDisable();
}

void xbeeSendOff(int ms)
{
    xbeeEnable();
    digitalWrite( xbeeSendPin, LOW );
    delay(ms);
    xbeeDisable();
}
//-------------------------------------------------------------


//
void setup()
{
  pinMode( ledStatusPin, OUTPUT);
  pinMode( beepPin,      OUTPUT);
  pinMode( ringlightPin, OUTPUT);

  xbeeBegin();
  xbeeDisable();

    BeamBreaker_begin( beamBreak, beamABreak, beamBBreak ); 

  Serial.begin(57600);
  Serial.println( "HandTriggerTxV1" );

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

  if( (millis() > 3000 && millis() < 3002) 
      //|| (millis() > 5000 && millis() < 5002)
      ) {
    Serial.println("checkTestButton");
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
  xbeeSendOn(100);
  
}

// called at end of doing things
void doThingsEnd()
{
  if( debug ) Serial.println("doThingsEnd");
  xbeeSendOff(100);
  digitalWrite( ringlightPin, LOW);
}

// pusling light stuff
void lightWub()
{
  int wrapval = 16 - (sliceCount*8/suckSliceCountMax);
  byte lightval = 255-(sliceCount*wrapval);  // wub wub wub
  lightval = 0.5 * (float)lightval *  (1.0-(float)sliceCount/suckSliceCountMax);


  if( doingThingsMillis < suckDurationMillis ) {
    if( debug ) {
      Serial.print("lightval:");
      Serial.println(lightval,DEC);
    }
    analogWrite( ringlightPin, lightval);
  } else { 
    // turn off ringlight
    digitalWrite( ringlightPin, LOW);
  }

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

  // deal with the pulsing light
  lightWub();

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


