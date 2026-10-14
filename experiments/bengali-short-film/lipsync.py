#!/usr/bin/env python3
"""Turn each dialogue recording into a per-frame mouth-opening curve.

There is no phoneme aligner here, so the mouth is driven by the speech it is
actually saying: the RMS envelope of the rendered voice, sampled at the film's
frame rate, smoothed, and normalised. Loud vowels open the mouth, consonant
gaps close it, and silence closes it completely.
"""

import json
import math
import os
import struct
import sys
import wave

FPS = 24


def envelope(path, fps=FPS):
    w = wave.open(path, "rb")
    n, rate, ch = w.getnframes(), w.getframerate(), w.getnchannels()
    raw = w.readframes(n)
    data = struct.unpack(f"<{len(raw) // 2}h", raw)
    if ch == 2:
        data = data[0::2]
        n = len(data)
    step = rate / fps
    frames = int(n / step)
    vals = []
    for i in range(frames):
        a, b = int(i * step), int((i + 1) * step)
        chunk = data[a:b] or (0,)
        vals.append(math.sqrt(sum(x * x for x in chunk) / len(chunk)) / 32767.0)
    peak = max(vals) or 1.0
    vals = [v / peak for v in vals]
    # attack fast, release slower: a mouth closes more slowly than it opens
    out, prev = [], 0.0
    for v in vals:
        prev = v if v > prev else prev * 0.55 + v * 0.45
        out.append(round(min(1.0, prev ** 0.75), 4))
    return out


def main():
    lines = json.load(open(sys.argv[1]))
    voice_dir = sys.argv[2]
    out_path = sys.argv[3]
    data = {}
    for ln in lines:
        p = os.path.join(voice_dir, f"{ln['id']}.wav")
        env = envelope(p)
        data[ln["id"]] = dict(speaker=ln["speaker"], scene=ln["scene"],
                              frames=len(env), seconds=round(len(env) / FPS, 3),
                              openness=env)
        print(f"{ln['id']:10s} {len(env):4d} frames  {len(env)/FPS:5.2f}s  "
              f"mean={sum(env)/len(env):.2f}")
    json.dump(data, open(out_path, "w"))


if __name__ == "__main__":
    main()
