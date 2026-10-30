import Cocoa
import WebKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
// The cloud-sea piece from ascii.rest, drawn in one WebGL pass: each frame uploads the 200x100 grid of
// (dot size, palette colour) as a texture, and the shader stamps the dot glyphs and fades the edges.
let html = #"""
<!doctype html><style>html,body{margin:0;width:100%;height:100%;background:#111312;overflow:hidden}canvas{position:absolute;width:min(50vw,100vh);left:50%;top:50%;transform:translate(-50%,-50%)}</style><canvas></canvas>
<script type="module">
import cloudSea, { meta } from "https://ascii.rest/pieces/cloud-sea.js";
const FPS = 15, BG = [0x11, 0x13, 0x12].map((v) => v / 255);
const { cols, rows, palette } = meta;
const frame = cloudSea();
const color = new Uint8Array(cols * rows);
const cells = new Uint8Array(cols * rows * 2);
const step = { 32: 0, 0xb7: 1, 0x2022: 2, 0x25cf: 3 };

const canvas = document.querySelector("canvas");
canvas.style.aspectRatio = `${cols} / ${rows}`;
const gl = canvas.getContext("webgl2", { alpha: false, antialias: false, depth: false, powerPreference: "low-power" });

// The three dot glyphs, white on clear, one cell each, as the original draws them: font at cell / 0.6, centred, clipped.
const glyphs = (px) => {
  const a = document.createElement("canvas");
  a.width = px * 4; a.height = px;
  const c = a.getContext("2d");
  c.font = `${px / 0.6}px ui-monospace, SFMono-Regular, Menlo, monospace`;
  c.textAlign = "center"; c.textBaseline = "middle"; c.fillStyle = "#fff";
  [" ", "·", "•", "●"].forEach((g, i) => { c.save(); c.beginPath(); c.rect(i * px, 0, px, px); c.clip(); c.fillText(g, i * px + px / 2, px / 2); c.restore(); });
  return a;
};

const sh = (type, src) => { const s = gl.createShader(type); gl.shaderSource(s, src); gl.compileShader(s); return s; };
const prog = gl.createProgram();
gl.attachShader(prog, sh(gl.VERTEX_SHADER, `#version 300 es
in vec2 p; out vec2 uv;
void main() { uv = vec2(p.x, -p.y) * 0.5 + 0.5; gl_Position = vec4(p, 0, 1); }`));
gl.attachShader(prog, sh(gl.FRAGMENT_SHADER, `#version 300 es
precision mediump float;
in vec2 uv; out vec4 o;
uniform mediump usampler2D cells; uniform sampler2D atlas; uniform vec3 pal[${palette.length}], bg; uniform vec2 grid;
void main() {
  vec2 g = uv * grid, f = fract(g);
  uvec2 c = texelFetch(cells, ivec2(g), 0).rg;
  float a = c.r == 0u ? 0.0 : texture(atlas, vec2((float(c.r) + f.x) / 4.0, f.y)).a;
  // the page's edge fades: 10% at the sides, 12% top and bottom
  a *= smoothstep(0.0, 0.1, min(uv.x, 1.0 - uv.x)) * smoothstep(0.0, 0.12, min(uv.y, 1.0 - uv.y));
  o = vec4(mix(bg, pal[c.g], a), 1);
}`));
gl.linkProgram(prog);
gl.useProgram(prog);
gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer());
gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), gl.STATIC_DRAW);
gl.enableVertexAttribArray(0);
gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 0, 0);
const hex = (s) => [1, 3, 5].map((i) => parseInt(s.slice(i, i + 2), 16) / 255);
gl.uniform3fv(gl.getUniformLocation(prog, "pal"), palette.flatMap(hex));
gl.uniform3fv(gl.getUniformLocation(prog, "bg"), BG);
gl.uniform2f(gl.getUniformLocation(prog, "grid"), cols, rows);
gl.uniform1i(gl.getUniformLocation(prog, "cells"), 0);
gl.uniform1i(gl.getUniformLocation(prog, "atlas"), 1);
gl.pixelStorei(gl.UNPACK_ALIGNMENT, 1);

const cellTex = gl.createTexture();
gl.activeTexture(gl.TEXTURE0);
gl.bindTexture(gl.TEXTURE_2D, cellTex);
gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
gl.texStorage2D(gl.TEXTURE_2D, 1, gl.RG8UI, cols, rows);
const atlasTex = gl.createTexture();
gl.activeTexture(gl.TEXTURE1);
gl.bindTexture(gl.TEXTURE_2D, atlasTex);
gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

const size = () => {
  canvas.width = Math.round(canvas.clientWidth * devicePixelRatio);
  canvas.height = Math.round(canvas.width * rows / cols);
  gl.viewport(0, 0, canvas.width, canvas.height);
  gl.activeTexture(gl.TEXTURE1);
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, glyphs(Math.ceil(canvas.width / cols)));
  gl.activeTexture(gl.TEXTURE0);
};

let t = 0, timer = 0;
const draw = () => {
  const text = frame(t, { color, paper: false });
  for (let k = 0, i = 0; k < text.length; k++) {
    const c = text.charCodeAt(k);
    if (c === 10) continue;
    cells[i * 2] = step[c] ?? 0;
    cells[i * 2 + 1] = color[i];
    i++;
  }
  gl.texSubImage2D(gl.TEXTURE_2D, 0, 0, 0, cols, rows, gl.RG_INTEGER, gl.UNSIGNED_BYTE, cells);
  gl.drawArrays(gl.TRIANGLES, 0, 3);
};
const run = () => {
  clearInterval(timer);
  if (!document.hidden) timer = setInterval(() => { t += 1 / FPS; draw(); }, 1000 / FPS);
};
size(); draw(); run();
new ResizeObserver(() => { size(); draw(); }).observe(canvas);
const dpr = () => matchMedia(`(resolution: ${devicePixelRatio}dppx)`).addEventListener("change", () => { size(); draw(); dpr(); }, { once: true });
dpr();
document.addEventListener("visibilitychange", run);
</script>
"""#
// One wallpaper window per display, refitted whenever displays are added, removed, or change resolution.
var windows: [NSWindow] = []
func fit() {
    let screens = NSScreen.screens
    while windows.count > screens.count { windows.removeLast().close() }
    while windows.count < screens.count {
        let window = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = true
        let web = WKWebView(frame: .zero)
        web.autoresizingMask = [.width, .height]
        window.contentView = web
        web.loadHTMLString(html, baseURL: URL(string: "https://commonstudios.dk/"))
        windows.append(window)
    }
    for (window, screen) in zip(windows, screens) {
        window.setFrame(screen.frame, display: true)
        window.orderFrontRegardless()
    }
}
fit()
NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { _ in fit() }
app.run()
