//---------------------------------------------------------
// Bass Pinwheel
//---------------------------------------------------------

class Bass extends Chugraph
{
    SawOsc osc => Gain g => ADSR adsr => LPF lpf => JCRev rev => outlet;

    osc.gain(0.6);
    adsr.set(10::ms, 200::ms, 0, 0::ms);
    rev.mix(0.06);

    24 => int SUB;
    7 => int FIFTH;

    63 => int pitch;
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
        osc.freq(Std.mtof(pitch-SUB));
        lpf.freq(Std.mtof(pitch-SUB+FIFTH));
    }

    fun void freq(float freq) 
    {
        osc.freq(freq);
        lpf.freq(Std.mtof(Std.ftom(freq) + FIFTH));
    }

    fun float freq() 
    {
        return osc.freq();
    }
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

    // BASS SCORE (40 NOTES)
    [ 0, 0, 5, 5, 0, 0, 5, 5,
      0, 0, 4, 4, 0, 0, 5, 5,
      6, 6, 4, 4, 3, 3, 2, 2, 
      1, 1, 4, 4, 1, 1, 5, 5,
      1, 2, 3, 4, 5, 6, 7, 8 ] @=> int score[];

    // Set the key center
    fun void setKeyCenter(int midi) 
    {
        midi => keyCenter; 
    }

    fun void updateScore(int newIndex) {
        newIndex => scoreIndex;
        keyCenter + score[scoreIndex] => pitch;
    }

    // Trigger the pinwheel
    fun void blow(float gain, int bladeIndex) 
    {
        // Update pitch
        // Occasionally + octave
        Math.random2f(0,1) > 0.9 ? pitch + 12 : pitch => int localPitch;
        bass.midi(localPitch);
        // Trigger pinwheel
        bass.noteOn(gain);
        500::second => now;
        bass.noteOff();
    }
}