//---------------------------------------------------------
// PINWHEEL VIBRAPHONE
//---------------------------------------------------------
class Bamboo extends Chugraph
{
    Shakers shake => Dyno d => JCRev rev => outlet;
    .001 => rev.mix;

    // Trickly kind of shaker
    shake.which(22);

    d.compress();
    2000::ms => d.releaseTime;
    0.2 => d.thresh;
    0.33 => d.slopeAbove;
    4 => d.gain;

    fun void noteOn(float gain) 
    {
        Math.random2f(0,30) => shake.objects;
        gain * 2 => shake.noteOn;
    }

    fun void noteOff() { }

    fun void freq(float freq) 
    {
        freq => shake.freq;
    }

    fun float freq() 
    {
        return shake.freq();
    }
}

//---------------------------------------------------------
// PINWHEEL 2 INSTRUMENT
//---------------------------------------------------------
public class Pinwheel
{
    Bamboo blade => JCRev rev => dac; // Blade Cross
    rev.mix(0.01);

    4 * Math.PI => float MAX_VELOCITY;

    // Variables
    63 => int keyCenter;
    [ 4, 7, 2, 7, 4, 12+4 ] @=> int pentatonic[];

    0 => int pentIndex;

    // Set the key center
    fun void setKeyCenter(int midi) 
    {
        midi - 24 => keyCenter; 
    }

    // Trigger the pinwheel and cycle the index
    fun void blow(float velocity, int bladeIndex) 
    {
        // Trigger pinwheel
        pentatonic[pentIndex] + (keyCenter + 12*Math.random2(0,2)) => Std.mtof => blade.freq;
        blade.noteOn(velocityToGain(velocity));
        // Update pentatonic index
        pentIndex++;
        if (pentIndex >= pentatonic.size()) 
        {
            0 => pentIndex;
        };
        100::ms => now;
        blade.noteOff();
    }

    fun float velocityToGain(float velocity) 
    {
        Math.sqrt(velocity / (MAX_VELOCITY)) => float gain;
        return gain * .3 + .2;
    }
}