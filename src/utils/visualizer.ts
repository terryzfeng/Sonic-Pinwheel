import { rgbStringToHex, tweenColor} from "./colors";

const MIN_DBFS: number = -120;
// light theme
const SPECTRUM_OUTLINE = "#ffffff";
const SPECTRUM_COLOR = "#ffffff";
const SPECTRUM_HEIGHT = 0.2;

function clamp(value: number, min: number, max: number): number {
    return Math.min(Math.max(value, min), max);
}

// Convert dbfs to height scale
function freqHeightScale(dbfs: number, height: number): number {
    const value: number = clamp(dbfs, MIN_DBFS, 0); // -120 to 0
    const percent: number = value / MIN_DBFS; // 0.0 to 1.0
    return (percent * height) * SPECTRUM_HEIGHT + height * (1-SPECTRUM_HEIGHT); // 0.0 to height (downward)
}
export default class Visualizer {
    public analyserNode: AnalyserNode;
    public canvas: HTMLCanvasElement;

    private context2D: CanvasRenderingContext2D;
    private readonly frequencyData: Float32Array;
    private running: boolean = false;

    private spectrumColor: string = SPECTRUM_COLOR;
    private spectrumOutline: string = SPECTRUM_OUTLINE;

    constructor(canvas: HTMLCanvasElement, analyserNode: AnalyserNode, currBG: string) {
        const visualizerDefaultOptions = {
            frameSize: 2048,
            drawWaveform: true,
            drawSpecturm: true,
        };
        this.analyserNode = analyserNode;
        this.canvas = canvas;
        this.context2D = canvas.getContext("2d")!;
        this.frequencyData = new Float32Array(
            visualizerDefaultOptions.frameSize / 2,
        );

        const bgColor = rgbStringToHex(currBG);
        console.log(bgColor);
        this.spectrumOutline = tweenColor(SPECTRUM_OUTLINE, bgColor, 0.2);
        this.spectrumColor = tweenColor(SPECTRUM_COLOR, bgColor, 0.4);
        console.log(this.spectrumOutline, this.spectrumColor);
    }

    drawSpectrum_(width: number, height: number) {
        this.analyserNode.getFloatFrequencyData(this.frequencyData);
        const increment = width / (this.frequencyData.length / 2);
        this.context2D.beginPath();
        for (let x = 0, i = 0; x < width; x += increment, ++i) {
            if (i === 0) {
                this.context2D.moveTo(
                    x,
                    freqHeightScale(this.frequencyData[i], height),
                );
            } else {
                this.context2D.lineTo(
                    x,
                    freqHeightScale(this.frequencyData[i], height),
                );
            }
        }
        this.context2D.lineTo(width, height);
        this.context2D.lineTo(0, height);
        this.context2D.closePath();
        this.context2D.fillStyle = this.spectrumColor;
        this.context2D.fill();
        this.context2D.strokeStyle = this.spectrumOutline;
        this.context2D.lineWidth = 2;
        this.context2D.stroke();
        this.context2D.lineWidth = 1;
    }

    /**
     * Draw waveform and spectrum
     */
    drawVisualization_() {
        if (!this.running) return;
        this.context2D.clearRect(
            0,
            0,
            this.context2D.canvas.width,
            this.context2D.canvas.height,
        );
        const w = this.context2D.canvas.width;
        const h = this.context2D.canvas.height;
        this.drawSpectrum_(w, h);
        requestAnimationFrame(this.drawVisualization_.bind(this));
    }

    /**
     * Start the visualizer
     */
    start() {
        this.running = true;
        this.drawVisualization_();
    }

    /**
     * Stop the visualizer
     */
    stop() {
        this.running = false;
    }

    /**
     * Set the visualizer dimensions
     */
    resize() {
        this.canvas.width = this.canvas.clientWidth;
        this.canvas.height = this.canvas.clientHeight;
    }
}

export function startVisualizer(analyser: AnalyserNode) {
    const cnv = document.getElementById("input-canvas")! as HTMLCanvasElement;
    const currBG = (document.getElementById("bg-canvas") as HTMLElement).style.backgroundColor;
    const visualizer = new Visualizer(cnv, analyser, currBG);
    visualizer.start();
}
