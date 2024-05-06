export default class Renderer {
    constructor(canvasId) {
        this.canvas = document.getElementById(canvasId);
        this.ctx = this.canvas.getContext("2d");
        this.width = this.canvas.width;
        this.height = this.canvas.height;
        this.lastUpdateTime = 0;
        this.dt = 0;
        this.animationID = 0;

        // Initialize any other properties related to rendering
        this.background = new Background(this.ctx);
        this.pinwheel = new Pinwheel(this.ctx);
    }

    render() {
        // Clear canvas
        this.ctx.clearRect(0, 0, this.width, this.height);

        // Draw background
        this.background.draw();

        // Draw pinwheel
        this.pinwheel.draw();

        // Continue rendering loop
        this.animationID = requestAnimationFrame(this.render.bind(this));
    }

    start() {
        this.lastUpdateTime = performance.now();
        this.render();
    }
}
