import Pinwheel from "./pinwheel";

const NUM_INSTRUMENTS = 6;
const DROPDOWN_ID = "instruments";

const BLADE_COLORS = [
    "#3498db",
    "#e74c3c",
    "#2ecc71",
    "#f39c12",
    "#9b59b6",
    "#1abc9c",
];
export const BG_COLORS = [
    "#ABEFCD",
    "#ABCDEF",
    "#CDEFAB",
    "#CDABEF",
    "#EFABCD",
    "#EFCDAB",
];
// e.g. pinwheel-bass.ck, pinwheel-wind.ck, pinwheel-chime.ck, ...
const INST_NAMES = ["wind", "chime", "bamboo", "bass", "voice", "drift"];

export default class Settings {
    public static instDropdown: HTMLSelectElement;
    public static bgCanvas: HTMLCanvasElement;
    public static instName: string = INST_NAMES[0];
    public static instIndex: number = -1;

    private static buttonStates: boolean[] = [
        true,
        true,
        true,
        true,
        true,
        true,
    ];

    constructor(canvasId: string, pinwheel: Pinwheel) {
        Settings.instDropdown = document.getElementById(
            DROPDOWN_ID,
        ) as HTMLSelectElement;
        Settings.bgCanvas = document.getElementById(
            canvasId,
        ) as HTMLCanvasElement;

        Settings.instDropdown.addEventListener("change", () => {
            const index = Settings.instDropdown.selectedIndex;
            Settings.handleDropdownChange(index);
        });

        Settings.instDropdown.addEventListener(
            "click",
            () => {
                Settings.instDropdown.classList.remove("enabled:animate-pulse");
            },
            { once: true },
        );

        // Select a random pinwheel instrument
        Settings.instDropdown.selectedIndex = Math.random() * NUM_INSTRUMENTS;
        Settings.handleDropdownChange(Settings.instDropdown.selectedIndex);

        // Get blade control buttons
        const bladeButtons = document.getElementsByClassName("blade-button");
        for (let i = bladeButtons.length - 1; i >= 0; --i) {
            const button = bladeButtons[i] as HTMLButtonElement;
            // Add border color to button
            button.style.borderColor = BLADE_COLORS[i];
            button.style.backgroundColor = BLADE_COLORS[i];
            button.classList.add("hover:opacity-75");
            button.addEventListener("click", () => {
                if (Settings.buttonStates[i]) {
                    pinwheel.disableBlade(i);
                    button.style.backgroundColor = "white";
                } else {
                    pinwheel.enableBlade(i);
                    button.style.backgroundColor = BLADE_COLORS[i];
                }
                Settings.buttonStates[i] = !Settings.buttonStates[i];
            });
        }
    }

    private static handleDropdownChange(index: number) {
        Settings.bgCanvas.style.backgroundColor = BG_COLORS[index];
        Settings.instIndex = index;
        Settings.instName = INST_NAMES[index];
    }

    /**
     * Disable the dropdown so you can't select another instrument
     */
    public static disableDropdown() {
        Settings.instDropdown.disabled = true;
        Settings.instDropdown.title = "Refresh page to change instrument";
        // Get select prompt
        const selectPrompt = document.getElementById("select-inst-prompt")!;
        selectPrompt.classList.add("opacity-0");

        setTimeout(() => {
            selectPrompt.innerText = "Instrument is selected";
            selectPrompt.classList.remove("opacity-0");
            selectPrompt.classList.add("opacity-50");
        }, 300); // Wait for the hide animation to finish
    }
}
