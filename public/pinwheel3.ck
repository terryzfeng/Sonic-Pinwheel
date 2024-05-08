//---------------------------------------------------------
// PINWHEEL VIBRAPHONE
//---------------------------------------------------------
class Shaker extends Chugraph
{
    Shakers shake => outlet;
    shake => LPF lpf => JCRev rev => outlet;
    lpf.freq(500);
    .01 => rev.mix;

    shake.which(1);
    shake.energy(.9);

    fun void noteOn(float gain) 
    {
        Math.random2f(0,128) => shake.objects;
        gain * 2.3 => shake.noteOn;
    }

    fun void noteOff() { }

    fun void freq(float freq) 
    {
        (freq $ int) % 2 * Math.random2(0,4) => shake.which;
        freq => shake.freq;
    }

    fun float freq() 
    {
        return shake.freq();
    }
}

//---------------------------------------------------------
// PINWHEEL 3 INSTRUMENT
//---------------------------------------------------------
public class Pinwheel
{
    Shaker blade => JCRev rev => dac; // Blade Cross
    rev.mix(0.01);

    4 * Math.PI => float MAX_VELOCITY;

    // Variables
    63 => int keyCenter;
    [ 4, 7, 2, 7, 4, 12+4 ] @=> int pentatonic[];

    0 => int pentIndex;

    // Set the key center
    fun void setKeyCenter(int midi) 
    {
        midi => keyCenter; 
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