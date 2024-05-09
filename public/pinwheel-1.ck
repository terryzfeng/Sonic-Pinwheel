//---------------------------------------------------------
// PINWHEEL PRISM
//---------------------------------------------------------
// class Prism extends Chugraph
// {
//     ModalBar bar => BPF bpf => NRev rev => outlet;
//     bar.controlChange( 16, 1 );
//     bar.controlChange( 1, 1);

//     bpf.freq( 4000 );
//     bpf.Q( 2 );
//     rev.mix(0.5);

//     fun @construct(dur decay) 
//     {
//     }

//     fun void noteOn(float gain) 
//     {
//         Math.random2f( 80, 90 ) => float stickHardness;
//         Math.random2f( 10, 30 ) => float strikePosition;
//         Math.random2f( 0, 2 ) => float vibratoGain;
//         Math.random2f( 20, 50 ) => float vibratoFreq;

//         bar.controlChange( 2, stickHardness );
//         bar.controlChange( 4, strikePosition );
//         bar.controlChange( 11, vibratoGain );
//         bar.controlChange( 7, vibratoFreq );

//         gain => bar.noteOn;
//     }

//     fun void noteOff() 
//     {
//         bar.noteOff;
//     }

//     fun void freq(float freq) 
//     {
//         freq => bar.freq;
//     }

//     fun float freq() 
//     {
//         return bar.freq();
//     }
// }

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
class Vibraphone extends Chugraph
{
    Gain master => outlet;
    SinOsc osc1[5]; Gain osc1Gain; Envelope tremolo;
    SinOsc osc2; 
    SinOsc osc3; 
    ADSR env1; ADSR env2;
    LPF lpf1; lpf1.set(220, 0); lpf1.gain(1); // not sure why gain is needed
    env1 => lpf1 => master;
    env2 => lpf1 => master;

    // member variables
    float _freq;
    float _gain;
    float _tremolo_period;
    dur _tremolo_half; 

    fun @construct() {
        init(2.2::second);
    }

    fun @construct(dur decay) {
        init(decay);
    }
    
    fun init(dur decay) 
    {
        220.0 => _freq;
        1 => _gain;

        // Osc1
        0.3 => osc1Gain.gain;
        
        _freq => osc1[0].freq;
        2*_freq+2 => osc1[1].freq;
        3*_freq-3 => osc1[2].freq;
        4*_freq+4 => osc1[3].freq;
        6*_freq-6 => osc1[4].freq;
        
        1.0 => osc1[0].gain;
        .2 => osc1[1].gain;
        .4 => osc1[2].gain;
        .6 => osc1[3].gain;
        .25 => osc1[4].gain;
        
        .5 => osc1[2].phase;
        
        // Osc2
        220 * 10 => osc2.freq;
        .08 => osc2.gain;
        
        // Osc3
        220 * 16 => osc3.freq;
        .05 => osc3.gain;

        // Env1
        env1.set(0::ms, decay, .0, 0.8::second);
        
        // Env2
        env2.set(0::ms, .2::second, 0, .3::second);

        // Tremolo
        .2 => _tremolo_period;
        .2::second => tremolo.duration;
        tremolo.duration() / 2.0 => _tremolo_half;
        
        // Patch
        for (0 => int i; i < 5; i++) {
            osc1[i] => osc1Gain;
        }
        osc1Gain => tremolo => env1;
        osc2 => env2;
        osc3 => env2;
    }

    fun void freq(float freq) 
    {
        freq => _freq;
        _freq => osc1[0].freq;
        2*_freq+2 => osc1[1].freq;
        3*_freq-3 => osc1[2].freq;
        4*_freq+4 => osc1[3].freq;
        6*_freq-6 => osc1[4].freq;
        10 * _freq => osc2.freq;
        16 * _freq => osc3.freq;
    }

    fun float freq() 
    {
        return _freq;
    }

    public void noteOn(float gain) 
    {
        master.gain(gain);
        env1.keyOn();
        env2.keyOn();
        spork ~ lpfSweep();
        spork ~ tremoloNow();
    }

    public void noteOff() 
    {
        env1.keyOff();
        env2.keyOff(); 
    }
    
    fun void lpfSweep() 
    {
        lpf1.freq(10000);
        while (lpf1.freq() > _freq) 
        {
            lpf1.freq() * .985 => lpf1.freq;
            10::ms => now;
        }
    }

    fun void tremoloNow() 
    {
        tremolo.value(1);
        now + 3::second => time later;
        _tremolo_half => dur currTremolo;
        while(now < later) 
        {
            tremolo.keyOff();
            currTremolo => now;
            tremolo.keyOn();
            currTremolo => now;
            currTremolo * .98 => currTremolo;
        }
    }
}

//---------------------------------------------------------
// PINWHEEL 1 INSTRUMENT
//---------------------------------------------------------
public class Pinwheel
{
    Prism prism(0.5::second) => NRev rev => LPF lpf => dac; // background ostinato
    Vibraphone vibe => NRev rev2 => dac; // pentatonic pinwheel
    lpf.freq( 2000 );
    rev.mix(0.1);
    rev2.mix(0.4);

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
    fun void blow(float velocity, int bladeIndex) 
    {
        // Trigger pinwheel
        pentatonic[pentIndex] + (keyCenter + 12*Math.random2(0,2)) => Std.mtof => prism.freq;
        // <<< velocityToGain(velocity) >>>;
        prism.noteOn(velocityToGain(velocity));
        // Update pentatonic index
        pentIndex++;
        if (pentIndex >= pentatonic.size()) 
        {
            0 => pentIndex;
        };
        100::ms => now;
        prism.noteOff();
    }

    fun float velocityToGain(float velocity) 
    {
        Math.sqrt(velocity / (MAX_VELOCITY)) => float gain;
        return gain * .3 + .2;
    }
}