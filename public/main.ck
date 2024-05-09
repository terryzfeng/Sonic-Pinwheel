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
0 => global int PINWHEEL_BLADE;
0.0 => global float PINWHEEL_VEL;
global Event BLADE_CROSSED;
global Event READY;
global float MIC_ACTIVE;
global float MIC_DBFS;
global float MIC_MAG;
global float MIC_FREQ;

// Main UGens
MicTrack micTrack;
Pinwheel pinwheel;

// Variables
63 => int keyCenter;
40 => int scoreSize;
0 => int scoreIndex;

// CONSTANTS
3 => int CYCLE_MIN;
16 => int CYCLE_MAX;

//-------
// Initialize System
//-------
// Wait for clock to start
READY => now;
// Set Ostinato Cycle
Math.random2(CYCLE_MIN,CYCLE_MAX) => int cycle;
// Init Pinwheel
pinwheel.setKeyCenter(keyCenter);
// Initial score position
clock.getTick() / 36 => scoreIndex;
<<< "Pinwheel Score:" , scoreIndex, "(" + clock.getTick() / 4 + ")">>>;

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
        micTrack.getFreq() => MIC_FREQ;

        50::ms => now;
    }
}
spork ~ control();

//-------
// PINWHEEL CONTROL
//-------
4 * Math.PI => float MAX_VELOCITY;
fun float velocityToGain(float velocity) 
{
    Math.sqrt(velocity / (MAX_VELOCITY)) => float gain;
    return gain * .3;
}
fun void pinwheelCrossing() 
{
    while (true)
    {
        BLADE_CROSSED => now;
        spork ~ pinwheel.blow(velocityToGain(PINWHEEL_VEL), PINWHEEL_BLADE);
    }
}
spork ~ pinwheelCrossing();


//-------
// MAIN LOOP
//-------
while (true) 
{
    GLOBAL_TICK => now;

    // Advance Score every 15 seconds * 4 beats = 60 ticks
    if (clock.getTick() % 60 == 0) {
        scoreInc();
    }
}

function scoreInc() {
    if (++scoreIndex >= scoreSize) {
        0 => scoreIndex;
    }
    <<< "scoreInc:", scoreIndex >>>;
    pinwheel.updateScore(scoreIndex);
}