#!/usr/bin/env python3
"""Cut the five scenes together, burn in the Bengali captions, add the mix.

Each scene is encoded on its own and the scenes are concatenated without
re-encoding, so recutting never re-renders a frame. The captions are composited
from pre-shaped PNGs (see subtitles.py) rather than drawn by ffmpeg, which
cannot shape Bengali.

    python3 assemble_video.py
"""

import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, ".."))
FPS = 24
SCENES = (1, 2, 3, 4, 5)


def run(cmd, log=None):
    r = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if log:
        open(log, "ab").write(r.stdout)
    if r.returncode:
        sys.stdout.write(r.stdout.decode("utf-8", "replace")[-3000:])
        raise SystemExit(f"failed: {' '.join(cmd[:6])} ...")
    return r


def main():
    renders = os.path.join(ROOT, "renders")
    out_dir = os.path.join(ROOT, "output")
    os.makedirs(out_dir, exist_ok=True)
    log = os.path.join(ROOT, "logs", "assemble.log")
    open(log, "wb").close()

    picture = os.path.join(out_dir, "picture.mp4")
    if "--reuse-picture" in sys.argv and os.path.exists(picture):
        print("reusing", picture)
        _caption_and_mux(ROOT, out_dir, picture, log)
        return

    parts = []
    total = 0
    for n in SCENES:
        frames = os.path.join(renders, f"shot_{n:02d}")
        count = len([f for f in os.listdir(frames) if f.endswith(".png")])
        total += count
        part = os.path.join(out_dir, f"scene{n}.mp4")
        run(["ffmpeg", "-y", "-framerate", str(FPS), "-i", os.path.join(frames, "f_%04d.png"),
             "-c:v", "libx264", "-preset", "medium", "-crf", "17", "-pix_fmt", "yuv420p", part], log)
        parts.append(part)
        print(f"scene {n}: {count} frames")
    print(f"total frames: {total}")

    listing = os.path.join(out_dir, "scenes.txt")
    with open(listing, "w") as fh:
        for p in parts:
            fh.write(f"file '{p}'\n")
    run(["ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", listing, "-c", "copy", picture], log)
    _caption_and_mux(ROOT, out_dir, picture, log)


def _caption_and_mux(ROOT, out_dir, picture, log):
    # captions, each enabled over its own window
    overlays = json.load(open(os.path.join(ROOT, "assets", "subs", "overlays.json")))
    cmd = ["ffmpeg", "-y", "-i", picture]
    for o in overlays:
        cmd += ["-i", o["file"]]
    # Each caption is a single still. Its one frame carries timestamp zero, so a
    # fade keyed to the film's clock would leave it transparent for ever; the
    # overlay's own enable window does the timing instead.
    chain, prev = [], "[0:v]"
    for i, o in enumerate(overlays, start=1):
        label = f"[v{i}]"
        chain.append(
            f"[{i}:v]format=rgba[s{i}];"
            f"{prev}[s{i}]overlay=0:0:eof_action=repeat:"
            f"enable='between(t,{o['start']},{o['end']})'{label}")
        prev = label
    captioned = os.path.join(out_dir, "captioned.mp4")
    cmd += ["-filter_complex", ";".join(chain), "-map", prev, "-c:v", "libx264",
            "-preset", "medium", "-crf", "17", "-pix_fmt", "yuv420p", captioned]
    run(cmd, log)

    final = os.path.join(out_dir, "mithyar-mic-bn-60s.mp4")
    run(["ffmpeg", "-y", "-i", captioned, "-i", os.path.join(ROOT, "assets", "audio", "mix.wav"),
         "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-ar", "44100", "-shortest", final], log)
    print(f"FILM {final} {os.path.getsize(final) / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
