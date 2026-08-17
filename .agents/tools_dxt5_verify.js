const fs=require('fs'); const {PNG}=require('pngjs');
const [,,pngPath,...ddsPaths]=process.argv;
const src=PNG.sync.read(fs.readFileSync(pngPath)); const W=src.width,H=src.height;
function from565(v){const r5=(v>>11)&0x1f,g6=(v>>5)&0x3f,b5=v&0x1f;return [(r5<<3)|(r5>>2),(g6<<2)|(g6>>4),(b5<<3)|(b5>>2)];}
for(const dp of ddsPaths){
  const d=fs.readFileSync(dp).slice(128); let o=0;
  let wsum=0,wErr=0,glowErr=0,glowN=0,worstVis=0;
  for(let by=0;by<H;by+=4)for(let bx=0;bx<W;bx+=4){
    const a0=d[o],a1=d[o+1]; const aPal=[a0,a1];
    for(let i=2;i<8;i++) aPal.push(Math.round(((8-i)*a0+(i-1)*a1)/7));
    let ab=0n; for(let i=0;i<6;i++) ab|=BigInt(d[o+2+i])<<BigInt(i*8);
    const c0=d[o+8]|(d[o+9]<<8),c1=d[o+10]|(d[o+11]<<8);
    const e0=from565(c0),e1=from565(c1);
    const pal=[e0,e1,[Math.round((2*e0[0]+e1[0])/3),Math.round((2*e0[1]+e1[1])/3),Math.round((2*e0[2]+e1[2])/3)],[Math.round((e0[0]+2*e1[0])/3),Math.round((e0[1]+2*e1[1])/3),Math.round((e0[2]+2*e1[2])/3)]];
    for(let j=0;j<4;j++){const ib=d[o+12+j];
      for(let i=0;i<4;i++){
        const ci=(ib>>(i*2))&3, p=((by+j)*W+(bx+i))*4, a=src.data[p+3]/255;
        const e=(Math.abs(pal[ci][0]-src.data[p])+Math.abs(pal[ci][1]-src.data[p+1])+Math.abs(pal[ci][2]-src.data[p+2]))/3;
        wErr+=e*a; wsum+=a;
        if(e*a>worstVis) worstVis=e*a;
        if(by>=384 && src.data[p+3]>=10){ glowErr+=e*a; glowN++; }
      }}
    o+=16;
  }
  console.log(dp.padEnd(20)+' visible-weighted RGB err = '+(wErr/wsum).toFixed(3)+'   worst visible = '+worstVis.toFixed(1)+'   subtitle band = '+(glowErr/glowN).toFixed(3));
}
