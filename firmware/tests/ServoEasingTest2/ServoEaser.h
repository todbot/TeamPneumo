//
// ServoEaser.h -- Arduino library for Servo easing
//
// Uses concepts from:
// -- http://portfolio.tobiastoft.dk/331886/Easing-library-for-Arduino
// -- http://jesusgollonet.com/processing/pennerEasing/
// -- http://robertpenner.com/easing/
//
// 2011, TeamPneumo, Tod E. Kurt, http://todbot.com/blog/
// 
//


#ifndef ServoEaser_h
#define ServoEaser_h

#include "WProgram.h"

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
    int frameMillis; // minimum update time between servo moves
    int startPos;    // where servo started its tween
    int currPos;     // current servo position, best of our knowledge

    int changePos;   // from servoMove list

    int durMillis;   // from servoMove list
    int tick;        // count of easing moves within move duration 
    int tickCount;   // number of frames between start & end pos
    unsigned long lastMillis; // time time we did something

    int movesIndex;  // where in the moves list we are
    int movesCount;  // number of moves in the moves list

    ServoMove* moves; // list of user-supplied servo moves

    EasingFunc easingFunc; // func that describes tween motion

    boolean running; // 

    void getNextPos();

public:
    
    void begin(Servo s, int frameTime, ServoMove* moves, int movesCount);
    void begin(Servo s, int frameTime, int startPos);

    void reset();
    void setMovesList( ServoMove* mlist, int mcount );

    void start();
    void stop();

    void easeTo( int pos, int durMillis );

    void update();

    // you can set your own easing function
    void setEasingFunc( EasingFunc );

};



#endif
