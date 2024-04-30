//---------------------------------------------------------
// title: MicTrack 
// desc: Track microphone RMS and pitch
// author: terry feng
//---------------------------------------------------------

public class MicTrack
{
    float _freq;
    float _dbfs;
    float _threshold;

    512 => int WINDOW_SIZE;
    // Blowing gain detection (RMS)
    adc => HPF hpf => FFT fft =^ RMS rms => blackhole;
    hpf.freq(5000); 
    WINDOW_SIZE => fft.size;
    Windowing.hann(WINDOW_SIZE) => fft.window;

    // Pitch detection
    adc => LPF lpf => Flip flip =^ AutoCorr corr => blackhole;
    lpf.freq(5000);
    WINDOW_SIZE => flip.size;
    true => corr.normalize;
    second/samp => float sr;

    440 => _freq;
    -60 => _dbfs;
    -30 => _threshold;

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

    // Return pitch track frequency
    fun float getFreq() {
        return _freq;
    }

    // Set new threshold
    fun void setThreshold(float threshold) 
    {
        threshold => _threshold;
    }

    // START MICROPHONE TRACKING
    fun void start() {
        UAnaBlob blob;
        while (true)
        {
            // Get RMS
            rms.upchuck() @=> blob;
            blob.fval(0) => float rms;
            20 * Math.log10(rms / .0025) => _dbfs;

            // Get pitch
            corr.upchuck();
            // Ignore bins for notes that are too high
            (sr/Std.mtof(90)) $ int => int maxBin;
            float mag;
            for ( maxBin => int bin; bin < corr.fvals().size()/2; ++bin) {
                if (corr.fval(bin) > corr.fval(maxBin)) {
                    bin => maxBin;
                    corr.fval(bin) => mag;
                }
            }
            if (mag > 0.5) {
                // Update pitch if above correlation mag threshold
                sr/maxBin => _freq;
            }

            WINDOW_SIZE::samp => now;
        }
    }

    spork ~ start();
}