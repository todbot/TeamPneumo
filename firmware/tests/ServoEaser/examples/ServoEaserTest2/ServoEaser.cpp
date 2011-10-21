//
// ServoEaser.cpp -- Arduino library for Servo easing
//
// Uses concepts from:
// -- http://portfolio.tobiastoft.dk/331886/Easing-library-for-Arduino
// -- http://jesusgollonet.com/processing/pennerEasing/
// -- http://robertpenner.com/easing/
// -- http://robertpenner.com/easing/easing_demo.html
//
// 2011, TeamPneumo, Tod E. Kurt, http://todbot.com/blog/
// 
//

#include "ServoEaser.h"

// default easing function
// this is from Easing::easeInOutCubic()
// t: current time, b: beginning value, c: change in value, d: duration
// t and d can be in frames or seconds/milliseconds
float easeInOutCubic(float t, float b, float c, float d)
{
    if ((t/=d/2) < 1) return c/2*t*t*t + b;
	return c/2*((t-=2)*t*t + 2) + b;
}


void ServoEaser::begin(Servo s, int frameTime, 
                       ServoMove* mlist, int mcount)
{
    servo = s;
    frameMillis = frameTime;
    moves = mlist;
    movesCount = mcount;

    easingFunc = easeInOutCubic;

    reset();
}

void ServoEaser::begin(Servo s, int frameTime, int pos )
{
    servo = s;
    frameMillis = frameTime;
    startPos = pos;

    easingFunc = easeInOutCubic;

    reset();
}

// warning only applicable when doing a moves list
void ServoEaser::reset()
{
    movesIndex = 0;

    if( movesCount > 0 ) {
        startPos  = moves[ movesIndex ].pos;  // get first position
        durMillis = moves[ movesIndex ].dur;
    }
    currPos  = startPos;  // get everyone in sync
    changePos = 0; 

    tickCount = durMillis / frameMillis;
    tick = 0;
    
    running = true;
}

//
void ServoEaser::setEasingFunc( EasingFunc func )
{
    easingFunc = func;
}

//
void ServoEaser::setMovesList( ServoMove* mlist, int mcount )
{
    moves = mlist;
    movesCount = mcount;
    reset();
}

//
void ServoEaser::getNextPos()
{
    movesIndex++;
    if( movesIndex == movesCount ) {
        movesIndex = 0;
    }
    startPos  = currPos; // current position becomes new start position

    changePos = moves[ movesIndex ].pos - startPos ;
    durMillis = moves[ movesIndex ].dur;

    tickCount = durMillis / frameMillis;
    tick = 0;
}

//
void ServoEaser::easeTo( int pos, int dur )
{
    movesCount = 0;  // no longer doing moves list
    startPos = currPos;
    changePos = pos - startPos;
    durMillis = dur;
    tickCount = durMillis / frameMillis;
    tick = 0;
}

//  FIXME: assumes running from a moves list
void ServoEaser::update()
{
    if( (millis() - lastMillis) < frameMillis ) {  // time yet?
        return;
    }
    lastMillis = millis();

    if( running ) {

        currPos = easingFunc( tick, startPos, changePos, tickCount );

        tick++;
        if( tick == tickCount ) { // time for new position
            if( movesCount!=0 ) {
                getNextPos();
            } // or maybe we're just done
            else { 
                tick--; // FIXME: hack easingFunc goes nuts
            }
        }
    } // if(!running) still hold servo position
    servo.write( currPos );
}

//
void ServoEaser::start()
{
    running = true;
}
//
void ServoEaser::stop()
{
    running = false;
}


 

