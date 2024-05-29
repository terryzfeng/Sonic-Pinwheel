import Pinwheel from "./pinwheel";
import { cout } from "./utils/print";

let midi: MIDIAccess;
let midiOutput: MIDIOutput;
let teensyId: string;
let pinwheelRef: Pinwheel;
let isOn = false;

function onMIDISuccess(midiAccess: MIDIAccess)  {
    midi = midiAccess; // store in the global (in real usage, would probably keep in an object instance)
    cout("Probing MIDI devices:", "green", false);
    for (const entry of midi.outputs) {
        const output = entry[1];
        cout( `Output port [type:'${output.type}'] id: '${output.id}' manufacturer: '${output.manufacturer}' name: '${output.name}' version: '${output.version}'`,);
        if (output.name === "Teensy MIDI") {
            teensyId = output.id;
            cout("Teensy MIDI connected: " + teensyId);
            midiOutput = midi.outputs.get(teensyId)!;
        }
    }

    if (!midiOutput) {
        cout("Could not find Teensy MIDI");
        return;
    }
    
    setInterval(() => {
        const vel = pinwheelRef.getAngularVelocity(); // 0-4PI
        if (vel > Math.PI && !isOn) {
            noteOn();
        } else if (vel <= Math.PI && isOn) {
            noteOff();
        }
        console.log(isOn);
    }, 250);

    // Initial MIDI off
    noteOff();
}

function noteOn() {
    const noteOnMessage = [0x90, 60, 0x7f]; // note on middle C, full velocity
    midiOutput.send(noteOnMessage); //omitting the timestamp means send immediately.
    isOn = true;
}

function noteOff() {
    midiOutput.send([0x80, 60, 0x40]);
    isOn = false;
}

function onMIDIFailure(msg: string) {
    cout(`Failed to get MIDI access to Teensy: ${msg}`);
}

export function initMidi(pinwheel: Pinwheel) {
    pinwheelRef = pinwheel;
    navigator.requestMIDIAccess().then(onMIDISuccess, onMIDIFailure);
}
