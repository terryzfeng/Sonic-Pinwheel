const NUM_INSTRUMENTS = 3;

const BG_COLORS = ["#ABEFCD", "#ABCDEF", "#CDEFAB", "#CDABEF", "#EFABCD", "#EFCDAB"];
// e.g. pinwheel-bass.ck, pinwheel-wind.ck, pinwheel-chime.ck, ...
const INST_NAMES = ["wind", "chime", "2", "bass", "4", "drift"];

export default class Settings {
    public static instDropdown: HTMLSelectElement;
    public static bgCanvas: HTMLCanvasElement;
    public static instName: string = INST_NAMES[0];

    constructor(canvasId: string, dropdownId: string = "instruments") {
        Settings.instDropdown = document.getElementById(
            dropdownId,
        ) as HTMLSelectElement;
        Settings.bgCanvas = document.getElementById(
            canvasId,
        ) as HTMLCanvasElement;

        for (let i = 0; i < NUM_INSTRUMENTS; i++) {
            const option = document.createElement("option");
            option.value = i.toString();
            option.text = `Instrument ${i}`;
        }

        Settings.instDropdown.addEventListener("change", () => {
            const index = Settings.instDropdown.selectedIndex;
            Settings.handleDropdownChange(index);
        });

        // Get the current selected index
        const index = Settings.instDropdown.selectedIndex;
        Settings.handleDropdownChange(index);
    }

    private static handleDropdownChange(index: number) {
        Settings.bgCanvas.style.backgroundColor = BG_COLORS[index];
        Settings.instName = INST_NAMES[index];
    }

    public static disableDropdown() {
        Settings.instDropdown.disabled = true;
    }
}
