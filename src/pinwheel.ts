import { theChuck } from "./host";

const BG_COLOR = "#ABCDEF";
const MIN_VELOCITY = 0.5;
const DECELERATE = 0.999;
const DECELERATE2 = 0.998;

export default class Pinwheel {
    private canvas: HTMLCanvasElement;
    private ctx: CanvasRenderingContext2D;
    private rotation: number;
    private angularVelocity: number;
    private angularAcceleration: number;
    private previousRotation: number;
    private numBlades: number;
    private twoPi: number;
    private bladeDivisions: number;
    private bladeAngle: number;
    // private pulseBGColor: string = "#FFFFFF";
    private lastUpdateTime: number = 0;
    private dt: number = 0;
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
            theChuck.setFloat("PINWHEEL_VEL", this.angularVelocity);
            theChuck.broadcastEvent("BLADE_CROSSED");
        }
    }

    // private pulsateBackgroundOnce() {
    //     this.pulseBGColor = "#987BAC";
    // }

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
    // 0 = 0
    // 1 = 4 PI
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
