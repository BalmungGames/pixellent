#!/usr/bin/env python3
"""
export_spritesheet.py — auxiliary batch export tool for Pixellent.

Called from GDScript (autoloads/ProjectFile.gd) via OS.execute() for operations
that are easier/cheaper to do outside the engine runtime with Pillow:

  --mode gif          Combine a PNG frame sequence into an animated GIF.
  --mode spritesheet  Combine a PNG frame sequence into a tiled spritesheet PNG.
  --mode optimize     Palette-quantize / strip metadata from a PNG to shrink size.

Requires: pip install pillow --break-system-packages

Usage:
  python3 export_spritesheet.py --mode gif --out anim.gif --fps 6 frame_0001.png frame_0002.png ...
  python3 export_spritesheet.py --mode spritesheet --out sheet.png --columns 4 frame_0001.png ...
  python3 export_spritesheet.py --mode optimize --out small.png source.png
"""

import argparse
import math
import sys

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow is not installed. Run: pip install pillow --break-system-packages", file=sys.stderr)
    sys.exit(1)


def cmd_gif(frames, out_path, fps):
    images = [Image.open(p).convert("RGBA") for p in frames]
    if not images:
        print("ERROR: no frames given", file=sys.stderr)
        return 1
    duration_ms = max(1, round(1000.0 / max(1, fps)))
    images[0].save(
        out_path,
        save_all=True,
        append_images=images[1:],
        duration=duration_ms,
        loop=0,
        disposal=2,
        transparency=0,
    )
    print(f"Wrote GIF: {out_path} ({len(images)} frames @ {fps}fps)")
    return 0


def cmd_spritesheet(frames, out_path, columns):
    images = [Image.open(p).convert("RGBA") for p in frames]
    if not images:
        print("ERROR: no frames given", file=sys.stderr)
        return 1
    fw, fh = images[0].size
    n = len(images)
    cols = columns if columns and columns > 0 else math.ceil(math.sqrt(n))
    rows = math.ceil(n / cols)
    sheet = Image.new("RGBA", (fw * cols, fh * rows), (0, 0, 0, 0))
    for i, img in enumerate(images):
        x = (i % cols) * fw
        y = (i // cols) * fh
        sheet.paste(img, (x, y), img)
    sheet.save(out_path)
    print(f"Wrote spritesheet: {out_path} ({cols}x{rows} grid, {fw}x{fh} per frame)")
    return 0


def cmd_optimize(frames, out_path):
    if len(frames) != 1:
        print("ERROR: optimize mode takes exactly one input PNG", file=sys.stderr)
        return 1
    img = Image.open(frames[0]).convert("RGBA")
    # Quantize to an adaptive palette while preserving alpha via a mask trick.
    alpha = img.getchannel("A")
    quantized = img.convert("RGB").quantize(colors=256, method=Image.MEDIANCUT)
    quantized = quantized.convert("RGBA")
    quantized.putalpha(alpha)
    quantized.save(out_path, optimize=True)
    print(f"Wrote optimized PNG: {out_path}")
    return 0


def main():
    parser = argparse.ArgumentParser(description="Pixellent batch export tool")
    parser.add_argument("--mode", required=True, choices=["gif", "spritesheet", "optimize"])
    parser.add_argument("--out", required=True, help="output file path")
    parser.add_argument("--fps", type=int, default=6, help="frames per second (gif mode)")
    parser.add_argument("--columns", type=int, default=0, help="grid columns (spritesheet mode)")
    parser.add_argument("frames", nargs="+", help="input PNG frame paths, in order")
    args = parser.parse_args()

    if args.mode == "gif":
        sys.exit(cmd_gif(args.frames, args.out, args.fps))
    elif args.mode == "spritesheet":
        sys.exit(cmd_spritesheet(args.frames, args.out, args.columns))
    elif args.mode == "optimize":
        sys.exit(cmd_optimize(args.frames, args.out))


if __name__ == "__main__":
    main()
