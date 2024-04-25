//--------------------------------
// title: Main
// desc:  Control Sonic Pinwheel
//
// authoer: terry feng
// date: February 2024
//--------------------------------

// Global Clock
global Event GLOBAL_TICK;
global Clock clock;

// Global Communication
1.0 => global float MIC_GAIN;
0.0 => global float PINWHEEL_VEL;
global Event BLADE_CROSSED;
global float MIC_ACTIVE;
global float MIC_DBFS;
global float MIC_MAG;

// Main UGens
MicTrack micTrack;
Pinwheel pinwheel;

// Variables
63 => int keyCenter;
[ 0,7 ] @=> int ostinato[];
0 => int ostinatoIndex;

// CONSTANTS
3 => int CYCLE_MIN;
16 => int CYCLE_MAX;

//-------
// Initialize System
//-------
// Set Ostinato Cycle
Math.random2(CYCLE_MIN,CYCLE_MAX) => int cycle;
// Init Pinwheel
pinwheel.setKeyCenter(keyCenter);
// if between .25 and .5 or between .75 and 1
// set to 1
if (clock._second >= 15 && clock._second < 30 ||
    clock._second >= 45 && clock._second < 60) {
    1 => ostinatoIndex;
    pinwheel.setKeyCenter(keyCenter + ostinato[ostinatoIndex]);
}

//-------
// JS COMMUNICATION/CONTROL
//-------
fun void control() 
{
    while (true)
    {
        // WRITE GLOBAL COMMUNICATION
        micTrack.active() => MIC_ACTIVE;
        micTrack.getDBFS() => MIC_DBFS;
        micTrack.getMag() => MIC_MAG;

        50::ms => now;
    }
}
spork ~ control();

//-------
// PINWHEEL CONTROL
//-------
fun void pinwheelCrossing() 
{
    while (true)
    {
        BLADE_CROSSED => now;
        spork ~ pinwheel.blow(PINWHEEL_VEL);
    }
}
spork ~ pinwheelCrossing();


// Main Loop
while (true) 
{
    GLOBAL_TICK => now;
    // // Ostinato
    // if (clock.getTick() % cycle == 0) 
    // {
    //     pinwheel.strike(0.01);
    // }
    // if (maybe && clock.getTick() % cycle == 1) 
    // {
    //     pinwheel.strike(0.04, Std.mtof(keyCenter + 2));
    // }

    // if (clock._second % 4 == 0) {
    //     // Update Ostinato Index
    //     ostInc();
    //     pinwheel.strike(0.01);
    // }

    // // Update Ostinato every 15 seconds
    if (clock.exactSecondIs(15) || clock.exactSecondIs(30) ||
        clock.exactSecondIs(45) || clock.exactSecondIs(0)) {
        // Update Ostinato Index
        <<< "UPDATE OSTINATO" >>>;
        ostInc();
    }
}

function ostInc() {
    ostinatoIndex++;
    if (ostinatoIndex >= ostinato.size()) 
    {
        0 => ostinatoIndex;
    }
    pinwheel.setKeyCenter(keyCenter + ostinato[ostinatoIndex]);
}