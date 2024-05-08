import { initChuck, startChuck } from "./host";
import Pinwheel from "./pinwheel";
import Settings from "./settings";

class Main {
    public startButton: HTMLButtonElement;
    public settings: Settings;
    public pinwheel: Pinwheel;

    constructor() {
        this.startButton = document.querySelector<HTMLButtonElement>("#start")!;
        this.pinwheel = new Pinwheel("pinwheel-canvas");
        this.settings = new Settings("bg-canvas");
    }

    init() {
        // animation pause/resume
        document.addEventListener("visibilitychange", () => {
            if (document.hidden) {
                cancelAnimationFrame(this.pinwheel.animationID);
            } else {
                this.pinwheel.start();
            }
        });

        window.addEventListener("load", async () => {
            await initChuck(this.startButton);

            // START button is clicked
            this.startButton.addEventListener("click", async () => {
                this.startButton.disabled = true;
                await startChuck(this.startButton);
                this.pinwheel.start();
                Settings.disableDropdown();
            });
        });
    }
}

const main = new Main();
main.init();
