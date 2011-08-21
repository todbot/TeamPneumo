
#include "WProgram.h"

// TONES  ==========================================
// Start by defining the relationship between
//       note, period, &  frequency.
#define  NOTE_C     3830    // 261 Hz
#define  NOTE_D     3400    // 294 Hz
#define  NOTE_E     3038    // 329 Hz
#define  NOTE_F     2864    // 349 Hz
#define  NOTE_G     2550    // 392 Hz
#define  NOTE_A     2272    // 440 Hz
#define  NOTE_B     2028    // 493 Hz
#define  NOTE_C1    1912    // 523 Hz
// Define a special note, 'R', to represent a rest
#define  R     0


//
void playTone(int pin, int tone_, long duration) {
  long elapsed_time = 0;
  int rest_count = 100; //<-BLETCHEROUS HACK; See NOTES
  duration = duration * 1000;

  if (tone_ > 0) { // if this isn't a Rest beat, while the tone has
    //  played less long than 'duration', pulse speaker HIGH and LOW
    while (elapsed_time < duration) {

      digitalWrite(pin, HIGH);
      delayMicroseconds(tone_ / 2);

      digitalWrite(pin, LOW);
      delayMicroseconds(tone_ / 2);

      // Keep track of how long we pulsed
      elapsed_time += (tone_);
    }
  }
  else { // Rest beat; loop times delay
    for (int j = 0; j < rest_count; j++) { // See NOTE on rest_count
      delayMicroseconds(duration);  
    }                                
  }                                
}
