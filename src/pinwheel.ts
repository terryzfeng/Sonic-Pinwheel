import { theChuck } from "./host";

const MIN_VELOCITY = 0.5;
const DECELERATE = 0.999;
const DECELERATE2 = 0.998;

// Scaling
const RATIO = window.devicePixelRatio || 1;
const WIDTH = 400;
const HEIGHT = 400;
const bladeX = 50 * RATIO;
const bladeY = 150 * RATIO;

export default class Pinwheel {
    private currentBladeIndex: number = -1;
    private numBlades: number;
    private canvas: HTMLCanvasElement;
    private ctx: CanvasRenderingContext2D;
    private width: number = WIDTH;
    private height: number = HEIGHT;

    private rotation: number;
    private previousRotation: number;
    private angularVelocity: number;
    private angularAcceleration: number;

    private twoPi: number;
    private bladeDivisions: number;
    private bladeAngle: number;
    private lastUpdateTime: number = 0;
    private dt: number = 0;
    private disabledBlades: Set<number> = new Set();
    public animationID: number = 0;


    constructor(canvasId: string) {
        this.canvas = document.getElementById(canvasId)! as HTMLCanvasElement;
        this.ctx = this.canvas.getContext("2d")!;
        this.rotation = 0;
        this.angularVelocity = Math.PI;
        this.angularAcceleration = 0;
        this.previousRotation = 0;
        this.numBlades = 6;
        this.twoPi = Math.PI * 2.0;
        this.bladeDivisions = this.twoPi / this.numBlades;
        this.bladeAngle = 0;

        this.ctx.scale(RATIO, RATIO);
        const stage = document.getElementById("stage")! as HTMLDivElement;
        this.width = stage.clientWidth * RATIO;
        this.height = stage.clientHeight * RATIO;
        this.canvas.width = this.width;
        this.canvas.height = this.height;
        this.canvas.style.width = stage.clientWidth + "px";
        this.canvas.style.height = stage.clientHeight + "px";

        this.disableBlade(1);
        this.disableBlade(4);

        this.drawPinwheel();
    }

    private drawPinwheel() {
        this.ctx.clearRect(0, 0, this.width, this.height);
        this.ctx.save();
        this.ctx.translate(this.width / 2, this.height / 2);
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
            if (this.disabledBlades.has(i)) {
                this.ctx.strokeStyle = colors[i % colors.length];
                this.ctx.beginPath();
                this.ctx.moveTo(0, 0);
                this.ctx.lineTo(bladeX, 0);
                this.ctx.lineTo(0, bladeY);
                this.ctx.closePath();
                this.ctx.lineWidth = 1 * RATIO;
                this.ctx.stroke();
            } else {
                this.ctx.fillStyle = colors[i % colors.length];
                this.ctx.beginPath();
                this.ctx.moveTo(0, 0);
                this.ctx.lineTo(bladeX, 0);
                this.ctx.lineTo(0, bladeY);
                this.ctx.closePath();
                this.ctx.fill();
            }
            this.ctx.rotate(Math.PI / (this.numBlades / 2));
        }

        this.ctx.restore();

        // Draw the ichtus circle
        this.ctx.fillStyle = "#ffffff";
        this.ctx.beginPath();
        this.ctx.arc(
            this.width / 2,
            this.height / 2 + bladeY,
            8 * RATIO,
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
            this.currentBladeIndex =
                (this.currentBladeIndex + 1) % this.numBlades; // Add this line
            if (!this.disabledBlades.has(this.currentBladeIndex)) {
                theChuck.setFloat("PINWHEEL_VEL", this.angularVelocity);
                theChuck.setInt("PINWHEEL_BLADE", this.currentBladeIndex);
                theChuck.broadcastEvent("BLADE_CROSSED");
            }
        }
    }

    /**
     * Blow speed based on microphone magnitude
     */
    private blowSpeed() {
        theChuck.getInt("MIC_ACTIVE").then((active) => {
            if (active === 0) {
                theChuck.getFloat("MIC_MAG").then((mag) => {
                    this.magToAngularVelocity(mag);
                });
            }
        });
    }

    // Convert magnitude to angular velocity
    // [0, 1] => [0, 4 PI]
    private magToAngularVelocity(mag: number) {
        const newAcceleration = mag * 4 * Math.PI;
        if (newAcceleration > 0 && this.angularVelocity < 4 * Math.PI) {
            // this.angularAcceleration = (.95 * newAcceleration) + (.05 * this.angularAcceleration);
            // TODO: This is a hack to make the pinwheel more responsive
            this.angularAcceleration = 2 + newAcceleration;
            this.angularVelocity += this.angularAcceleration * this.dt;
        } else {
            if (this.angularVelocity > Math.PI) {
                this.angularVelocity *= DECELERATE;
            } else {
                this.angularVelocity *= DECELERATE2;
            }
        }
        // Minimum speed
        if (this.angularVelocity < MIN_VELOCITY) {
            this.angularVelocity = MIN_VELOCITY;
        }
    }

    public disableBlade(bladeIndex: number) {
        this.disabledBlades.add(bladeIndex);
    }

    public enableBlade(bladeIndex: number) {
        this.disabledBlades.delete(bladeIndex);
    }

    private update() {
        // Time Delta
        const now = performance.now();
        this.dt = (now - this.lastUpdateTime) / 1000;
        this.lastUpdateTime = now;

        // Rotation Update
        this.previousRotation = this.rotation;
        this.blowSpeed();
        this.rotation += this.angularVelocity * this.dt;
        if (this.rotation > this.twoPi) {
            this.rotation -= this.twoPi;
            this.previousRotation -= this.twoPi;
        }

        this.drawPinwheel();
        this.checkBladeCrossing();
        this.animationID = requestAnimationFrame(() => this.update());
    }

    public async start() {
        await theChuck;
        this.lastUpdateTime = performance.now();
        this.update();
    }
}

