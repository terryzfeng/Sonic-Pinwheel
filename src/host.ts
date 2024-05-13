//--------------------------------------------
// title: Host
// desc:  Everything Web Audio API related
//
// author: terry feng
// date:   Feb 2024
//--------------------------------------------

import { Chuck } from "webchuck";
import Settings from "./settings";
import { cout } from "./utils/print";
import { startVisualizer } from "./utils/visualizer";

let theChuck: Chuck;
let audioContext: AudioContext;
let adc: MediaStreamAudioSourceNode;
let micGain: GainNode;
let analyser: AnalyserNode;
export { theChuck };

const PIECE_LENGTH = 6; // minutes

// FILES TO LOAD INTO CHUCK
const preloadFiles = [
    "main.ck",
    "clock.ck",
    "micTrack.ck",
    "pinwheel-bass.ck",
    "pinwheel-wind.ck",
    "pinwheel-chime.ck",
    "pinwheel-2.ck",
    "pinwheel-3.ck",
    "pinwheel-4.ck",
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

    // connect micGain to analyser
    analyser = audioContext.createAnalyser();
    micGain.connect(analyser);

    startButton.disabled = true;
    startButton.innerText = "Loading...";

    // Create theChuck
    Chuck.loadChugin("chugins/GVerb.chug.wasm");
    theChuck = await Chuck.init(
        filesToPreload,
        audioContext,
        audioContext.destination.maxChannelCount,
    );
    theChuck.connect(audioContext.destination);

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
            adc = audioContext.createMediaStreamSource(stream);
            adc.connect(micGain).connect(theChuck);
        });

    // Microphone setup
    cout("Probing Microphones:", "green");
    navigator.mediaDevices.enumerateDevices().then(function (devices) {
        devices.forEach(function (device) {
            if (device.kind === "audioinput") {
                cout(
                    device.kind +
                        ": " +
                        device.label +
                        " id = " +
                        device.deviceId,
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
    audioContext.resume();
    startButton.innerHTML = "Syncing...";

    await theChuck.runFile("clock.ck");
    await theChuck.runFile("micTrack.ck");
    await theChuck.runFile(`pinwheel-${Settings.instName}.ck`);
    await theChuck.runFile("main.ck");

    await new Promise((resolve) => setTimeout(resolve, 1000));
    const currentSecond = sync(PIECE_LENGTH); // Sync from a 6 minute time interval
    console.log(`Starting at ${currentSecond} / ${PIECE_LENGTH * 60}`);
    theChuck.setInt("COUNT", currentSecond);
    theChuck.broadcastEvent("START");


    startButton.innerHTML = "BLOW!";

    startInputMonitor();
    setupMicGainSlider();
    startVisualizer(analyser);
}

/**
 * Monitor the input, display RMS
 */
function startInputMonitor() {
    // draw a RMS meter in DBFS
    const canvas = document.getElementById("input-meter") as HTMLCanvasElement;
    const ctx = canvas.getContext("2d")!;
    const WIDTH = canvas.width;
    const HEIGHT = canvas.height;
    setInterval(() => {
        const db = document.getElementById("dbfs") as HTMLDivElement;
        const freq = document.getElementById("freq") as HTMLDivElement;
        theChuck.getFloat("MIC_MAG").then((mag) => {
            ctx.clearRect(0, 0, WIDTH, HEIGHT);
            ctx.fillStyle = `green`;
            ctx.fillRect(0, 0, mag * WIDTH, HEIGHT);
        });
        theChuck.getFloat("MIC_FREQ").then((f) => {
            // dbfs to log scale
            freq.innerHTML = f.toFixed(2);
        });
        theChuck.getFloat("MIC_DBFS").then((dbfs) => {
            db.innerHTML = dbfs.toFixed(2);
        });
    }, 30);
}

/**
 * Setup the mic gain slider
 */
function setupMicGainSlider() {
    const slider = document.getElementById("mic-gain") as HTMLInputElement;
    slider.value = "50";
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
