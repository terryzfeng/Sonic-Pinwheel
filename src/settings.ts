const NUM_INSTRUMENTS = 3;

const BG_COLORS = ["#ABEFCD", "#ABCDEF", "#CDABEF"];

export default class Settings {
    public static instDropdown: HTMLSelectElement;
    public static bgCanvas: HTMLCanvasElement;
    public static instIndex: number = 1;

    constructor(canvasId: string, dropdownId: string = "instruments") {
        Settings.instDropdown = document.getElementById(dropdownId) as HTMLSelectElement;
        Settings.bgCanvas = document.getElementById(canvasId) as HTMLCanvasElement;

        for (let i = 0; i < NUM_INSTRUMENTS; i++) {
            const option = document.createElement("option");
            option.value = i.toString();
            option.text = `Instrument ${i}`;
        }

        Settings.instDropdown.addEventListener("change", () => {
            const index = Settings.instDropdown.selectedIndex;
            Settings.handleDropdownChange(index);
        });
    }

    private static handleDropdownChange(index: number) {
        Settings.bgCanvas.style.backgroundColor = BG_COLORS[index];
        Settings.instIndex = index;
    }

    public static disableDropdown() {
        Settings.instDropdown.disabled = true;
    }
}