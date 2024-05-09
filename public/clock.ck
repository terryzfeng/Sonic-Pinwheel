global Event GLOBAL_TICK;
global Event START;
global Event READY;
global int COUNT;
-1 => COUNT;

public class Clock
{
    4 => int _bps; // beats per second
    360 => int _max_seconds; // max seconds of piece

    0 => int _beat; // current beat per second
    0 => int _second; // current second of piece
    0 => int _running; // is clock running

    // calculate
    1.0 / _bps => float _period; // in seconds
    _period::second => dur _period_dur;

    fun int getTick()
    {
        return _second * _bps + _beat;
    }

    fun int exactSecondIs(int currSecond)
    {
        return currSecond == _second && _beat == 0;
    }

    fun void start(int count) 
    {
        1 => _running;
        count => _second;
        while (_running)
        {
            // <<< _second, " : ", _beat >>>;
            GLOBAL_TICK.broadcast();
            _period_dur => now;
            _beat++;

            // wrap beat
            if (_beat == _bps)
            {
                0 => _beat;
                _second++;
            }
            // wrap second
            _second % _max_seconds => _second;
        }
    }
    
    fun void stop() 
    {
        0 => _running;
    }
}

global Clock clock;

// TRIGGERED FROM JS
// while (COUNT < 0) { 10::ms => now; }
// <<< COUNT >>>;
START => now;
spork ~ clock.start(COUNT);
READY.broadcast();
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
