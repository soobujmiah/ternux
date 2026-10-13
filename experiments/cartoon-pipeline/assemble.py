#!/usr/bin/env python3
"""Cut the rendered shots together and lay the soundtrack under them.

    python3 assemble.py [out_dir]

Each shot is encoded on its own, the shots are concatenated without re-encoding,
and the audio is muxed in last, so a re-cut never re-renders a frame.
"""

import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
FPS = 24
SHOTS = (1, 2, 3, 4)


def run(cmd):
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "out")
    parts = []
    for shot in SHOTS:
        frames = os.path.join(out, f"shot{shot}")
        count = len([f for f in os.listdir(frames) if f.endswith(".png")])
        part = os.path.join(out, f"shot{shot}.mp4")
        run(["ffmpeg", "-y", "-framerate", str(FPS), "-i", os.path.join(frames, "f_%04d.png"),
             "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p", part])
        parts.append(part)
        print(f"shot {shot}: {count} frames -> {os.path.basename(part)}")

    listing = os.path.join(out, "shots.txt")
    with open(listing, "w") as fh:
        for p in parts:
            fh.write(f"file '{p}'\n")
    silent = os.path.join(out, "picture.mp4")
    run(["ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", listing, "-c", "copy", silent])

    final = os.path.join(out, "bulbul-and-the-stubborn-flower.mp4")
    run(["ffmpeg", "-y", "-i", silent, "-i", os.path.join(out, "audio.wav"),
         "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-shortest", final])
    size = os.path.getsize(final) / 1e6
    print(f"FILM {final} {size:.1f} MB")


if __name__ == "__main__":
    main()
