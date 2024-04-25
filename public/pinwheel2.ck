//---------------------------------------------------------
// PINWHEEL PRISM
//---------------------------------------------------------

class Prism extends Chugraph
{
    ModalBar bar => BPF bpf => PRCRev rev => NRev rev2 => outlet;
    bar.controlChange( 16, 1 );
    bar.controlChange( 1, 68);
    bar.damp(0.2);

    bpf.freq( 3000 );
    bpf.Q( 2 );
    rev.mix(0.21);
    rev2.mix(0.21);

    fun @construct(dur decay) 
    {
    }

    fun void noteOn(float gain) 
    {
        Math.random2f( 80, 90 ) => float stickHardness;
        Math.random2f( 10, 30 ) => float strikePosition;
        Math.random2f( 0, 2 ) => float vibratoGain;
        Math.random2f( 20, 50 ) => float vibratoFreq;

        bar.controlChange( 2, stickHardness );
        bar.controlChange( 4, strikePosition );
        bar.controlChange( 11, vibratoGain );
        bar.controlChange( 7, vibratoFreq );

        gain => bar.noteOn;
    }

    fun void noteOff() 
    {
        bar.noteOff;
    }

    fun void freq(float freq) 
    {
        freq => bar.freq;
    }

    fun float freq() 
    {
        return bar.freq();
    }
}

//---------------------------------------------------------
// PINWHEEL VIBRAPHONE
//---------------------------------------------------------
class Blade extends Chugraph
{
    Impulse imp => BPF bpf => outlet;
    bpf.Q(1);
    bpf.freq(440);
    bpf.gain(20);

    fun void noteOn(float gain) 
    {
        gain => imp.next;
    }

    fun void noteOff() { }

    fun void freq(float freq) 
    {
        freq => bpf.freq;
    }

    fun float freq() 
    {
        return bpf.freq();
    }

}

//---------------------------------------------------------
// PINWHEEL 2 INSTRUMENT
//---------------------------------------------------------
public class Pinwheel
{
    Blade blade => Gain g => DelayL l => JCRev rev => dac; // Blade Cross
    l => g;
    Prism vibe => NRev rev2 => dac; // Background
    l.max(0.06::second);
    l.delay(0.06::second);
    l.gain(0.5);
    rev.mix(0.01);
    rev2.mix(0.1);

    4 * Math.PI => float MAX_VELOCITY;

    // Variables
    63 => int keyCenter;
    [ 4, 7, 2, 7, 4, 12+4 ] @=> int pentatonic[];

    0 => int pentIndex;

    // Set the key center
    fun void setKeyCenter(int midi) 
    {
        midi => keyCenter; 
        vibe.freq(Std.mtof(midi));
    }

    fun void strike(float gain) 
    {
        vibe.freq(Std.mtof(keyCenter));
        vibe.noteOn(gain);
    }

    fun void strike(float gain, float freq) 
    {
        vibe.freq(freq);
        vibe.noteOn(gain);
    }

    // Trigger the pinwheel and cycle the index
    fun void blow(float velocity) 
    {
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