
#ifndef ServoEaser_h
#define ServoEaser_h

#include <Servo.h>

typedef struct _servoMove {
  int pos;     // position of servo in degrees
  int dur;     // duration in milliseconds to get to and stay at that position
} ServoMove;

// define type "EasingFunc"
//
// t: current time, b: beginning value, c: change in value, d: duration
// t and d can be in frames or seconds/milliseconds
//
typedef float (*EasingFunc)(float t, float b, float c, float d); 


class ServoEaser 
{
private:
    Servo servo;
    int frameMillis;
    int startPos;
    int currPos;   // current servo position, best of our knowledge
    int changePos; // from servoMove list
    int durMillis; // from servoMove list
    int tick;      // count of easing moves within move duration 
    int tickCount;  // number of frames between start & end pos
    unsigned long lastMillis;
    int movesIndex;
    int movesCount;
    ServoMove* moves; // list of user-supplied servo moves
    EasingFunc easingFunc;

    void getNewPos();
    //float easingFunc(float t, float b, float c, float d);

public:
    
    void begin(Servo s,int frameTime,ServoMove* moves,int movesCount);
    void update();
    void setEasingFunc( EasingFunc );

};



#endif
