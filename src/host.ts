//--------------------------------------------
// title: Host
// desc:  Everything Web Audio API related
//
// author: terry feng
// date:   Feb 2024
//--------------------------------------------

import { Chuck } from "webchuck";
import { cout } from "./utils/print";
import Settings, { BG_COLORS } from "./settings";
import { startVisualizer } from "./utils/visualizer";

let theChuck: Chuck;
let audioContext: AudioContext;
let adc: MediaStreamAudioSourceNode;
let micGain: GainNode;
let chuckGain: GainNode;
let analyser: AnalyserNode;
export { theChuck, chuckGain };

const PIECE_LENGTH = 6; // minutes

// FILES TO LOAD INTO CHUCK
const preloadFiles = [
    "aah.wav",
    "main.ck",
    "clock.ck",
    "micTrack.ck",
    "pinwheel-bass.ck",
    "pinwheel-wind.ck",
    "pinwheel-chime.ck",
    "pinwheel-bamboo.ck",
    "pinwheel-voice.ck",
    "pinwheel-drift.ck",
];

const filesToPreload = preloadFiles.map((f) => {
    return {
        serverFilename: `./${f}`,
        virtualFilename: f,
    };
});

/**
 * Background initialization of theChuck
 * @param startButton
 */
export async function initChuck(startButton: HTMLButtonElement) {
    audioContext = new AudioContext();
    audioContext.suspend();
    micGain = audioContext.createGain();
    micGain.gain.value = 1.0;
    chuckGain = audioContext.createGain();
    chuckGain.gain.value = 1.0;

    // connect micGain to analyser
    analyser = audioContext.createAnalyser();
    micGain.connect(analyser);

    startButton.disabled = true;
    startButton.innerText = "Loading...";

    // Preload Chuck Chugins (WebChugin)
    Chuck.loadChugin("chugins/GVerb.chug.wasm");

    // Create theChuck
    theChuck = await Chuck.init(
        filesToPreload,
        audioContext,
        audioContext.destination.maxChannelCount,
    );
    theChuck.connect(chuckGain).connect(audioContext.destination);

    // Microphone setup
    cout("Probing Microphones:", "green", false);
    navigator.mediaDevices.enumerateDevices().then(function (devices) {
        devices.forEach(function (device) {
            if (device.kind === "audioinput") {
                cout(
                    device.kind +
                        ": " +
                        device.label +
                        " id = " +
                        device.deviceId,
                    undefined,
                    false,
                );
            }
        });
    });

    (window as any).theChuck = theChuck;

    readyChuck(startButton);
}

/**
 * Called when theChuck is ready
 */
export function readyChuck(startButton: HTMLButtonElement) {
    startButton.innerText = "Start";
    startButton.disabled = false;
}

/**
 * Start theChuck
 */
export async function startChuck(
    startButton: HTMLButtonElement,
): Promise<void> {
    // Connect microphone
    navigator.mediaDevices
        .getUserMedia({
            video: false,
            audio: {
                // echoCancellation: false,
                autoGainControl: false,
                noiseSuppression: false,
            },
        })
        .then((stream) => {
            cout("Microphone Connected", "green", true);
            adc = audioContext.createMediaStreamSource(stream);
            adc.connect(micGain).connect(theChuck);
        });
    setupMicGainSlider();
    audioContext.resume();
    startButton.innerHTML = "Syncing...";

    await theChuck.runFile("clock.ck");
    await theChuck.runFile("micTrack.ck");
    await theChuck.runFile(`pinwheel-${Settings.instName}.ck`);
    cout("Initializing Pinwheel:", BG_COLORS[Settings.instIndex], true);
    cout(`pinwheel-${Settings.instName}.ck`);
    await theChuck.runFile("main.ck");

    await new Promise((resolve) => setTimeout(resolve, 1000));
    const currentSecond = sync(PIECE_LENGTH); // Sync from a 6 minute time interval
    console.log(`Starting at ${currentSecond} / ${PIECE_LENGTH * 60}`);
    theChuck.setInt("COUNT", currentSecond);
    theChuck.broadcastEvent("START");

    startButton.innerHTML = "BLOW!";

    startInputMonitor();
    startVisualizer(analyser);
}

/**
 * Monitor the input, display RMS
 */
function startInputMonitor() {
    // Draw RMS meter in DBFS to Canvas
    const canvas = document.getElementById("input-meter") as HTMLCanvasElement;
    const ctx = canvas.getContext("2d")!;
    const WIDTH = canvas.width;
    const HEIGHT = canvas.height;

    const freq = document.getElementById("freq") as HTMLSpanElement;
    const db = document.getElementById("dbfs") as HTMLSpanElement;

    setInterval(() => {
        // Canvas Meter
        theChuck.getFloat("MIC_MAG").then((mag) => {
            ctx.clearRect(0, 0, WIDTH, HEIGHT);
            ctx.fillStyle = `green`;
            ctx.fillRect(0, 0, mag * WIDTH, HEIGHT);
        });

        // Monitor Mic
        theChuck.getFloat("MIC_FREQ").then((f) => {
            freq.innerHTML = `${f.toFixed(2)} Hz`;
        });
        theChuck.getFloat("MIC_DBFS").then((dbfs) => {
            db.innerHTML = `${dbfs.toFixed(2)} dB`;
        });
    }, 30);
}

/**
 * Setup the mic gain slider
 */
function setupMicGainSlider() {
    const slider = document.getElementById("mic-gain") as HTMLInputElement;
    micGain.gain.value = (2 * parseFloat(slider.value)) / 100;
    slider.oninput = () => {
        micGain.gain.value = (2 * parseFloat(slider.value)) / 100;
    };
}

/**
 * helper function to get the current second of several minutes
 */
function sync(minutes: number) {
    let currentSecond = 0;
    // get current time
    let currentTime = new Date().getTime();
    while (currentTime % 1000 !== 0) {
        currentTime = new Date().getTime();
    }
    // Get the current second
    currentSecond = (currentTime % (minutes * 60 * 1000)) / 1000;

    return currentSecond;
}
