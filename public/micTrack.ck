//---------------------------------------------------------
// MICROPHONE TRACKING
//---------------------------------------------------------
public class MicTrack 
{
    float _dbfs;
    float _threshold;
    dur _period;

    adc => Gain micInput;
    micInput => Gain g => OnePole p => blackhole;
    micInput => g; // square input
    3 => g.op; // multiple
    .9 => p.pole;

    // default 
    20::ms => _period;
    -60 => _dbfs;
    -20 => _threshold;

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

    // Set new threshold
    fun void setThreshold(float threshold) 
    {
        threshold => _threshold;
    }

    // Set mic gain
    fun void gain(float gain) 
    {
        gain => micInput.gain;
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
}