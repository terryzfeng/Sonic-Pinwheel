//---------------------------------------------------------
// Pingpong delay effect
//---------------------------------------------------------
class PingPong extends Chugraph {
    inlet => outlet;
    inlet => DelayL dL => Gain fbL => outlet;
    inlet => DelayL dR => Delay dR2 => Gain fbR => outlet;
    fbL => dL;
    fbR => dR;

    .25::second => dL.max => dL.delay;
    .25::second => dR.max => dR.delay;
    .25::second => dR2.max => dR2.delay;

    // .64 => fbL.gain; // set feedback
    .47 => dL.gain; // set effects mix

    // .64 => fbR.gain; // set feedback
    .47 => dR.gain; // set effects mix
    .47 => dR2.gain; // set effects mix
}

//---------------------------------------------------------
// Drift - Pinwheel
//---------------------------------------------------------
class Drift extends Chugraph {
    8 => int NUM_VOICES;
    SawOsc osc[NUM_VOICES]; TriOsc osc2[NUM_VOICES];
    ADSR adsr1[NUM_VOICES]; ADSR adsr2[NUM_VOICES];
    BPF bpf[NUM_VOICES];
    SinOsc lfo[NUM_VOICES] => blackhole;
    Pan2 pan[NUM_VOICES];
    Pan2 master => Pan2 control => dac;
    float freqs[NUM_VOICES];


    control.chan(0) => outlet;
    control.chan(1) => outlet;

    // Inititialize
    master.gain(3.2);
    for (0 => int i; i < NUM_VOICES; i++) {
        osc[i].gain(1.0/(4*NUM_VOICES));
        osc2[i].gain(1.0/(NUM_VOICES));
        Math.random2f(0,4) => lfo[i].freq;
        440 => freqs[i] => osc[i].freq => osc2[i].freq;
        bpf[i].freq(440);
        bpf[i].Q(1.5);

        1 => pan[i].panType;
        Math.random2f(-1,1) => pan[i].pan;

        adsr1[i].set(3.57::ms, .8::second, 0, 0.3::second);
        adsr2[i].set(0::ms, 1.2::second, 0, .5::second);

        osc[i] => adsr1[i] => bpf[i];
        osc2[i] => adsr2[i] => bpf[i];
        bpf[i] => pan[i] => master;
    }

    fun void noteOn(float gain) {
        gain => control.gain;
        for (0 => int i; i < NUM_VOICES; ++i) {
            adsr1[i].keyOn();
            adsr2[i].keyOn();
        }
    }

    fun void noteOff() {
        for (0 => int i; i < NUM_VOICES; ++i) {
            adsr1[i].keyOff();
            adsr2[i].keyOff();
        }
    }

    fun void midi(int note) {
        for (0 => int i; i < NUM_VOICES; i++) {
            Std.mtof(note) => freqs[i];
        }
        Std.mtof(note+12) => bpf.freq; 
    }

    fun float midi() {
        return Std.ftom(freqs[0]);
    }

    fun void lfoDrift() {
        while (true) {
            for (0 => int i; i < NUM_VOICES; i++) {
                freqs[i] + Math.random2(-10,10) * lfo[i].last() => osc[i].freq;
                freqs[i] + Math.random2(-2,2) * lfo[i].last() => osc2[i].freq;
            }
            50::ms => now;
        }
    }
    spork ~ lfoDrift();
}

//---------------------------------------------------------
// PINWHEEL Drift
//---------------------------------------------------------
public class Pinwheel
{
    Drift drift;
    drift.gain(0.8);
    drift => PingPong p => dac;

    // Variables
    63 => int keyCenter;
    keyCenter => int pitch;
    0 => int scoreIndex;

    // Drift SCORE (2 modes: Scale or Pentatonic)
    // relative to key center
    [0, 2, 4, 5, 7, 9, 11, 12, 14, 16] @=> int major[];
    // startIndices: 0, 2, or 5
    [-10, -8,
     -7, -5, -3,
     0, 2, 4, 7, 11, 12, 14, 16] @=> int pentatonic[]; // + major 7
    0 => int mode; // 0 = major, 1 = pentatonic
    major.size() => int currLength;
    0 => int cycleIndex;
    0 => int cycleStart;

    // Set the key center
    fun void setKeyCenter(int midi) 
    {
        midi => keyCenter; 
    }

    fun void updateScore(int newIndex) {
        newIndex => scoreIndex;
        // Update which mode we are in based on score position
        // Major Mode
        if (scoreIndex == 0 || scoreIndex >= 32) {
            0 => mode;
            major.size() - Math.random2(0,2) => currLength;
            0 => cycleStart;
        } else {
        // Pentatonic Mode
            1 => mode;
            0 => cycleIndex;
            pentatonic.size() => currLength;
            if (scoreIndex % 3 == 0 || scoreIndex % 4 == 0) {
                0 => cycleStart; // Reset to 0
            }
            if (scoreIndex % 5 == 0 || scoreIndex % 6 == 0) {
                2 => cycleStart; // Reset to 2
            } else {
                5 => cycleStart; // Reset to 5
            }
        }
    }

    // Increment the cycle index
    fun void incCycle() {
        // Scale
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

    // Trigger the pinwheel, play a drift note
    fun void blow(float gain, int bladeIndex) 
    {
        Math.min(1, gain) => gain;
        // Play the pitch
        if (mode == 0) {
            drift.midi(keyCenter + major[cycleIndex]);
        } else {
            drift.midi(keyCenter + pentatonic[cycleIndex]);
        }
        drift.noteOn(gain);
        incCycle();
        200::ms => now;
    }
}