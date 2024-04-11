const NUM_INSTRUCTIONS = 2;

const BG_COLORS = [
    "#ABEFCD",
    "#ABCDEF",
    "#CDEFAB",
];

export default class Settings {
    public static instButtons: HTMLInputElement[];
    public static pinwheelCanvas: HTMLCanvasElement;
    public static instIndex: number = 1;

    constructor(canvasId: string) {
        Settings.instButtons = Array.from(
            { length: NUM_INSTRUCTIONS },
            (_, i) => document.getElementById(`inst-${i}`) as HTMLInputElement,
        );
        Settings.pinwheelCanvas = document.getElementById(canvasId) as HTMLCanvasElement;

        Settings.instButtons.forEach((button, index) => {
            button.addEventListener("change", () => {
                if (button.checked) {
                    Settings.handleRadioButtonChange(index);
                }
            });
        });
    }

    private static handleRadioButtonChange(index: number) {
        Settings.pinwheelCanvas.style.backgroundColor = BG_COLORS[index];
        Settings.instIndex = index;
    }

    public static disableButtons() {
        Settings.instButtons.forEach((button) => {
            button.disabled = true;
        });
    }
}
