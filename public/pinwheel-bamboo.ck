global float MIC_FREQ;

//---------------------------------------------------------
// Bamboo - Pinwheel
//---------------------------------------------------------
class Bamboo extends Chugraph
{
    Shakers shake => Dyno d => JCRev rev => outlet;
    .001 => rev.mix;

    // Trickly kind of shaker
    shake.which(22);

    // Compressor
    d.compress();
    2000::ms => d.releaseTime;
    0.2 => d.thresh;
    0.33 => d.slopeAbove;
    8 => d.gain;

    fun void noteOn(float gain) 
    {
        // Inverse gain to number of objects, max 30
        30 - (29*gain) => shake.objects;
        gain * 2 => shake.noteOn;
    }

    fun void noteOff() { 
        shake.noteOff(.1);
    }

    fun void freq(float freq) 
    {
        freq => shake.freq;
    }

    fun float freq() 
    {
        return shake.freq();
    }
}

//---------------------------------------------------------
// PINWHEEL Bamboo 
//---------------------------------------------------------
public class Pinwheel
{
    Bamboo bamboo => JCRev revL => dac; 
    revL.mix(0.01);

    // Variables
    63 => int keyCenter;

    // Set the key center
    fun void setKeyCenter(int midi) 
    {
        // low instrument (but actually isn't used)
        midi - 24 => keyCenter; 
    }

    // bamboo doesn't follow the score
    fun void updateScore(int newIndex) {}

    // Trigger the pinwheel and cycle the index
    fun void blow(float gain, int bladeIndex) 
    {
        // shift 1 octave down
        MIC_FREQ * 0.5 => float currFreq;
        currFreq => bamboo.freq;

        // Trigger pinwheel
        bamboo.noteOn(gain);

        // When closer to 0, the bamboo rings for longer
        // Otherwise don't note off as it will clip
        if (gain < 0.5) {
            ((1-gain)*500)::ms => now;
            bamboo.noteOff();
        } 
    }

}