import { rgbStringToHex, tweenColor } from "./colors";

const MIN_DBFS: number = -90;
// const SPECTRUM_OUTLINE = "#ffffff";
const SPECTRUM_COLOR = "#ffffff";
// const SPECTRUM_HEIGHT = 0.2;

const NUM_BANDS = 50;

function clamp(value: number, min: number, max: number): number {
    return Math.min(Math.max(value, min), max);
}

// Convert dbfs to height scale
// function freqHeightScale(dbfs: number, height: number): number {
//     const value: number = clamp(dbfs, MIN_DBFS, 0); // -120 to 0
//     const percent: number = value / MIN_DBFS; // 0.0 to 1.0
//     return (percent * height) * SPECTRUM_HEIGHT + height * (1-SPECTRUM_HEIGHT); // 0.0 to height (downward)
// }

// [-120,0] -> [0,1]
function dbfsToLinear(dbfsValue: number): number {
    const min = MIN_DBFS;
    const max = 0;
    const value = clamp(dbfsValue, min, max);
    return (value - min) / (max - min);
}

export default class Visualizer {
    public analyserNode: AnalyserNode;
    public canvas: HTMLCanvasElement;

    private context2D: CanvasRenderingContext2D;
    private readonly frequencyData: Float32Array;
    private running: boolean = false;

    private spectrumColor: string = SPECTRUM_COLOR;
    // private spectrumOutline: string = SPECTRUM_OUTLINE;

    constructor(
        canvas: HTMLCanvasElement,
        analyserNode: AnalyserNode,
        currBG: string,
    ) {
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
        // this.spectrumOutline = tweenColor(SPECTRUM_OUTLINE, bgColor, 0.2);
        this.spectrumColor = tweenColor(SPECTRUM_COLOR, bgColor, 0.5);
    }

    drawSpectrum_(width: number, height: number) {
        this.analyserNode.getFloatFrequencyData(this.frequencyData);
        const freqs = linearToLog(this.frequencyData);
        const spacing = width / (NUM_BANDS - 1);
        const bins = new Array(NUM_BANDS).fill(0);
        this.frequencyData.forEach((value, index) => {
            const binIndex = Math.floor(index / (freqs.length / NUM_BANDS));
            bins[binIndex] += value;
        });
        // Avg the bins
        bins.forEach((_, index) => {
            bins[index] /= freqs.length / NUM_BANDS;
            // Normalize dbfs to [-120,0] => [0,1]
            bins[index] = Math.pow(dbfsToLinear(bins[index]), 2);
        });

        for (let i = 0; i < NUM_BANDS; i++) {
            const x = i * spacing - 2 * spacing;
            const y = height;

            const adjustedBin = Math.sqrt(bins[i]);
            const cloudSize = 100 * adjustedBin; // Adjust this factor to control cloud density

            // draw a cloud-like shape
            this.context2D.beginPath();
            this.context2D.arc(x, y, cloudSize, 0, 2 * Math.PI);
            this.context2D.fillStyle = this.spectrumColor;
            this.context2D.fill();
        }
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
    const currBG = (document.getElementById("bg-canvas") as HTMLElement).style
        .backgroundColor;
    const visualizer = new Visualizer(cnv, analyser, currBG);
    visualizer.start();
}

// Convert 1024 linear bins to 20 log bins
function linearToLog(frequencyData: Float32Array) {
    const logData = new Float32Array(NUM_BANDS);
    const logBase = Math.pow(frequencyData.length, 1 / NUM_BANDS);
    for (let i = 0; i < NUM_BANDS; i++) {
        const start = Math.pow(logBase, i);
        const end = Math.pow(logBase, i + 1);
        let sum = 0;
        for (let j = start; j < end; j++) {
            sum += frequencyData[j];
        }
        logData[i] = sum / (end - start);
    }
    return logData;
}
