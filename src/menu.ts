import { chuckGain, setSelectedMicrophoneId } from "./host";
import { consoleDisabled, toggleConsole } from "./utils/print";

const menuButton = document.getElementById("menu-button")! as HTMLButtonElement;
const menuDialog = document.getElementById("menu-dialog")! as HTMLDialogElement;
const closeButton = document.getElementById(
    "close-dialog",
)! as HTMLButtonElement;

const volumeSlider = document.getElementById(
    "volume-slider",
)! as HTMLInputElement;
const loggingCheckbox = document.getElementById(
    "logging-checkbox",
)! as HTMLInputElement;
const microphoneSelect = document.getElementById(
    "microphone-select",
)! as HTMLSelectElement;

// parse to int
const volume = localStorage["volume"] ? parseInt(localStorage["volume"]) : 100;

export function initMenu() {
    menuButton.addEventListener("click", () => {
        menuDialog.showModal();
        populateMicrophoneSelect();
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
    setVolume(volume);

    // Initialize logging checkbox
    loggingCheckbox.checked = !consoleDisabled;
    loggingCheckbox.onchange = () => {
        toggleConsole();
    };

    // Initialize microphone select
    microphoneSelect.onchange = () => {
        setSelectedMicrophoneId(microphoneSelect.value);
    };
}

export function disableMicrophoneSelect() {
    microphoneSelect.disabled = true;
}

function setVolume(volume: number) {
    chuckGain.gain.value = volume / 100;
    localStorage["volume"] = volume;
}

async function populateMicrophoneSelect() {
    try {
        const devices = await navigator.mediaDevices.enumerateDevices();
        const audioInputs = devices.filter((device) => device.kind === "audioinput");

        // Clear existing options except the first one
        while (microphoneSelect.options.length > 1) {
            microphoneSelect.remove(1);
        }

        // Add each microphone as an option
        audioInputs.forEach((device) => {
            const option = document.createElement("option");
            option.value = device.deviceId;
            option.textContent = device.label || `Microphone ${device.deviceId.substring(0, 5)}`;
            microphoneSelect.appendChild(option);
        });

        // Restore previous selection if it exists
        const savedMicId = localStorage["selectedMicrophoneId"];
        if (savedMicId) {
            microphoneSelect.value = savedMicId;
        }
    } catch (error) {
        console.error("Error enumerating audio devices:", error);
    }
}
