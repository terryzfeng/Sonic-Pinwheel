import { theChuck } from "./host";

const TWO_PI = Math.PI * 2;
const MIN_VELOCITY = 0.5;
const HIGH_SPEED_DECELERATION = 0.995;
const LOW_SPEED_DECELERATION = 0.997;

// Scaling
const RATIO = window.devicePixelRatio || 1;
const WIDTH = 400;
const HEIGHT = 400;
const bladeX = 50 * RATIO;
const bladeY = 150 * RATIO;
const ICTUS_LARGE = 4 * RATIO;

export default class Pinwheel {
    // Canvas Properties
    private canvas: HTMLCanvasElement;
    private ctx: CanvasRenderingContext2D;
    private width: number = WIDTH;
    private height: number = HEIGHT;

    // Blade Configuration
    private numBlades: number;
    private bladeDivisions: number;
    private bladeAngle: number;
    private ictusActive: number = 0;

    // Rotation Properties
    private rotation: number;
    private previousRotation: number;
    private angularVelocity: number;
    private angularAcceleration: number;

    // Timing Properties
    private lastUpdateTime: number = 0;
    private dt: number = 0;

    // Blade Indexing
    private currentBladeIndex: number = 5;
    private disabledBlades: Set<number> = new Set();

    // Animation Properties
    public animationID: number = 0;

    // Motion Control
    public useConstantSpeed: boolean = false;
    public constantSpeed: number = 5;

    // Color Palette
    public colors: string[] = [
        "#3498db",
        "#e74c3c",
        "#2ecc71",
        "#f39c12",
        "#9b59b6",
        "#1abc9c",
    ];

    constructor(canvasId: string) {
        this.canvas = document.getElementById(canvasId)! as HTMLCanvasElement;
        this.ctx = this.canvas.getContext("2d")!;
        this.rotation = 0;
        this.angularVelocity = Math.PI;
        this.angularAcceleration = 0;
        this.previousRotation = 0;
        this.numBlades = 6;
        this.bladeDivisions = TWO_PI / this.numBlades;
        this.bladeAngle = 0;

        this.ctx.scale(RATIO, RATIO);
        const stage = document.getElementById("stage")! as HTMLDivElement;
        this.width = stage.clientWidth * RATIO;
        this.height = stage.clientHeight * RATIO;
        this.canvas.width = this.width;
        this.canvas.height = this.height;
        this.canvas.style.width = stage.clientWidth + "px";
        this.canvas.style.height = stage.clientHeight + "px";

        // this.disableBlade(1);
        // this.disableBlade(2);
        // this.disableBlade(0);
        // this.disableBlade(4);

        this.draw();
    }

    private drawPinwheel(rotationOffset = 0) {
        this.ctx.save();
        this.ctx.translate(this.width / 2, this.height / 2);
        this.ctx.rotate(this.rotation + rotationOffset);

        for (let i = 0; i < this.numBlades; i++) {
            if (this.disabledBlades.has(i)) {
                this.ctx.strokeStyle = this.colors[i % this.colors.length];
                this.ctx.beginPath();
                this.ctx.moveTo(0, 0);
                this.ctx.lineTo(bladeX, 0);
                this.ctx.lineTo(0, bladeY);
                this.ctx.closePath();
                this.ctx.lineWidth = 1 * RATIO;
                this.ctx.stroke();
            } else {
                this.ctx.fillStyle = this.colors[i % this.colors.length];
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
    }

    private draw() {
        this.ctx.clearRect(0, 0, this.width, this.height);

        // Draw previous positions with transparency for motion blur effect
        const blurFactor = 0.6; // Adjust the blur intensity as needed
        const trailLength = 3; // Number of previous positions to draw
        for (let i = 1; i <= trailLength; i++) {
            const alpha = (1 - i / trailLength) * blurFactor;
            this.ctx.save();
            this.ctx.globalAlpha = alpha;
            this.drawPinwheel(-i * this.angularVelocity * this.dt);
            this.ctx.restore();
        }

        this.drawPinwheel();

        // Draw the ichtus circle
        this.ctx.fillStyle = "#ffffff";
        this.ctx.beginPath();
        this.ctx.arc(
            this.width / 2,
            this.height / 2 + bladeY,
            8 * RATIO + this.ictusActive,
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
            // Update blade angle
            this.bladeAngle -= this.bladeDivisions;
            // Blade is active and crossed the ictus circle
            if (!this.disabledBlades.has(this.currentBladeIndex)) {
                this.ictusActive = ICTUS_LARGE;
                theChuck.setFloat("PINWHEEL_VEL", this.angularVelocity);
                theChuck.setInt("PINWHEEL_BLADE", this.currentBladeIndex);
                theChuck.broadcastEvent("BLADE_CROSSED");
            }
            // Blades count down in reverse order (clockwise)
            this.currentBladeIndex--;
            if (this.currentBladeIndex == -1) {
                this.currentBladeIndex = this.numBlades - 1; // wrap around
            }
        } else {
            this.ictusActive = this.ictusActive * 0.9;
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
            if (this.angularVelocity > TWO_PI) {
                this.angularVelocity *= HIGH_SPEED_DECELERATION;
            } else {
                this.angularVelocity *= LOW_SPEED_DECELERATION;
            }
        }
        // Minimum speed
        if (this.angularVelocity < MIN_VELOCITY) {
            this.angularVelocity = MIN_VELOCITY;
        }

        if (this.useConstantSpeed) {
            this.angularVelocity = this.constantSpeed;
        }
    }

    public disableBlade(bladeIndex: number) {
        this.disabledBlades.add(bladeIndex);
        this.draw();
    }

    public enableBlade(bladeIndex: number) {
        this.disabledBlades.delete(bladeIndex);
        this.draw();
    }

    public setColors(colors: string[]) {
        this.colors = colors;
    }

    public toggleConstantSpeed() {
        this.useConstantSpeed = !this.useConstantSpeed;
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
        if (this.rotation > TWO_PI) {
            this.rotation -= TWO_PI;
            this.previousRotation -= TWO_PI;
        }

        this.draw();
        this.checkBladeCrossing();
        this.animationID = requestAnimationFrame(() => this.update());
    }

    public async start() {
        await theChuck;
        this.lastUpdateTime = performance.now();
        this.update();
    }
}
