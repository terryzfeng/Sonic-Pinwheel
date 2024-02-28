import { initChuck, startChuck } from "./host";
import Pinwheel from "./pinwheel";

class Main {
    public startButton: HTMLButtonElement;
    public pinwheel: Pinwheel;

    constructor() {
        this.startButton = document.querySelector<HTMLButtonElement>("#start")!;
        this.pinwheel = new Pinwheel("pinwheelCanvas");
    }

    init() {
        window.addEventListener("load", async () => {
            this.startButton.addEventListener("click", async () => {
                await initChuck(this.startButton);
                await startChuck(this.startButton);
                this.pinwheel.start();
                this.startButton.disabled = true;
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
