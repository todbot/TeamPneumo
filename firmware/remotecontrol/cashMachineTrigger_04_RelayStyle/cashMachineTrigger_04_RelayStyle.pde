
#include <Button.h> 
#include <FancyLED.h> 

unsigned long  loopCurrentTime = 0;

  //Instantiate Button on digital pin 2
  //pressed = ground (pulled high with _external_ resistor)
  Button helloButton = Button(6, LOW);
     
  //Instantiate FancySolenoid on digital pin 5
  //active = HIGH (could need to be low if inverting IC is being used...)  
  FancyLED onTrigger = FancyLED(4, HIGH);
  FancyLED offTrigger = FancyLED(5, HIGH);


void setup()
{
  Serial.begin(19200);
  onTrigger.setFullPeriod(1000);
  onTrigger.setDutyCycle(60);
  onTrigger.turnOff();
  
  offTrigger.setFullPeriod(1000);
  offTrigger.setDutyCycle(60);
  offTrigger.turnOff();
  
}

void loop()
{

  helloButton.listen();  
  onTrigger.update();
  offTrigger.update();
 
  
 if (helloButton.onPress()) {

    onTrigger.pulse(1);
    offTrigger.fusedPulse(7000,1);

  } 

}

