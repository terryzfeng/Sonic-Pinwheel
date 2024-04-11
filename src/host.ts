//--------------------------------------------
// title: Host
// desc:  Everything Web Audio API related
//
// author: terry feng
// date:   Feb 2024
//--------------------------------------------

import { Chuck } from "webchuck";
import Settings from "./settings";

let theChuck: Chuck;
let audioContext: AudioContext;

export { theChuck };

export async function initChuck(startButton: HTMLButtonElement) {
    startButton.innerText = "Loading...";
    startButton.disabled = true;
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
                serverFilename: "./main.ck",
                virtualFilename: "main.ck",
            },
        ],
        undefined,
        2,
        "./src/",
    );
    // theChuck.connect(audioContext.destination);
    audioContext = theChuck.context as AudioContext;

    // Connect microphone
    navigator.mediaDevices
        .getUserMedia({
            video: false,
            audio: {
                // echoCancellation: false,
                // autoGainControl: false,
                noiseSuppression: false,
            },
        })
        .then((stream) => {
            const adc = audioContext.createMediaStreamSource(stream);
            const gain = audioContext.createGain();
            adc.connect(gain).connect(theChuck);
        });

    (window as any).theChuck = theChuck;

    // readyChuck(startButton);
}

/**
 * Called when theChuck is ready
 */
// export function readyChuck(startButton: HTMLButtonElement) {
//     startButton.innerText = "Start";
//     startButton.disabled = false;
// }

/**
 * Start theChuck
 */
export async function startChuck(
    startButton: HTMLButtonElement,
): Promise<void> {
    audioContext.resume();
    await new Promise((resolve) => setTimeout(resolve, 500));
    await theChuck.runFile("clock.ck");
    await new Promise((resolve) => setTimeout(resolve, 1000));
    const currentSecond = sync();
    theChuck.setInt("COUNT", currentSecond);
    theChuck.broadcastEvent("START");

    await theChuck.runFile("micTrack.ck");
    switch (Settings.instIndex) {
    case 0: 
        await theChuck.runFile("pinwheel0.ck");
        break;
    
    case 1: 
        await theChuck.runFile("pinwheel1.ck");
        break;
    default: 
        await theChuck.runFile("pinwheel1.ck");
    }
    await theChuck.runFile("main.ck");

    startButton.innerHTML = "BLOW!";
}

/**
 * sync
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
