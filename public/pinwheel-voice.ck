// //----------------------------------------------------------
// // title: Voice (aah)
// // desc: Voice using granular synthesis of me saying ahh in ahh.wav
// //       adapted from Jack Atherton's Chuck Timbre Library
// //       view original here:
// //       https://ccrma.stanford.edu/~lja/timbre-library/
// //
// // date: May 2024
// // author: terry feng
// //----------------------------------------------------------

global float MIC_FREQ;

//---------------------------------------------------------
// voice - aah granular synthesis
//---------------------------------------------------------
// class Voice extends Chugraph {
//     // noise
//     LiSa lisa => Gain bus => LPF lpf => ADSR adsr => outlet;
//     15000 => lpf.freq;
//     adsr.set( 30::ms, 30::ms, 0.9, 200::ms );

//     // CONSTANTS
//     0.1 => float SLIDE_RATIO;

//     // Member Vars
//     float _freq; float _targetFreq;
//     float _gain; float _targetGain;
//     0.1 => float _slideSpeed; // default, gets overriden
//     false => int _shouldPlay;
//     dur _bufferLen; 
    
//     // Lisa Configuration
//     // spawn rate: how often a new grain is spawned (ms)
//     25 =>  float grainSpawnRateMS;
//     0 =>  float grainSpawnRateVariationMS;
//     0.0 =>  float grainSpawnRateVariationRateMS;
//     // position: where in the file is a grain (0 to 1)
//     0.0 =>  float grainPosition;
//     0.2 =>  float grainPositionRandomness;
//     // grain length: how long is a grain (ms)
//     300 =>  float grainLengthMS;
//     10 =>  float grainLengthRandomnessMS;
//     // grain rate: how quickly is the grain scanning through the file
//     1.004 =>  float _grainRate; // 1.002 == in-tune Ab
//     0.015 =>  float _grainRateRandomness;
//     // ramp up/down: how quickly we ramp up / down
//     50 =>  float rampUpMS;
//     200 =>  float rampDownMS;
    
//     fun void midi( int m )
//     {
//         freq(Std.mtof(m));
//     }
    
//     fun void freq( float f )
//     {
//         f => _targetFreq;
//     }

//     fun void noteOn( float gain )
//     {
//         gain => _targetGain;
//         adsr.keyOn( true );

//         gain * SLIDE_RATIO => _slideSpeed;
//         adsr.keyOn( true );
//         true => _shouldPlay;
//     }
    
//     fun void noteOff()
//     {
//         adsr.keyOff( true );
//         false => _shouldPlay;
//     }
    
    
//     // Finish configure Lisa
//     // Read in samples into SndBuf => Lisa
//     SndBuf buf("aah.wav"); 
//     (buf.samples() + 1)::samp => lisa.duration;
//     for( int i; i < buf.samples(); i++ )
//     {
//         lisa.valueAt( buf.valueAt( i ), i::samp );
//     }
//     buf.length() => _bufferLen;
    
//     // LiSa params
//     100 => lisa.maxVoices;
//     0.9 => lisa.gain;
//     true => lisa.loop;
//     false => lisa.record;
    
//     // modulate
//     SinOsc freqmod => blackhole;
//     0.1 => freqmod.freq;
    
//     //--------------------------------------------------------
//     // CONTINUOUSLY RUNNING FUNCTIONS
//     //--------------------------------------------------------
//     fun void spawnGrains()
//     {
//         // create grains
//         while( true )
//         {
//             // Update gain pitch frequency
//             60 => Std.mtof => float baseFreq;
//             _freq / baseFreq * 1.02 => _grainRate; // Correction for tuning
//             // grain length
//             ( grainLengthMS + Math.random2f( -grainLengthRandomnessMS / 2, grainLengthRandomnessMS / 2 ) )
//                 * 1::ms => dur grainLength;
//             // grain rate
//             _grainRate + Math.random2f( -_grainRateRandomness / 2, _grainRateRandomness / 2 ) => float _grainRate;
//             // grain position
//             ( grainPosition + Math.random2f( -grainPositionRandomness / 2, grainPositionRandomness / 2 ) )
//             * _bufferLen => dur playPos;
//             // grain: grainlen, rampup, rampdown, rate, playPos
//             spork ~ playGrain( grainLength, rampUpMS::ms, rampDownMS::ms, _grainRate, playPos);
            
//             // advance time (time per grain)
//             // PARAM: GRAIN SPAWN RATE
//             grainSpawnRateMS::ms  + freqmod.last() * grainSpawnRateVariationMS::ms => now;
//             grainSpawnRateVariationRateMS => freqmod.freq;
//         }
//     }
//     spork ~ spawnGrains();
    
//     // gets called by spawnGrains
//     fun void playGrain( dur grainlen, dur rampup, dur rampdown, float rate, dur playPos )
//     {
//         lisa.getVoice() => int newvoice;
        
//         if(_shouldPlay && newvoice > -1)
//         {
//             lisa.rate( newvoice, rate );
//             lisa.playPos( newvoice, playPos );
//             lisa.rampUp( newvoice, rampup );
//             ( grainlen - ( rampup + rampdown ) ) => now;
//             lisa.rampDown( newvoice, rampdown) ;
//             rampdown => now;
//         }
//     }

//     fun void pitchSlider() {
//         while(true) {
//             // Pitch slider
//             (_targetFreq * _slideSpeed) + (_freq * (1 - _slideSpeed)) => _freq;
//             // Gain slider
//             (_targetGain * _slideSpeed) + (_gain * (1 - _slideSpeed)) => _gain => bus.gain;
//             10::ms => now;
//         }
//     }
//     spork ~ pitchSlider();
// }

class Formant extends Chugraph {
    inlet => BPF bpf => outlet;

    fun @construct(float freq, float gain, float Q) {
        bpf.freq(freq);
        bpf.gain(gain);
        bpf.Q(Q);
    }

    fun set(float freq, float gain, float Q) {
        bpf.freq(freq);
        bpf.gain(gain);
        bpf.Q(Q);
    }

    fun freq(float freq) {
        bpf.freq(freq);
    }
}

class Voice extends Chugraph
{
    1 => int NUM_VOICES;
    // noise
    Gain bus => ADSR adsr => NRev r => outlet;
    // Noise
    Noise noise => Gain formantBus;
    noise.gain(0.01);
    formantBus => Formant f1(300, 1, 5) => bus;
    formantBus => Formant f2(870, 0.6, 20) => bus;
    formantBus => Formant f3(2250, .4, 50) => bus;
    // SinOsc
    SinOsc osc[NUM_VOICES] => LPF lpf => Chorus c => Gain oscBus => bus;
    oscBus.gain(.4 * (1.0/NUM_VOICES));

    // FX
    lpf.freq(Std.mtof(63+12));
    lpf.Q(2);
    c.baseDelay( 10::ms );
    c.modDepth( .1 );
    c.modFreq( 3 );
    c.mix( .3 );
    r.mix(0.1);

    // Member vars
    float _freq;  float _targetFreq;
    float _gain; float _targetGain;
    0.1 => float _slideSpeed;
    now => time _lastOn;
    Event _noteTriggered;

    // Constants
    3::second => dur AUTO_OFF;
    .1 => float SLIDE_RATIO;

    // Init
    adsr.set(100::ms, 1.5::second, .0, 2::second);

    fun void noteOn(float gain) 
    {
        gain => _targetGain;
        gain * SLIDE_RATIO => _slideSpeed;
        Math.random2(0, 2) => int formantIndex;

        adsr.keyOn();

        now => _lastOn;
        _noteTriggered.broadcast();
    }

    fun void noteOff() { 
        adsr.keyOff();
    }

    fun void freq(float freq) 
    {
        freq => _targetFreq;
    }

    fun float freq() 
    {
        return _freq;
    }

    fun void movement() {
        SinOsc lfo => blackhole;
        lfo.period(2::second);
        while(true) {
            207 + (10*lfo.last()) => f1.freq;
            2200 + (20*lfo.last()) => f2.freq;
            3000 + (10*-lfo.last()) => f3.freq;
            10::ms => now;
        }
    }
    spork ~ movement();

    /** lerp the voice continuously, pitch and gain */
    fun void pitchSlider() {
        while(true) {
            // Pitch slider
            (_targetFreq * _slideSpeed) + (_freq * (1 - _slideSpeed)) => _freq;
            for (int i; i < NUM_VOICES; i++) {
                _freq + Math.random2f(-10, 10) => osc[i].freq;
            }
            // Gain slider
            (_targetGain * _slideSpeed) + (_gain * (1 - _slideSpeed)) => _gain => bus.gain;
            10::ms => now;
        }
    }
    spork ~ pitchSlider();

    /** Auto shut off the note after 3 seconds */
    fun void autoTurnOff() {
        while(true) {
            _noteTriggered => now; // wait for note to be triggered
            while (now < _lastOn + AUTO_OFF) {
                50::ms => now;
            }
            noteOff();
        }
    }
    spork ~ autoTurnOff();
}

//---------------------------------------------------------
// PINWHEEL 3 INSTRUMENT
//---------------------------------------------------------
public class Pinwheel
{
    Voice voice => JCRev rev => dac; // voice Cross
    rev.mix(0.2);

    // Variables
    63 => int keyCenter;
    [0, 2, 4, 5, 7, 9, 11] @=> int major[];


    // Set the key center
    fun void setKeyCenter(int midi) 
    {
        midi + 12 => keyCenter; 
    }

    fun void updateScore(int newIndex) {}

    // Trigger the pinwheel and cycle the index
    fun void blow(float gain, int voiceIndex) 
    {
        quantizeFreq(MIC_FREQ) => voice.freq;
        voice.noteOn(gain);
        100::ms => now;
        voice.noteOff();
    }

    // Quantize the frequency to the nearest major scale
    fun float quantizeFreq(float freq) {
        // Get nearest major interval
        Std.ftom(freq) $ int => int midi;
        midi % 12 => int wrappedMidi;
        12 => int min;
        0 => int minIndex;
        for (0 => int i; i < major.size(); i++) {
            wrappedMidi - major[i] => int diff;
            if (diff < min) {
                diff => min;
                i => minIndex;
            }
        }
        minIndex => int majorIndex;
        // Get octave 
        (midi / 12) * 12 => int octave;
        Std.mtof(octave + major[majorIndex]) => float newFreq;
        return newFreq;
    }
}