import { initChuck, startChuck } from "./host";
import Pinwheel from "./pinwheel";
import Settings from "./settings";

class Main {
    public startButton: HTMLButtonElement;
    public settings: Settings;
    public pinwheel: Pinwheel;

    constructor() {
        this.startButton = document.querySelector<HTMLButtonElement>("#start")!;
        this.settings = new Settings("pinwheelCanvas");
        this.pinwheel = new Pinwheel("pinwheelCanvas");
    }

    init() {
        window.addEventListener("load", async () => {
            this.startButton.addEventListener("click", async () => {
                await initChuck(this.startButton);
                await startChuck(this.startButton);
                this.pinwheel.start();
                this.startButton.disabled = true;
                Settings.disableButtons();
            });
        });

        // Pinwheel animation pause/resume
        document.addEventListener("visibilitychange", () => {
            if (document.hidden) {
                cancelAnimationFrame(this.pinwheel.animationID);
            } else {
                this.pinwheel.start();
            }
        });
    }
}

const main = new Main();
main.init();
