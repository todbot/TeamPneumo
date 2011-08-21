//
// FreqOutT2 -- Output a frequency on pin 3 (or maybe 11) using Timer2
//
// Steals liberally from Ken Shirriff's IRRemote library
// see: http://arcfn.com
//
//
// 2011, Tod E. Kurt, http://todbot.com/blog/
//

//
void FreqOutT2_setFreq( long hz, int dutypercent )
{
  // (the below is from IRremote.cpp)
  // The khz value controls the modulation frequency in kilohertz.
  // The output will be on pin 3 (OC2B).
  // This routine is designed for 36-40KHz; if you use it for other values,
  //  it's up to you to make sure it gives reasonable results. 
  // (Watch out for overflow / underflow / rounding.)
  // TIMER2 is used in phase-correct PWM mode, 
  // with OCR2A controlling the frequency and OCR2B controlling the duty cycle.
  // There is no prescaling, so the output frequency is F_CPU / (2 * OCR2A)
  // To turn the output on and off, we leave the PWM running, 
  // but connect and disconnect the output pin.
  // A few hours staring at the ATmega documentation & this will all make sense.
  // See Ken's Secrets of Arduino PWM at 
  // http://arcfn.com/2009/07/secrets-of-arduino-pwm.html 

  // Disable the Timer2 Interrupt (which is used for receiving IR)
  TIMSK2 &= ~_BV(TOIE2); //Timer2 Overflow Interrupt
  
  pinMode(3, OUTPUT);
  digitalWrite(3, LOW); // When not sending PWM, we want it low
  
  // COM2A = 00: disconnect OC2A
  // COM2B = 00: disconnect OC2B; to send signal set to 10: OC2B non-inverted
  // WGM2 = 101: phase-correct PWM with OCRA as top
  // CS2 = 000: no prescaling
  TCCR2A = _BV(WGM20);
  TCCR2B = _BV(WGM22) | _BV(CS20);

  // The top value for the timer.  
  // The modulation frequency will be SYSCLOCK / 2 / OCR2A.
  //OCR2A = F_CPU / 2 / khz / 1000;
  //OCR2B = OCR2A / 3; // 33% duty cycle
  OCR2A = F_CPU / 2 / hz;
  //OCR2A = F_CPU / 2 / 38e3;
  OCR2B = (OCR2A * dutypercent) / 100;

}

// turn on frequency being output
void FreqOutT2_on()
{
  TCCR2A |=  _BV(COM2B1); // Enable pin 3 PWM output
}

// turn off frequency being output
void FreqOutT2_off()
{
  TCCR2A &=~ _BV(COM2B1); // Disable pin 3 PWM output
}
