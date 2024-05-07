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
    theChuck = await Chuck.init(
        [
            {
                serverFilename: "./clock.ck",
                virtualFilename: "clock.ck",
            },
            {
                serverFilename: "./micTrack.ck",
                virtualFilename: "micTrack.ck",
            },
            {
                serverFilename: "./pinwheel0.ck",
                virtualFilename: "pinwheel0.ck",
            },
            {
                serverFilename: "./pinwheel1.ck",
                virtualFilename: "pinwheel1.ck",
            },
            {
                serverFilename: "./pinwheel2.ck",
                virtualFilename: "pinwheel2.ck",
            },
            {
                serverFilename: "./main.ck",
                virtualFilename: "main.ck",
            },
        ],
        audioContext,
        audioContext.destination.maxChannelCount,
        "./src/",
    );
    theChuck.connect(audioContext.destination);

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
    await new Promise((resolve) => setTimeout(resolve, 500));
    await theChuck.runFile("clock.ck");
    await new Promise((resolve) => setTimeout(resolve, 1000));
    const currentSecond = sync();
    theChuck.setInt("COUNT", currentSecond);
    theChuck.broadcastEvent("START");

    await theChuck.runFile("micTrack.ck");
    await theChuck.runFile(`pinwheel${Settings.instIndex}.ck`);
    await theChuck.runFile("main.ck");

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
        theChuck.getFloat("MIC_DBFS").then((dbfs) => {
            // dbfs to log scale
            db.innerHTML = dbfs.toFixed(2);
            // [-70, -20] => [0, 1]
            const scale = (dbfs + 70) / 60;
            ctx.clearRect(0, 0, WIDTH, HEIGHT);
            ctx.fillStyle = `green`;
            ctx.fillRect(0, 0, scale * WIDTH, HEIGHT);
        });
        theChuck.getFloat("MIC_FREQ").then((f) => {
            // dbfs to log scale
            freq.innerHTML = f.toFixed(2);
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
 * helper function to sync down to the second
 */
function sync() {
    let currentSecond = 0;
    // get current time
    let currentTime = new Date().getTime();
    while (currentTime % 1000 !== 0) {
        currentTime = new Date().getTime();
    }
    // Get the current second
    currentSecond = (currentTime % (60 * 1000)) / 1000;

    return currentSecond;
}
