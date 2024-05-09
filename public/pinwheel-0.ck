//---------------------------------------------------------
// Wind Pad - Pinwheel
//---------------------------------------------------------

class WindPad extends Chugraph
{
    // Pad
    4 => int NUM_VOICES;
    SinOsc osc[NUM_VOICES];
    ADSR adsr => Gain g(1.0 / (3*NUM_VOICES)) => NRev rev => outlet;
    float pitches[NUM_VOICES];

    rev.mix(0.2);
    adsr.set(1::second, 1::second, 0, 1::second);

    // Wind Noise
    Noise noise => HPF lpf => adsr;
    0.1 => float _noise_threshold;
    noise.gain(_noise_threshold);

    // default
    63 => pitches[0];
    63+4 => pitches[1];
    70+7 => pitches[1];
    63+12 => pitches[3];

    for (0 => int i; i < NUM_VOICES; ++i) {
        osc[i] => adsr;
    }

    fun void noteOn(float gain) 
    {
        // Update chord
        // Randomize inversion
        pitches[0] => Std.mtof => osc[0].freq;
        Math.random2(-1, 1) * 12 + pitches[1] => Std.mtof => osc[1].freq;
        Math.random2(-1, 1) * 12 + pitches[2] => Std.mtof => osc[2].freq;
        Math.random2(-1, 1) * 12 + pitches[3] => Std.mtof => osc[3].freq;
        adsr.keyOn();

        // Update Noise
        gain > _noise_threshold ? _noise_threshold => noise.gain : gain => noise.gain;
        lpf.freq(gain * 10000); // scale freq with gain
    }

    fun void noteOff() 
    {
        adsr.keyOff();
    }

    // midi notes for 3 voices
    fun void midi(int m1, int m2, int m3) {
        m1 => pitches[0];
        m2 => pitches[1];
        m3 => pitches[2];
        m1+12 => pitches[3];
    }

    // midi notes for 4 voices
    fun void midi(int m1, int m2, int m3, int m4) {
        m1 => pitches[0];
        m2 => pitches[1];
        m3 => pitches[2];
        m4 => pitches[3];
    }

    fun void freq(float freq) 
    {
        // 1, 3, 5, 8
        freq => Std.ftom => float root;
        root => pitches[0];
        // Std.mtof(Std.ftom(freq) + 4) => pitches[1];
        // Std.mtof(Std.ftom(freq) + 7) => pitches[2];
        // Std.mtof(Std.ftom(freq) + 12) => pitches[3];
    }

    fun float freq() 
    {
        return osc[0].freq();
    }
}


//---------------------------------------------------------
// PINWHEEL Wind WindPad
//---------------------------------------------------------
public class Pinwheel
{
    WindPad pad => NRev rev => dac; // background ostinato
    rev.mix(0.1);

    // Variables
    63 => int keyCenter;
    [keyCenter, keyCenter, keyCenter, keyCenter] @=> int pitches[];
    0 => int scoreIndex;
    [0, 2, 4, 5, 7, 9, 11, 
    12, 14, 16, 17, 19, 21, 23] @=> int major[];

    // WIND PAD SCORE
    // (8 + 8 + 4) = 20 * 2
    [ [0,2,4], [0,2,4],
      [4,6,8], [4,6,8],
      [0,2,4], [0,2,4],
      [4,6,8], [4,6,8],
      [0,2,4], [0,2,4],
      [3,5,7], [3,5,7],
      [0,2,4], [0,2,4],
      [4,6,8], [4,6,8],

      [5,7,9], [5,7,9],
      [3,5,7,9], [3,5,7,9],
      [2,4,6,8], [2,4,6,8],
      [1,3,5,7], [1,3,5,7],
      [0,2,4,6], [0,2,4,6],
      [3,5,7,9], [3,5,7,9],
      [0,2,4,6], [0,2,4,6],
      [4,6,8,10], [4,6,8,10],

      [0,2,4], [1,3,5],
      [2,4,6], [3,5,7],
      [4,6,8], [5,7,9],
      [6,8,10], [7,9,11] ] @=> int score[][];

    // Set the key center
    fun void setKeyCenter(int midi) 
    {
        midi => keyCenter; 
    }

    fun void updateScore(int newIndex) {
        newIndex => scoreIndex;
        // Update chord pitches
        if (score[newIndex].size() == 3) {
            pad.midi(
                keyCenter + major[score[newIndex][0]],
                keyCenter + major[score[newIndex][1]],
                keyCenter + major[score[newIndex][2]]);
        } else {
            pad.midi(
                keyCenter + major[score[newIndex][0]],
                keyCenter + major[score[newIndex][1]],
                keyCenter + major[score[newIndex][2]],
                keyCenter + major[score[newIndex][3]]);
        }
    }

    // Trigger the pinwheel and cycle the index
    fun void blow(float gain, int bladeIndex) 
    {
        // Trigger pinwheel
        pad.noteOn(gain);
        2::second => now;
        pad.noteOff();
    }
}