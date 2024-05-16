import { chuckGain } from "./host";
import { consoleDisabled, toggleConsole } from "./utils/print";

const menuButton = document.getElementById("menu-button")! as HTMLButtonElement;
const menuDialog = document.getElementById("menu-dialog")! as HTMLDialogElement;
const closeButton = document.getElementById("close-dialog")! as HTMLButtonElement;

const volumeSlider = document.getElementById("volume-slider")! as HTMLInputElement;
const loggingCheckbox = document.getElementById("logging-checkbox")! as HTMLInputElement;

// parse to int
const volume = localStorage["volume"] ? parseInt(localStorage["volume"]) : 100;

export function initMenu() {
    menuButton.addEventListener("click", () => {
        menuDialog.showModal();
    });

    closeButton.addEventListener("click", () => {
        menuDialog.close();
    });

    menuDialog.addEventListener("mousedown", (e) => {
        if (e.target === menuDialog) {
            menuDialog.close();
        }
    });

    // Initialize slider
    volumeSlider.value = volume.toString();
    volumeSlider.oninput = () => {
        setVolume(parseInt(volumeSlider.value));
    };

    // Initialize logging checkbox
    loggingCheckbox.checked = !consoleDisabled;
    loggingCheckbox.onchange = () => {
        toggleConsole();
    };
}

function setVolume(volume: number) {
    chuckGain.gain.value = volume / 100;
    localStorage["volume"] = volume;
}