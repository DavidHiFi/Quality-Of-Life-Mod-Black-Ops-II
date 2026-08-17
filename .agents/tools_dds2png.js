// DXT5 DDS -> RGBA PNG. Alpha is read from the DXT5 alpha block itself, not
// from the DDS pixel-format flags: the workspace .DDS dump declares no alpha
// while the bytes carry it, so trusting the header loses the transparency.
const fs = require('fs');
const { PNG } = require('pngjs');

const [, , ddsPath, outPath] = process.argv;
const buf = fs.readFileSync(ddsPath);
const H = buf.readUInt32LE(12), W = buf.readUInt32LE(16);
const fourCC = buf.toString('ascii', 84, 88);
if (fourCC !== 'DXT5') throw new Error('expected DXT5, got ' + fourCC);
const data = buf.slice(128);

function from565(v) {
    const r5 = (v >> 11) & 0x1f, g6 = (v >> 5) & 0x3f, b5 = v & 0x1f;
    return [(r5 << 3) | (r5 >> 2), (g6 << 2) | (g6 >> 4), (b5 << 3) | (b5 >> 2)];
}

const png = new PNG({ width: W, height: H });
let o = 0, aMin = 255, aMax = 0;
for (let by = 0; by < H; by += 4) {
    for (let bx = 0; bx < W; bx += 4) {
        const a0 = data[o], a1 = data[o + 1];
        const aPal = [a0, a1];
        for (let i = 2; i < 8; i++) {
            aPal.push(a0 > a1
                ? Math.round(((8 - i) * a0 + (i - 1) * a1) / 7)
                : (i < 6 ? Math.round(((6 - i) * a0 + (i - 1) * a1) / 5) : (i === 6 ? 0 : 255)));
        }
        let abits = 0n;
        for (let i = 0; i < 6; i++) abits |= BigInt(data[o + 2 + i]) << BigInt(i * 8);
        const c0 = data[o + 8] | (data[o + 9] << 8), c1 = data[o + 10] | (data[o + 11] << 8);
        const e0 = from565(c0), e1 = from565(c1);
        const pal = [e0, e1,
            [Math.round((2 * e0[0] + e1[0]) / 3), Math.round((2 * e0[1] + e1[1]) / 3), Math.round((2 * e0[2] + e1[2]) / 3)],
            [Math.round((e0[0] + 2 * e1[0]) / 3), Math.round((e0[1] + 2 * e1[1]) / 3), Math.round((e0[2] + 2 * e1[2]) / 3)]];
        for (let j = 0; j < 4; j++) {
            const idxByte = data[o + 12 + j];
            for (let i = 0; i < 4; i++) {
                const ci = (idxByte >> (i * 2)) & 3;
                const a = aPal[Number((abits >> BigInt((j * 4 + i) * 3)) & 7n)];
                const p = ((by + j) * W + (bx + i)) * 4;
                png.data[p] = pal[ci][0]; png.data[p + 1] = pal[ci][1];
                png.data[p + 2] = pal[ci][2]; png.data[p + 3] = a;
                if (a < aMin) aMin = a;
                if (a > aMax) aMax = a;
            }
        }
        o += 16;
    }
}
fs.writeFileSync(outPath, PNG.sync.write(png));
console.log(`${W}x${H} -> ${outPath}`);
console.log(`alpha range in the stock art: ${aMin} .. ${aMax}` + (aMin === 255 ? '  (fully opaque)' : '  (HAS transparency - keep it)'));
