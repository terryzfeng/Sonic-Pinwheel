//----------------------------
// title: sonic pinwheel
// desc: a pinwheel to blow and spin
//       makes sound when spinning
// 
// author: terry feng
// date: Feb 2024
//----------------------------

global Event GLOBAL_TICK;

class SonicPinwheel 
{
    1.0 => float _period; // in seconds
    0 => int _tick_count;
    1::second => dur _period_dur;
    0 => int _running;

    fun @construct(int count, float period) 
    {
        period => _period;
        _period::second => _period_dur;
        spork ~ start(count);
    }

    fun void start(int count) 
    {
        1 => _running;
        count => _tick_count;
        while (_running)
        {
            GLOBAL_TICK.broadcast();
            _tick_count++;
            _period_dur => now;
        }
    }
    
    fun void stop() 
    {
        0 => _running;
    }

    fun void period(float period) 
    {
        period => _period;
        _period::second => _period_dur;
    }
}

class MicTrack 
{
    20 => float THRESHOLD_DIFFERENCE;

    float _dbfs;
    float _threshold;
    dur _period;

    adc => Gain micInput;
    micInput => Gain g => OnePole p => blackhole;
    micInput => g; // square input
    3 => g.op; // multiple
    .99 => p.pole;

    // default 
    100::ms => _period;
    -60 => _dbfs;
    -40 => _threshold;

    fun @construct(dur period) 
    {
        period => _period;
    }

    // Return magnitude of the mic input
    fun float getMag() {
        // clamp between 0 and 1
        Math.min(1, Math.max(0, (_threshold - _dbfs) / _threshold)) => float mag;
        return mag;
    }

    // Return the current dbfs
    fun float getDBFS() {
        return _dbfs;
    }

    // Return if over threshold
    fun int active() {
        return _dbfs > _threshold; 
    }

    fun void setThreshold(float threshold) 
    {
        threshold => _threshold;
    }

    fun void autoSetThreshold() {
        .5::second => now;
        if (_dbfs > -100) {
            _dbfs + THRESHOLD_DIFFERENCE => _threshold;
            <<< "threshold", _threshold >>>;
        }
    }

    // Start tracking mic gain
    fun void start() {
        while (true)
        {
            20 * Math.log10( Math.sqrt(p.last()) ) => _dbfs;
            _period => now;
        }
    }

    spork ~ start();
    // spork ~ autoSetThreshold();
}

class Prism extends Chugraph
{
    ModalBar bar => LPF lpf => NRev rev => outlet;
    bar.controlChange( 16, 1 );
    bar.controlChange( 1, 0);

    lpf.freq(5000);
    rev.mix(0.09);

    fun void noteOn(float gain) 
    {
        Math.random2f( 40, 90 ) => float stickHardness;
        Math.random2f( 20, 40 ) => float strikePosition;
        Math.random2f( 0, 12 ) => float vibratoGain;
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
    
    fun @construct() 
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
        env1.set(0::ms, 2.2::second, .0, 0.8::second);
        
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

// MAIN
SonicPinwheel pinwheel(0, 0.25);
MicTrack micTrack;
Prism prism => dac; // low ostinato
Vibraphone vibe => NRev rev => dac; // pentatonic melody

rev.mix(0.05);
63 => int keyCenter;
[0,7] @=> int progression[];
[0,2,4,5,7,9,
12+2,12+0,12+7,12+4,
0,2,7,9] @=> int pentatonic[];

prism.freq(Std.mtof(keyCenter));
vibe.freq(Std.mtof(keyCenter));

fun void blowSonicPinwheel() 
{
    float mag;
    float active;
    int index;
    while (true) 
    {
        Math.fabs(Math.pow((micTrack.getMag()),1.0/4)) => mag;
        micTrack.active() => active;

        // If mic is active
        if (active) {
            pentatonic[index] + (keyCenter + 12*Math.random2(0,2)) => Std.mtof => prism.freq;
            // <<< Std.ftom(vibe.freq()) >>>;
            // prism.noteOn(mag);

            ((1.0 - mag) * 150)::ms => now;

            index++;
            if (index >= pentatonic.size()) 
            {
                0 => index;
            }
        }
        <<< micTrack.getDBFS() >>>;
        125::ms => now;
    }
}
spork ~ blowSonicPinwheel();

0 => int index;

Math.random2(2,6) => int cycle;


while (true) 
{
    GLOBAL_TICK => now;
    if (pinwheel._tick_count % cycle == 0) 
    {
        vibe.noteOn(0.18);
    }
    if (maybe && maybe && pinwheel._tick_count % cycle == 1) 
    {
        vibe.noteOn(0.16);
    }

    if (pinwheel._tick_count % 64 == 0) 
    {
        vibe.freq(Std.mtof(keyCenter + progression[index++]));
        if (index >= progression.size()) 
        {
            0 => index;
        }
    }
}
