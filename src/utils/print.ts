const out = document.getElementById("console")!;
const messages: (string | number)[] = [];

const MAX_MESSAGES = 20;
export let consoleDisabled =
    localStorage["consoleDisabled"] === "true" || false; // TODO: Set to false to enable console

export function cout(
    msg: string | number,
    color: string = "#444",
    scroll: boolean = true,
) {
    if (consoleDisabled) {
        return;
    }

    const coloredMsg = `<span style="color: ${color};">${msg}</span>`;
    messages.push(coloredMsg);

    // Only keep the last MAX_MESSAGES
    if (messages.length > MAX_MESSAGES) {
        messages.shift();
    }

    // Display the messages
    out.innerHTML = messages.join("<br>");

    // Scroll to the bottom
    if (scroll) {
        out.scrollTop = out.scrollHeight;
    }
}

function disable() {
    out.style.display = "none";
    consoleDisabled = true;
    localStorage["consoleDisabled"] = "true";
}
function enable() {
    out.style.display = "block";
    consoleDisabled = false;
    localStorage["consoleDisabled"] = "false";
}

/**
 * Toggle the console
 */
export function toggleConsole() {
    if (consoleDisabled) {
        enable();
    } else {
        disable();
    }
}

// Disable console check
if (consoleDisabled) {
    disable();
}
