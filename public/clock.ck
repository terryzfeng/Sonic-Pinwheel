global Event GLOBAL_TICK;
global Event START;
global int COUNT;
-1 => COUNT;

public class Clock
{
    1.0 => float _period; // in seconds

    0 => int _tick_count;
    0 => int _second_count;

    .25::second => dur _period_dur;
    (1::second / _period_dur) $ int => int _ticks_per_second;
    0 => int _running;

    fun void start() 
    {
        1 => _running;
        COUNT => _tick_count;
        COUNT => _second_count;
        while (_running)
        {
            GLOBAL_TICK.broadcast();
            _tick_count++;
            <<< _tick_count >>>;
            if (_tick_count > 59)
            {
                0 => _tick_count;
            }

            if (_tick_count % _ticks_per_second == 0)
            {
                _second_count++;
                if (_second_count > 59)
                {
                    0 => _second_count;
                }
            }
            _period_dur => now;
        }
    }
    
    fun void stop() 
    {
        0 => _running;
    }
}

global Clock clock;

// TRIGGERED FROM JS
// while (COUNT < 0) { <<< "." >>>; 1::ms => now; }
// <<< COUNT >>>;
START => now;
spork~clock.start();
1::week => now;

// // Monitoring
// SinOsc osc => ADSR e => dac; // TODO
// osc.freq(1000);
// e.set(50::ms, 100::ms, 0, 100::ms); // TODO

// // Keep alive
// while (true)
// {
//     GLOBAL_TICK => now;
//     e.keyOn();
//     100::ms => now;
//     e.keyOff();
// }
