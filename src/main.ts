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
                this.startButton.disabled = true;
                await startChuck(this.startButton);
                this.pinwheel.start();
            });
        });
    }
}

const main = new Main();
main.init();
