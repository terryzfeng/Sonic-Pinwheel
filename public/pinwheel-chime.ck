class PingPong extends Chugraph {
    inlet => outlet;
    inlet => DelayL dL => Gain fbL => GVerb gverbL => dac.chan(0);
    inlet => DelayL dR => Delay dR2 => Gain fbR => GVerb gverbR => dac.chan(1);
    fbL => dL;
    fbR => dR;
    fbL => outlet;
    fbR => outlet;
    outlet.gain(0.9);

    .4::second => dL.max => dL.delay;
    .4::second => dR.max => dR.delay;
    .4::second => dR2.max => dR2.delay;

    20 => gverbL.roomsize;
    1.4::second => gverbL.revtime;
    0.5 => gverbL.dry;
    0.2 => gverbL.early;
    0.3 => gverbL.tail;

    20 => gverbR.roomsize;
    1.6::second => gverbR.revtime;
    0.5 => gverbR.dry;
    0.2 => gverbR.early;
    0.4 => gverbR.tail;

    // .64 => fbL.gain; // set feedback
    .25 => dL.gain; // set effects mix

    // .64 => fbR.gain; // set feedback
    .25 => dR.gain; // set effects mix
    .25 => dR2.gain; // set effects mix
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
        Math.random2f( 0, 20 ) => float stickHardness;
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

    fun void midi(int note) 
    {
        Std.mtof(note) => bar.freq;
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
    env1.gain(0.5);
    env2.gain(1.2);
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
        env1.set(20::ms, decay, .0, 0.8::second);
        
        // Env2
        env2.set(3::ms, .2::second, 0, .3::second);
        
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

    fun void midi(int note) {
        freq(Std.mtof(note));
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

// Simpler Vibraphone implementation
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
//         freq * 3 => osc.freq;
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
    Stick stick(0.5::second) => GVerb gverb => dac;
    Vibraphone vibe() => LPF lpf => HPF hpf => PingPong p => gverb;
    lpf.freq(10000);
    hpf.freq(1000);
    stick.gain(0.9);
    vibe.gain(0.2);

    30 => gverb.roomsize;
    1.6::second => gverb.revtime;
    0.3 => gverb.dry;
    0.2 => gverb.early;
    0.6 => gverb.tail;
    
    // Variables
    63 => int keyCenter;
    0 => int scoreIndex;

    // Chimes SCORE (2 mo
    [0, 2, 4, 5, 7, 9, 11, 12, 14, 16] @=> int major[];
    [2, 0, 2, 4, -5, -1, 4, 7, 7, 7, 7, 5, 4, -15, -13, -12, 2, 2, 12, 7, 7, -8, -5, -1, -1, 7, 2, 2, 4, -5, 0] @=> int pentatonic[];
    major.size() => int currLength;
    0 => int mode;
    0 => int cycleIndex;
    0 => int cycleStart;
    
    // Set the key center
    fun void setKeyCenter(int midi) 
    {
        midi + 12 => keyCenter; 
    }
    
    fun void updateScore(int newIndex) {
        newIndex => scoreIndex;
        // Major Scale Mode
        if (scoreIndex == 0 || scoreIndex >= 32) {
            0 => mode;
            major.size() - Math.random2(0,2) => currLength;
            0 => cycleStart;
        } else {
            1 => mode;
            Math.random2(0,pentatonic.size()-1) => cycleStart;
            Math.random2(cycleStart,pentatonic.size()-1) => cycleIndex;
        }
    }

    fun void incCycle() {
        // Scale Mode
        if (mode == 0) {
            ++cycleIndex;
            if (cycleIndex >= currLength) {
                Math.random2(cycleStart,currLength-1) => cycleIndex;
            }
        } else {
            // Pentatonic
            ++cycleIndex;
            // double skip occasionally
            if (cycleIndex < currLength && pentatonic[cycleIndex] > 7 && maybe && maybe) {
                ++cycleIndex;
            }
            if (cycleIndex >= currLength) {
                if (scoreIndex % 3 == 0 || scoreIndex % 4 == 0) {
                    cycleStart + Math.random2(0,2) => cycleIndex; // Random reset back to 2
                } else {
                    cycleStart => cycleIndex; // Normal reset back to 3
                }
                // Set random end loop length
                Math.random2(cycleIndex,pentatonic.size()-1) => currLength;
            }
        }
    }
    
    // Trigger the pinwheel and cycle the index
    fun void blow(float gain, int bladeIndex) 
    {
        Math.min(gain, 1.0) => gain;
        // Play the pitch
        if (mode == 0) {
            stick.midi(keyCenter + major[cycleIndex]);
            vibe.midi(keyCenter + major[cycleIndex]);
        } else {
            stick.midi(keyCenter + pentatonic[cycleIndex]);
            vibe.midi(keyCenter + pentatonic[cycleIndex]);
        }
        stick.noteOn(gain);
        vibe.noteOn(gain);
        incCycle();

        1000::ms => now;
        // stick.noteOff();
        // vibe.noteOff();
    }
}
    