const out = document.getElementById("console")!;
const messages: (string | number)[] = [];

export function cout(msg: string | number, color: string = "#444") {
    const coloredMsg = `<span style="color: ${color};">${msg}</span>`;
    messages.push(coloredMsg);

    // Only keep the last 100 messages
    if (messages.length > 100) {
        messages.shift();
    }

    // Display the messages
    out.innerHTML = messages.join("<br>");
}
