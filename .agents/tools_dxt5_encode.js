// PNG -> DXT5 DDS, v2.
//
// v1 picked colour endpoints from the per-channel bounding box. That invents a
// corner colour no pixel actually has, and on a smooth low-contrast gradient -
// exactly what a Photoshop outer glow is - it blocks up visibly. This version
// does what real encoders do:
//
//   1. fit the block's dominant colour axis by PCA (power iteration on the
//      covariance), weighting each pixel by its ALPHA so fully transparent
//      pixels cannot drag the endpoints;
//   2. project onto that axis for initial endpoints;
//   3. refine by least squares against the current index assignment, re-quantise
//      to 565 and re-index, keeping whichever round scores best.
//
// The alpha block is unchanged - it already measured 0.40/255 on the glow.
const fs = require('fs');
const { PNG } = require('pngjs');

const [, , pngPath, stockDdsPath, outPath] = process.argv;
const png = PNG.sync.read(fs.readFileSync(pngPath));
const W = png.width, H = png.height;
if (W % 4 || H % 4) throw new Error('dimensions must be multiples of 4');
const src = png.data;

const to565 = (r, g, b) => ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3);
function from565(v) {
    const r5 = (v >> 11) & 0x1f, g6 = (v >> 5) & 0x3f, b5 = v & 0x1f;
    return [(r5 << 3) | (r5 >> 2), (g6 << 2) | (g6 >> 4), (b5 << 3) | (b5 >> 2)];
}
const clamp = v => v < 0 ? 0 : v > 255 ? 255 : v;

function palOf(c0, c1) {
    const e0 = from565(c0), e1 = from565(c1);
    return [e0, e1,
        [Math.round((2 * e0[0] + e1[0]) / 3), Math.round((2 * e0[1] + e1[1]) / 3), Math.round((2 * e0[2] + e1[2]) / 3)],
        [Math.round((e0[0] + 2 * e1[0]) / 3), Math.round((e0[1] + 2 * e1[1]) / 3), Math.round((e0[2] + 2 * e1[2]) / 3)]];
}
// weight of endpoint 0 for each palette slot
const WA = [1, 0, 2 / 3, 1 / 3];

function fitBlock(px) {
    // weights: alpha, with a floor so an all-transparent block still fits something
    const w = px.map(p => Math.max(p[3] / 255, 0.02));
    let wsum = 0, mean = [0, 0, 0];
    for (let k = 0; k < 16; k++) { wsum += w[k]; for (let c = 0; c < 3; c++) mean[c] += px[k][c] * w[k]; }
    for (let c = 0; c < 3; c++) mean[c] /= wsum;

    // covariance
    const cov = [0, 0, 0, 0, 0, 0]; // xx xy xz yy yz zz
    for (let k = 0; k < 16; k++) {
        const d = [px[k][0] - mean[0], px[k][1] - mean[1], px[k][2] - mean[2]];
        cov[0] += w[k] * d[0] * d[0]; cov[1] += w[k] * d[0] * d[1]; cov[2] += w[k] * d[0] * d[2];
        cov[3] += w[k] * d[1] * d[1]; cov[4] += w[k] * d[1] * d[2]; cov[5] += w[k] * d[2] * d[2];
    }
    // dominant eigenvector by power iteration
    let v = [1, 1, 1];
    for (let it = 0; it < 12; it++) {
        const nv = [
            cov[0] * v[0] + cov[1] * v[1] + cov[2] * v[2],
            cov[1] * v[0] + cov[3] * v[1] + cov[4] * v[2],
            cov[2] * v[0] + cov[4] * v[1] + cov[5] * v[2]];
        const m = Math.max(Math.abs(nv[0]), Math.abs(nv[1]), Math.abs(nv[2]));
        if (m < 1e-9) { v = [1, 1, 1]; break; }
        v = [nv[0] / m, nv[1] / m, nv[2] / m];
    }
    // project
    let lo = Infinity, hi = -Infinity, loP = px[0], hiP = px[0];
    for (let k = 0; k < 16; k++) {
        if (px[k][3] === 0) continue;                       // invisible: ignore
        const t = px[k][0] * v[0] + px[k][1] * v[1] + px[k][2] * v[2];
        if (t < lo) { lo = t; loP = px[k]; }
        if (t > hi) { hi = t; hiP = px[k]; }
    }
    if (hi === -Infinity) { loP = px[0]; hiP = px[0]; }     // wholly transparent block

    let c0 = to565(hiP[0], hiP[1], hiP[2]);
    let c1 = to565(loP[0], loP[1], loP[2]);
    if (c0 < c1) { const t = c0; c0 = c1; c1 = t; }

    let bestC0 = c0, bestC1 = c1, bestErr = Infinity, bestIdx = null;
    for (let round = 0; round < 5; round++) {
        const pal = palOf(c0, c1);
        const idx = new Array(16);
        let err = 0;
        for (let k = 0; k < 16; k++) {
            let b = 0, bd = Infinity;
            for (let j = 0; j < 4; j++) {
                const dr = pal[j][0] - px[k][0], dg = pal[j][1] - px[k][1], db = pal[j][2] - px[k][2];
                const d = (dr * dr + dg * dg + db * db) * w[k];
                if (d < bd) { bd = d; b = j; }
            }
            idx[k] = b; err += bd;
        }
        if (err < bestErr) { bestErr = err; bestC0 = c0; bestC1 = c1; bestIdx = idx; }
        // least squares for new endpoints given idx
        let aa = 0, ab = 0, bb = 0, ax = [0, 0, 0], bx = [0, 0, 0];
        for (let k = 0; k < 16; k++) {
            const a = WA[idx[k]], b = 1 - a, ww = w[k];
            aa += ww * a * a; ab += ww * a * b; bb += ww * b * b;
            for (let c = 0; c < 3; c++) { ax[c] += ww * a * px[k][c]; bx[c] += ww * b * px[k][c]; }
        }
        const det = aa * bb - ab * ab;
        if (Math.abs(det) < 1e-9) break;
        const n0 = [0, 0, 0], n1 = [0, 0, 0];
        for (let c = 0; c < 3; c++) {
            n0[c] = clamp(Math.round((bb * ax[c] - ab * bx[c]) / det));
            n1[c] = clamp(Math.round((aa * bx[c] - ab * ax[c]) / det));
        }
        let q0 = to565(n0[0], n0[1], n0[2]), q1 = to565(n1[0], n1[1], n1[2]);
        if (q0 < q1) { const t = q0; q0 = q1; q1 = t; }
        if (q0 === c0 && q1 === c1) break;
        c0 = q0; c1 = q1;
    }
    // Local search: nudge each quantised endpoint channel by +-1 in 565 space.
    // This is what closes the gap on a soft glow - least squares finds the right
    // AXIS, but rounding the endpoints to 5/6/5 bits is what bands a smooth
    // gradient, and a one-step search recovers most of it.
    const score = (q0, q1) => {
        const p = palOf(q0, q1);
        let e = 0;
        for (let k = 0; k < 16; k++) {
            let bd = Infinity;
            for (let j = 0; j < 4; j++) {
                const dr = p[j][0] - px[k][0], dg = p[j][1] - px[k][1], db = p[j][2] - px[k][2];
                const d = (dr * dr + dg * dg + db * db) * w[k];
                if (d < bd) bd = d;
            }
            e += bd;
        }
        return e;
    };
    let curErr = score(bestC0, bestC1);
    const chans = [[11, 0x1f, 0x07ff], [5, 0x3f, 0xf81f], [0, 0x1f, 0xffe0]];
    for (let pass = 0; pass < 3; pass++) {
        let improved = false;
        for (let which = 0; which < 2; which++) {
            for (const ch of chans) {
                const shift = ch[0], mask = ch[1], keep = ch[2];
                for (const delta of [-1, 1]) {
                    let q0 = bestC0, q1 = bestC1;
                    const base = which ? q1 : q0;
                    const nv = ((base >> shift) & mask) + delta;
                    if (nv < 0 || nv > mask) continue;
                    const rebuilt = ((base & keep) | (nv << shift)) & 0xffff;
                    if (which) q1 = rebuilt; else q0 = rebuilt;
                    if (q0 < q1) continue;
                    const e = score(q0, q1);
                    if (e < curErr) { curErr = e; bestC0 = q0; bestC1 = q1; improved = true; }
                }
            }
        }
        if (!improved) break;
    }

    // final index pass against the winning endpoints
    const pal = palOf(bestC0, bestC1);
    const idx = new Array(16);
    for (let k = 0; k < 16; k++) {
        let b = 0, bd = Infinity;
        for (let j = 0; j < 4; j++) {
            const dr = pal[j][0] - px[k][0], dg = pal[j][1] - px[k][1], db = pal[j][2] - px[k][2];
            const d = dr * dr + dg * dg + db * db;
            if (d < bd) { bd = d; b = j; }
        }
        idx[k] = b;
    }
    return { c0: bestC0, c1: bestC1, idx };
}

const out = Buffer.alloc((W / 4) * (H / 4) * 16);
let o = 0;
const px = new Array(16);
for (let by = 0; by < H; by += 4) {
    for (let bx = 0; bx < W; bx += 4) {
        for (let j = 0; j < 4; j++) for (let i = 0; i < 4; i++) {
            const p = ((by + j) * W + (bx + i)) * 4;
            px[j * 4 + i] = [src[p], src[p + 1], src[p + 2], src[p + 3]];
        }

        let aMin = 255, aMax = 0;
        for (const q of px) { if (q[3] < aMin) aMin = q[3]; if (q[3] > aMax) aMax = q[3]; }
        out[o++] = aMax; out[o++] = aMin;
        const aPal = [aMax, aMin];
        for (let i = 2; i < 8; i++) aPal.push(Math.round(((8 - i) * aMax + (i - 1) * aMin) / 7));
        let abits = 0n, sh = 0n;
        for (const q of px) {
            let best = 0, bd = 1e9;
            for (let i = 0; i < 8; i++) { const d = Math.abs(aPal[i] - q[3]); if (d < bd) { bd = d; best = i; } }
            abits |= BigInt(best) << sh; sh += 3n;
        }
        for (let i = 0; i < 6; i++) out[o++] = Number((abits >> BigInt(i * 8)) & 0xffn);

        const fit = fitBlock(px);
        out[o++] = fit.c0 & 0xff; out[o++] = (fit.c0 >> 8) & 0xff;
        out[o++] = fit.c1 & 0xff; out[o++] = (fit.c1 >> 8) & 0xff;
        for (let j = 0; j < 4; j++) {
            let byte = 0;
            for (let i = 0; i < 4; i++) byte |= fit.idx[j * 4 + i] << (i * 2);
            out[o++] = byte;
        }
    }
}

const header = fs.readFileSync(stockDdsPath).slice(0, 128);
if (header.readUInt32LE(16) !== W || header.readUInt32LE(12) !== H)
    throw new Error('stock header dimensions do not match the PNG');
fs.writeFileSync(outPath, Buffer.concat([header, out]));
console.log(`wrote ${outPath}  total=${128 + out.length}`);
