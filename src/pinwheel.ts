// import {
//     colorDifference,
//     colorHexToColor,
//     getHexColor,
//     tweenColor,
// } from "./utils";

const BG_COLOR = "#ABCDEF";

export default class Pinwheel {
    private canvas: HTMLCanvasElement;
    private ctx: CanvasRenderingContext2D;
    private rotation: number;
    private angularVelocity: number;
    private angularAcceleration: number;
    private epsilon: number;
    private previousRotation: number;
    private numBlades: number;
    private twoPi: number;
    private bladeDivisions: number;
    private bladeAngle: number;
    // private pulseBGColor: string = "#FFFFFF";
    private lastUpdateTime: number = 0;

    constructor(canvasId: string) {
        this.canvas = document.getElementById(canvasId)! as HTMLCanvasElement;
        this.ctx = this.canvas.getContext("2d")!;
        this.rotation = 0;
        this.angularVelocity = Math.PI;
        // this.angularAcceleration = -.3;
        this.angularAcceleration = 0;
        this.epsilon = 0.0001;
        this.previousRotation = 0;
        this.numBlades = 6;
        this.twoPi = Math.PI * 2.0;
        this.bladeDivisions = this.twoPi / this.numBlades;
        this.bladeAngle = 0;

        // Set canvas size
        this.canvas.width = 400;
        this.canvas.height = 400;

        // color the canvas white
        this.canvas.style.backgroundColor = BG_COLOR;

        this.drawPinwheel();
    }

    private drawPinwheel() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        this.ctx.save();
        this.ctx.translate(this.canvas.width / 2, this.canvas.height / 2);
        this.ctx.rotate(this.rotation);

        const colors = [
            "#3498db",
            "#e74c3c",
            "#2ecc71",
            "#f39c12",
            "#9b59b6",
            "#1abc9c",
        ];

        for (let i = 0; i < this.numBlades; i++) {
            this.ctx.fillStyle = colors[i % colors.length];
            this.ctx.beginPath();
            this.ctx.moveTo(0, 0);
            this.ctx.lineTo(50, 0);
            this.ctx.lineTo(0, 150);
            this.ctx.closePath();
            this.ctx.fill();

            this.ctx.rotate(Math.PI / (this.numBlades / 2));
        }

        this.ctx.restore();

        // Draw the ichtus circle
        this.ctx.fillStyle = "#ffffff";
        this.ctx.beginPath();
        this.ctx.arc(
            this.canvas.width / 2,
            this.canvas.height / 2 + 150,
            8,
            0,
            Math.PI * 2,
        );
        this.ctx.closePath();
        this.ctx.fill();
    }

    /**
     * Check if the pinwheel has crossed a blade
     */
    private checkBladeCrossing() {
        this.bladeAngle += this.rotation - this.previousRotation;
        if (this.bladeAngle > this.bladeDivisions) {
            this.bladeAngle -= this.bladeDivisions;
            // console.log("Blade crossed");
        }
    }

    // private pulsateBackgroundOnce() {
    //     this.pulseBGColor = "#987BAC";
    // }

    private update() {
        // Time Delta
        const now = performance.now();
        const dt = (now - this.lastUpdateTime) / 1000;
        this.lastUpdateTime = now;

        // Rotation Update
        this.previousRotation = this.rotation;
        this.angularVelocity += this.angularAcceleration * dt;
        if (this.angularVelocity < this.epsilon) {
            this.angularVelocity = 0;
        }
        this.rotation += this.angularVelocity * dt;
        if (this.rotation > this.twoPi) {
            this.rotation -= this.twoPi;
            this.previousRotation -= this.twoPi;
        }

        this.checkBladeCrossing();
        this.drawPinwheel();
        requestAnimationFrame(() => this.update());
    }

    // private equal(a: number, b: number) {
    //     return Math.abs(a - b) < this.epsilon;
    // }

    public start() {
        this.lastUpdateTime = performance.now();
        this.update();
    }
}
