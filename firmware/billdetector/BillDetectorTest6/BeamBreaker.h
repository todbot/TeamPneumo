/**
 *
 * BeamBreaker -- manage the IR LEDs and watch the IR detectors
 *
 * 2011, Tod E. Kurt, http://todbot.com/blog/
 *
 *
 * Uses PinChangeInt library
 *
 *
 *
 * Some TSOP details from the datasheet "test signal":
 * * input signal: 30 pulses, f = fo, t = 10ms
 * * input signal: tpi >= 10/fo recommeneded
 * * (input signal starts at t=0, goes to t=tpi, is off until T
 * * (output signal starts high, goes low after td, says low for tpo, goes high
 * * output signal: 7/fo < td < 15/fo
 * * output signal: tpi - 5/fo < tpo < tpi + 6/fo
 *
 * * at 38kHz: 
 * **  7/fo =  7/38e3 = 0.184 msec
 * ** 10/fo = 10/38e3 = 0.263 msec  <-- minimum ON pulse
 * ** 15/fo = 15/38e3 = 0.395 msec
 * 
 * Lower down on 2nd "optical test signal" graph:
 * * 0.600 msec ON, then 0.600 msec OFF  
 *
 */



volatile unsigned long detectAMillis;
volatile unsigned long detectBMillis;

volatile unsigned int cnt;
volatile unsigned char type;  // super hack, heck all of these vars are

// internal func for pinchange int, must be fast!
// first sensor ring
void BeamBreaker_detectA0()
{
  detectAMillis = millis();
  type = '0';
  cnt++;
}
// internal func for pinchange int, must be fast!
// first sensor ring
void BeamBreaker_detectA1()
{
  detectAMillis = millis();
  type = '1';
  cnt++;
}
// internal func for pinchange int, must be fast!
// second sensor ring
void BeamBreaker_detectB0()
{
  detectBMillis = millis();
  type = '0';
  cnt++;
}
// internal func for pinchange int, must be fast!
// second sensor ring
void BeamBreaker_detectB1()
{
  detectBMillis = millis();
  type = '1';
  cnt++;
}

// put this in setup()
void BeamBreaker_begin()
{
  pinMode( irOutPin,     OUTPUT);
  pinMode( irEnableA0Pin,OUTPUT);
  pinMode( irEnableA1Pin,OUTPUT);
  pinMode( irEnableB0Pin,OUTPUT);
  pinMode( irEnableB1Pin,OUTPUT);

  digitalWrite( irEnableA0Pin, LOW ); // turn off LEDA0
  digitalWrite( irEnableA1Pin, LOW ); // turn off LEDA1
  digitalWrite( irEnableB0Pin, LOW ); // turn off LEDB0
  digitalWrite( irEnableB1Pin, LOW ); // turn off LEDB1

  pinMode( irDetectA0Pin,  INPUT);
  pinMode( irDetectA1Pin,  INPUT); 
  pinMode( irDetectB0Pin,  INPUT);
  pinMode( irDetectB1Pin,  INPUT);
  digitalWrite(irDetectA0Pin, HIGH); // internal pullup
  digitalWrite(irDetectA1Pin, HIGH); // internal pullup
  digitalWrite(irDetectB0Pin, HIGH); // internal pullup
  digitalWrite(irDetectB1Pin, HIGH); // internal pullup

  const int changeType = FALLING;  // can be RISING, CHANGE or FALLING

  PCintPort::attachInterrupt(irDetectA0Pin, BeamBreaker_detectA0, changeType); 
  PCintPort::attachInterrupt(irDetectA1Pin, BeamBreaker_detectA1, changeType); 
  PCintPort::attachInterrupt(irDetectB0Pin, BeamBreaker_detectB0, changeType); 
  PCintPort::attachInterrupt(irDetectB1Pin, BeamBreaker_detectB1, changeType); 

}


// call this regularly in loop()
// FIXME: this sucks
void BeamBreaker_check()
{
  if( detectAMillis ) { 
    digitalWrite( ledStatusPin, HIGH);

    Serial.print("detectAMillis: "); 
    Serial.print(type); Serial.print(':');
    Serial.println(detectAMillis);

    playTone( tonePin, NOTE_C, 20 );
    digitalWrite( ledStatusPin, LOW);
    detectAMillis = 0;
    type = '.';
  }
  if( detectBMillis ) { 
    digitalWrite( ledStatusPin, HIGH);

    Serial.print("detectBMillis: ");
    Serial.print(type); Serial.print(':');
    Serial.println(detectBMillis);

    playTone( tonePin, NOTE_C1, 20 );
    digitalWrite( ledStatusPin, LOW);
    detectBMillis = 0;
    type = '.';
  }
      
  /*
  if( detectBMillis ) {
    int diff = abs(detectBMillis - detectAMillis);
    if( detectAMillis == 0 ) {
      Serial.println("***oops, no detectA");
    }
    digitalWrite( irEnableA0Pin, LOW );  // turn off LEDA
    digitalWrite( irEnableB0Pin, LOW );  // turn off LEDB

    Serial.print("detectBMillis: "); Serial.println(detectBMillis);
    Serial.print("diff: "); Serial.println( diff );

    detectAMillis = 0;
    detectBMillis = 0;

    digitalWrite( ledStatusPin, LOW);
    playTone( tonePin, NOTE_C1, 50 );

    digitalWrite( irEnableA0Pin, HIGH );  // turn on LEDA
    digitalWrite( irEnableB0Pin, HIGH );  // turn on LEDB
  }
  */
}

