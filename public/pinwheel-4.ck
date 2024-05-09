//---------------------------------------------------------
// PINWHEEL VIBRAPHONE
//---------------------------------------------------------

global float MIC_FREQ;
class Voice extends Chugraph
{
    SinOsc osc => Chorus c => NRev r => outlet;
    c.baseDelay( 10::ms );
    c.modDepth( .4 );
    c.modFreq( 1 );
    c.mix( .2 );

    r.mix(0.1);

    fun void noteOn(float gain) 
    {
        MIC_FREQ => osc.freq;
        gain => osc.gain;
    }

    fun void noteOff() { }

    fun void freq(float freq) 
    {

    }

    fun float freq() 
    {
        return 0;
    }
}

//---------------------------------------------------------
// PINWHEEL 3 INSTRUMENT
//---------------------------------------------------------
public class Pinwheel
{
    Voice blade => JCRev rev => dac; // Blade Cross
    rev.mix(0.01);

    4 * Math.PI => float MAX_VELOCITY;

    // Variables
    63 => int keyCenter;
    // [ 4, 7, 2, 7, 4, 12+4 ] @=> int pentatonic[];

    // 0 => int pentIndex;

    // Set the key center
    fun void setKeyCenter(int midi) 
    {
        midi => keyCenter; 
    }

    fun void updateScore(int newIndex) {}

    // Trigger the pinwheel and cycle the index
    fun void blow(float velocity, int bladeIndex) 
    {
        <<< "blow" >>>;
        blade.noteOn(velocityToGain(velocity));
        100::ms => now;
        blade.noteOff();
    }

    fun float velocityToGain(float velocity) 
    {
        Math.sqrt(velocity / (MAX_VELOCITY)) => float gain;
        return gain * .3 + .2;
    }
}