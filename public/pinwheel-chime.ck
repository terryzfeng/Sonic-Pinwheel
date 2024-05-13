class PingPong extends Chugraph {
    inlet => outlet;
    inlet => DelayL dL => Gain fbL => outlet;
    inlet => DelayL dR => Delay dR2 => Gain fbR => outlet;
    fbL => dL;
    fbR => dR;
    outlet.gain(0.9);

    .25::second => dL.max => dL.delay;
    .25::second => dR.max => dR.delay;
    .25::second => dR2.max => dR2.delay;

    // .64 => fbL.gain; // set feedback
    .47 => dL.gain; // set effects mix

    // .64 => fbR.gain; // set feedback
    .47 => dR.gain; // set effects mix
    .47 => dR2.gain; // set effects mix
}

class Stick extends Chugraph
{
    ModalBar bar => outlet;
    bar => outlet;
    bar.controlChange( 16, 3 );
    bar.controlChange( 1, 68);
    
    fun @construct(dur decay) 
    {
    }
    
    fun void noteOn(float gain) 
    {
        Math.random2f( 10, 40 ) => float stickHardness;
        Math.random2f( 10, 80 ) => float strikePosition;
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
    Gain bus => Gain master => outlet;
    SinOsc osc1[5]; Gain osc1Gain; Envelope tremolo;
    SinOsc osc2; 
    SinOsc osc3; 
    ADSR env1; ADSR env2;
    LPF lpf1; lpf1.set(220, 0); lpf1.gain(1); // not sure why gain is needed
    env1 => lpf1 => bus;
    env2 => lpf1 => bus;
    master.gain(0.6);
    
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
        .45 => osc3.gain;

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
        bus.gain(gain);
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

// class Vibraphone extends Chugraph {
//     SinOsc osc => ADSR env => Gain g => outlet;
//     SinOsc osc2 => env;
//     env.set(0.1::ms, 0.5::second, 0.0, 0.5::second);
    
//     osc.gain(0.8);
//     osc2.gain(0.1);

//     fun void noteOn(float gain) {
//         gain => g.gain;
//         env.keyOn();
//     }

//     fun void noteOff() {
//         env.keyOff();
//     }

//     fun void midi(int note) {
//         Std.mtof(note+36) => osc.freq;
//         osc.freq() * 5 => osc2.freq;
//     }

//     fun void freq(float freq) {
//         freq => osc.freq;
//         freq * 5 => osc2.freq;
//     }

//     fun float freq() {
//         return osc.freq();
//     }
// }

//---------------------------------------------------------
// PINWHEEL 1 INSTRUMENT
//---------------------------------------------------------
public class Pinwheel
{
    Stick stick(0.5::second) => Gain g => GVerb gverb => dac;
    Vibraphone vibe() => PingPong p => gverb => dac;
    g.gain(0.8);

    20 => gverb.roomsize;
    1.6::second => gverb.revtime;
    0.4 => gverb.dry;
    0.2 => gverb.early;
    0.3 => gverb.tail;
    
    // Variables
    63 => int keyCenter;
    [0, -1, 2, 0] @=> int pentatonic[];
    
    0 => int pentIndex;
    
    // Set the key center
    fun void setKeyCenter(int midi) 
    {
        midi => keyCenter; 
    }
    
    fun void updateScore(int newIndex) {}
    
    // Trigger the pinwheel and cycle the index
    fun void blow(float gain, int bladeIndex) 
    {
        // Trigger pinwheel
        pentatonic[pentIndex] + (keyCenter + 12) => Std.mtof => stick.freq;
        pentatonic[pentIndex] + (keyCenter + 12) + 12 * Math.random2(0,1) => Std.mtof => vibe.freq;

        stick.noteOn(gain);
        vibe.noteOn(gain);

        // Update pentatonic index
        pentIndex++;
        if (pentIndex >= pentatonic.size()) 
        {
            0 => pentIndex;
        };

        5000::ms => now;
        // stick.noteOff();
        // vibe.noteOff();
    }
}
    