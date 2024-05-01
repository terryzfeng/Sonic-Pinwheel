//---------------------------------------------------------
// PINWHEEL VIBRAPHONE
//---------------------------------------------------------
class Blade extends Chugraph
{
    Impulse imp => outlet;

    fun void noteOn(float gain) 
    {
        gain => imp.next;
    }

    fun void noteOff() { }

    fun void freq(float freq) 
    {
        // freq => bpf.freq;
    }

    fun float freq() 
    {
        // return bpf.freq();
        return 0;
    }

}

//---------------------------------------------------------
// PINWHEEL 2 INSTRUMENT
//---------------------------------------------------------
public class Pinwheel
{
    Blade blade => JCRev rev => dac; // Blade Cross
    // Prism vibe => NRev rev2 => dac; // Background
    rev.mix(0.01);
    // rev2.mix(0.1);

    4 * Math.PI => float MAX_VELOCITY;

    // Variables
    63 => int keyCenter;
    [ 4, 7, 2, 7, 4, 12+4 ] @=> int pentatonic[];

    0 => int pentIndex;

    // Set the key center
    fun void setKeyCenter(int midi) 
    {
        midi => keyCenter; 
        // vibe.freq(Std.mtof(midi));
    }

    fun void strike(float gain) 
    {
        // vibe.freq(Std.mtof(keyCenter));
        // vibe.noteOn(gain);
    }

    fun void strike(float gain, int freq) 
    {
        // vibe.freq(freq);
        // vibe.noteOn(gain);
    }

    // Trigger the pinwheel and cycle the index
    fun void blow(float velocity, int bladeIndex) 
    {
        if (bladeIndex % 2 == 0) 
        {
            return;
        }
        // Trigger pinwheel
        pentatonic[pentIndex] + (keyCenter + 12*Math.random2(0,2)) => Std.mtof => blade.freq;
        // <<< velocityToGain(velocity) >>>;
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