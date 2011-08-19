
/*
 * CarlynCashMachineTest -- Some test code for Carlyn to play with
 *
 *
 * 2011, Tod E. Kurt, http://todbot.com/blog/
 *
 */


#include "./TimedAction.h"


const int ledPin   = 13;
const int buttonPin = 8;


TimedAction buttonAction = TimedAction(100, readButtonAction);
TimedAction printAction = TimedAction(1000, updatePrintAction);


int pressCount;  // count the number of times the button was pressed

//
void setup()
{
  pinMode( ledPin, OUTPUT);

  pinMode( buttonPin, INPUT);
  digitalWrite( buttonPin, HIGH); // turn on pullup

  Serial.begin(19200);
  Serial.println("CarlynCashMachineTest ready");
}

// main loop
void loop() 
{
  printAction.check();
  buttonAction.check();
}


// do simple debounce by only reading button every 100 milliseconds
void readButtonAction()
{
  if( digitalRead(buttonPin) == LOW ) { // button pressed
    pressCount++;
  }
}

// every second, print out state of the universe
void updatePrintAction() 
{
  Serial.print("Number of button presses since last time: ");
  Serial.println( pressCount );
  pressCount = 0;
}



