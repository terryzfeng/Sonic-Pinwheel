import Pinwheel from "./pinwheel";

let midi: MIDIAccess;
let teensyId: string;
let pinwheelRef: Pinwheel;
let isOn = false;

function onMIDISuccess(midiAccess: MIDIAccess)  {
    console.log("MIDI ready!");
    midi = midiAccess; // store in the global (in real usage, would probably keep in an object instance)
    for (const entry of midi.outputs) {
        const output = entry[1];
        //console.log( `Output port [type:'${output.type}'] id: '${output.id}' manufacturer: '${output.manufacturer}' name: '${output.name}' version: '${output.version}'`,);
        if (output.name === "Teensy MIDI") {
            teensyId = output.id;
            console.log("teensyId", teensyId);
        }
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

    // Send initial note off
    noteOff();
}

function noteOn() {
    isOn = true;
    const noteOnMessage = [0x90, 60, 0x7f]; // note on middle C, full velocity
    const output = midi.outputs.get(teensyId)!;
    output.send(noteOnMessage); //omitting the timestamp means send immediately.
}

function noteOff() {
    isOn = false;
    const output = midi.outputs.get(teensyId)!;
    output.send([0x80, 60, 0x40]);
}

function onMIDIFailure(msg: string) {
    console.error(`Failed to get MIDI access - ${msg}`);
}

export function initMidi(pinwheel: Pinwheel) {
    pinwheelRef = pinwheel;
    navigator.requestMIDIAccess().then(onMIDISuccess, onMIDIFailure);
}
