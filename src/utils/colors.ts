export interface Color {
    r: number;
    g: number;
    b: number;
    a: number;
}

export function colorToHex(color: Color): string {
    return `#${color.r.toString(16)}${color.g.toString(16)}${color.b.toString(16)}`;
}
export function colorHexToColor(color: string): Color {
    const r = parseInt(color.slice(1, 3), 16);
    const g = parseInt(color.slice(3, 5), 16);
    const b = parseInt(color.slice(5, 7), 16);

    return { r, g, b, a: 1 };
}

export function rgbStringToHex(rgb: string): string {
    const match = rgb.match(/^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/);
    if (!match) {
        throw new Error("Invalid RGB color");
    }

    return `#${parseInt(match[1], 10).toString(16)}${parseInt(match[2], 10).toString(16)}${parseInt(match[3], 10).toString(16)}`;
}

export function colorRGBStringToColor(color: string): Color {
    const match = color.match(/^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/);
    if (!match) {
        throw new Error("Invalid RGB color");
    }
    return {
        r: parseInt(match[1], 10),
        g: parseInt(match[2], 10),
        b: parseInt(match[3], 10),
        a: 1,
    };
}

export function colorDifference(color1: Color, color2: Color): number {
    const dr = color1.r - color2.r;
    const dg = color1.g - color2.g;
    const db = color1.b - color2.b;
    return Math.sqrt(dr * dr + dg * dg + db * db);
}

export function colorDistance(color1: string, color2: string): number {
    return colorDifference(colorHexToColor(color1), colorHexToColor(color2));
}

export function getHexColor(element: HTMLElement): string {
    // Get the computed style of the element
    const style = getComputedStyle(element);

    // Get the RGB color value
    const rgb = style.backgroundColor;

    // Extract the individual red, green, and blue color components
    const match = rgb.match(/^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/)!;

    // Convert the color components to hex
    const hex = match
        .slice(1, 4)
        .map(Number)
        .map((x) => {
            const hex = x.toString(16);
            return hex.length === 1 ? "0" + hex : hex;
        })
        .join("");

    return "#" + hex;
}

export function tweenColor(color1: string, color2: string, t: number): string {
    const start = colorHexToColor(color1);
    const end = colorHexToColor(color2);

    const r = Math.round(start.r + (end.r - start.r) * t);
    const g = Math.round(start.g + (end.g - start.g) * t);
    const b = Math.round(start.b + (end.b - start.b) * t);

    return colorToHex({ r, g, b, a: 1 });
}
