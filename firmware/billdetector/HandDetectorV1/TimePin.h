//
// TimePin.h --
//
//
// 2011, Tod E. Kurt, http://todbot.com/blog/
//

#include <pins_arduino.h>

//
unsigned long timePin(int pin, int hilo)
{
  uint8_t bit = digitalPinToBitMask(pin);
  uint8_t port = digitalPinToPort(pin);
  uint8_t stateMask = (hilo ? bit : 0);

  unsigned long c = 0;
  if( (*portInputRegister(port) & bit) == stateMask ) {
    while ((*portInputRegister(port) & bit) == stateMask) {
      c++;
    }
    return clockCyclesToMicroseconds(c * 21 + 16);
  }
  return 0;
}
