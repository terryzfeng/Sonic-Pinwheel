//--------------------------------------------
// title: Host
// desc:  Everything Web Audio API related
//
// author: terry feng
// date:   Feb 2024
//--------------------------------------------

import { Chuck } from "webchuck";

let theChuck: Chuck;
let audioContext: AudioContext;


export async function initChuck(startButton: HTMLButtonElement) {
    startButton.innerText = "Loading...";
    audioContext = new AudioContext();
    // Create theChuck
    theChuck = await Chuck.init(
        [
            {
                serverFilename: "./clock.ck",
                virtualFilename: "clock.ck",
            },
            {
                serverFilename: "./pinwheel.ck",
                virtualFilename: "pinwheel.ck",
            },
        ],
        audioContext,
        2,
        "./src/",
    );
    console.log(theChuck);
    theChuck.connect(audioContext.destination);
    audioContext.suspend();

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
    theChuck.runFile("clock.ck");
    await new Promise((resolve) => setTimeout(resolve, 100));
    await syncSetBroadcast("COUNT", "START");
    console.log("synced");
    theChuck.runFile("pinwheel.ck");

    startButton.innerHTML = "Running";
}

function syncSetBroadcast(variable: string, event: string) {
    const callbackID = theChuck.nextDeferID();
    theChuck.sendMessage("syncSetBroadcast", {
        variable,
        event,
        callback: callbackID,
    });
    return theChuck.deferredPromises[callbackID].value() as Promise<number>;
}

/**
 * sync
 */
// function sync() {
//     let currentSecond = 0;
//     // get current time
//     let currentTime = new Date().getTime();
//     while (currentTime % 1000 !== 0) {
//         currentTime = new Date().getTime();
//     }
//     // Get the current second
//     currentSecond = (currentTime % (60 * 1000)) / 1000;

//     return currentSecond;
// }
