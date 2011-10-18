

const int ledStatusPin  = 13;
const int offButtonPin  = 5;
const int onButtonPin   = 4;


enum SuckButton {
  suckPushNone,
  suckPushOn,
  suckPushOff
};


//
void setup()
{
  pinMode( ledStatusPin, OUTPUT);

  pinMode( offButtonPin, OUTPUT);
  pinMode( onButtonPin,  OUTPUT);

  pushRemoteButton( suckPushNone );

}

void loop() 
{
    pushRemoteButton( suckPushOn );
    delay(1000);
    pushRemoteButton( suckPushNone );
    delay(1000);
    pushRemoteButton( suckPushOff );
    delay(1000);
    pushRemoteButton( suckPushNone );
    delay(1000);
}


//
void pushRemoteButton( int suckButton )
{
  if( suckButton == suckPushOn ) {
    Serial.println("ON ");
    digitalWrite( offButtonPin, LOW );
    digitalWrite( onButtonPin, HIGH );
  } 
  else if( suckButton == suckPushOff ) {
    Serial.println("OFF");
    digitalWrite( onButtonPin, LOW );
    digitalWrite( offButtonPin, HIGH );
  }
  else { // suckPushNone
    Serial.println("---");
    digitalWrite( onButtonPin, LOW );
    digitalWrite( offButtonPin, LOW );
  }
}


