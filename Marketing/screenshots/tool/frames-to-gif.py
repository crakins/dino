"""Assembles make-gif.mjs frames into a looping GIF with one shared palette (no per-frame flicker)."""
import glob, sys
from PIL import Image

src, out = sys.argv[1], sys.argv[2]
fps = int(sys.argv[3]) if len(sys.argv) > 3 else 20
frames = [Image.open(f).convert("RGB") for f in sorted(glob.glob(f"{src}/f*.png"))]
w, h = frames[0].size
# Build the palette from a spread of frames so the countdown and the run share it.
picks = frames[:: max(1, len(frames) // 16)]
atlas = Image.new("RGB", (w, h * len(picks)))
for i, f in enumerate(picks):
    atlas.paste(f, (0, i * h))
palette = atlas.quantize(colors=255, method=Image.Quantize.MEDIANCUT)
q = [f.quantize(palette=palette, dither=Image.Dither.NONE) for f in frames]
# Hold the last frame a moment before looping back to "3".
durations = [1000 // fps] * len(q)
durations[-1] = 900
q[0].save(out, save_all=True, append_images=q[1:], duration=durations, loop=0, optimize=True, disposal=1)
print(out, len(q), "frames")
