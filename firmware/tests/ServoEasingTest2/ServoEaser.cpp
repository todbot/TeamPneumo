//
// ServoEaser.cpp -- Arduino library for Servo easing
//
// Uses concepts from:
// -- http://portfolio.tobiastoft.dk/331886/Easing-library-for-Arduino
// -- http://jesusgollonet.com/processing/pennerEasing/
// -- http://robertpenner.com/easing/
//
// 2011, TeamPneumo, Tod E. Kurt, http://todbot.com/blog/
// 
//

#include "ServoEaser.h"

#include "WProgram.h"

// this is from Easing::easeInOutCubic()
float easeInOutCubic(float t, float b, float c, float d)
{
    if ((t/=d/2) < 1) return c/2*t*t*t + b;
	return c/2*((t-=2)*t*t + 2) + b;
}

void ServoEaser::setEasingFunc( EasingFunc func )
{
    easingFunc = func;
}

// FIXME: assumes a moves list, need a begin() with no moves list
void ServoEaser::begin(Servo s, int frameTime, 
                       ServoMove* mlist, int mcount)
{
    servo = s;
    frameMillis = frameTime;
    moves = mlist;
    movesCount = mcount;

    movesIndex = 0;

    easingFunc = easeInOutCubic;

    startPos  = moves[ movesIndex ].pos;  // get first position
    durMillis = moves[ movesIndex ].dur;

    currPos  = startPos;  // get everyone in sync
    changePos = 0; 

    tickCount = durMillis / frameMillis;
    tick = 0;

    servo.write( startPos );  
}

//
void ServoEaser::getNewPos()
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
// t: current time, b: beginning value, c: change in value, d: duration
// t and d can be in frames or seconds/milliseconds
//
/*
float ServoEaser::easingFunc(float t, float b, float c, float d)
{
    // this is Easing::easeInOutCubic()
    if ((t/=d/2) < 1) return c/2*t*t*t + b;
	return c/2*((t-=2)*t*t + 2) + b;
}
*/

//  FIXME: assumes running from a moves list
void ServoEaser::update()
{
    if( millis() - lastMillis >= frameMillis ) { 
        lastMillis = millis();

        currPos = easingFunc( tick, 
                              startPos, 
                              changePos, 
                              tickCount );

        servo.write( currPos );

        tick++;
        if( tick == tickCount ) { // time for new position
            getNewPos();
        }
    }

}

 

