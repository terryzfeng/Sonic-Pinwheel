//---------------------------------------------------------
// Bass - Pinwheel
//---------------------------------------------------------

class Bass extends Chugraph
{
    SawOsc osc => Gain g => ADSR adsr => LPF lpf => JCRev rev => outlet;
    SawOsc osc2 => BPF bpf => adsr;
    SinOsc lfo => blackhole;
    63 => int pitch;
    bpf.freq(100);
    bpf.Q(2);

    osc.gain(0.4);
    osc2.gain(0.1);
    adsr.set(10::ms, 300::ms, 0, 0::ms);
    rev.mix(0.06);

    24 => int SUB;
    7 => int FIFTH;
    12 => int OCTAVE;

    lpf.freq(Std.mtof(pitch-17));
    lpf.Q(2);
    osc.freq(Std.mtof(pitch-24));

    fun void noteOn(float gain) 
    {
        g.gain(gain);
        adsr.keyOn();
    }

    fun void noteOff() { 
        adsr.keyOff();
    }

    fun void midi(int midiVal) 
    {
        midiVal => pitch;
        osc.freq(Std.mtof(midiVal-SUB));
        osc2.freq(Std.mtof(midiVal-SUB-OCTAVE));
        lpf.freq(Std.mtof(midiVal-SUB+OCTAVE));
        bpf.freq(Std.mtof(midiVal-SUB+OCTAVE));
    }

    fun void freq(float freq) 
    {
        osc.freq(freq);
        osc2.freq(Std.mtof(Std.ftom(freq) - OCTAVE));
        lpf.freq(Std.mtof(Std.ftom(freq) + 2 * OCTAVE));
        bpf.freq(Std.mtof(Std.ftom(freq) + 12));
    }

    fun float freq() 
    {
        return osc.freq();
    }

    fun void updateLFO() {
        while (true) {
            200 + 50 * lfo.last() => bpf.freq;
            50::ms => now;
        }
    }
    spork ~ updateLFO();
}

//---------------------------------------------------------
// PINWHEEL Bass
//---------------------------------------------------------
public class Pinwheel
{
    Bass bass => dac;

    // Variables
    63 => int keyCenter;
    keyCenter => int pitch;
    0 => int scoreIndex;
    [0, 2, 4, 5, 7, 9, 11, 12] @=> int major[];

    Math.random2(3,16) => int cycle;
    0 => int cycleIndex;

    // BASS SCORE (40 NOTES)
    // relative to key center
    [ 0, 0, 4, 4, 0, 0, 4, 4,
      0, 0, 3, 3, 0, 0, 4, 4,
      5, 5, 3, 3, 2, 2, 1, 1, 
      0, 0, 3, 3, 0, 0, 4, 4,
      0, 1, 2, 3, 4, 5, 6, 7 ] @=> int score[];

    // Set the key center
    fun void setKeyCenter(int midi) 
    {
        midi => keyCenter; 
    }

    fun void updateScore(int newIndex) {
        newIndex => scoreIndex;
        keyCenter + major[score[scoreIndex]] => pitch;
        // Change the cycle
        Math.random2(3,16) => cycle;
    }

    // Trigger the pinwheel, play a bass note
    fun void blow(float gain, int bladeIndex) 
    {
        // Play the pitch
        // +12 every cycle
        cycleIndex++;
        pitch => int localPitch;
        if (cycleIndex > cycle) {
            0 => cycleIndex;
            12 +=> localPitch;
        }
        bass.midi(localPitch);

        // Trigger pinwheel
        bass.noteOn(gain);
        // 5::second => now;
        // bass.noteOff();

    }
}