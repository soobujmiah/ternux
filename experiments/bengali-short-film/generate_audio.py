#!/usr/bin/env python3
"""The film's soundtrack: ambience, crowd, spot effects, and the dialogue.

Everything except the dialogue is synthesised here with the standard library,
deterministically. The dialogue is the MMS-TTS Bengali output, already pitched
per character, and is simply placed at its cue. Levels are kept well under the
dialogue so speech stays in front.

    python3 generate_audio.py out.wav
"""

import json
import math
import os
import struct
import sys
import wave

RATE = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(HERE, "..", "assets")
DURATION = 60.0


class Noise:
    def __init__(self, seed=20261014):
        self.s = seed

    def __call__(self):
        self.s = (1103515245 * self.s + 12345) & 0x7FFFFFFF
        return self.s / 0x3FFFFFFF - 1.0


buf = [0.0] * int(DURATION * RATE + RATE)
rnd = Noise()


def env(i, n, attack, release):
    a = max(1, int(attack * RATE))
    r = max(1, int(release * RATE))
    if i < a:
        return i / a
    if i > n - r:
        x = (n - i) / r
        return x * x
    return 1.0


def noise_band(t0, dur, amp, cut0, cut1, attack=0.02, release=None):
    release = dur * 0.4 if release is None else release
    n, start, lp = int(dur * RATE), int(t0 * RATE), 0.0
    for i in range(n):
        x = i / n
        c = min(0.9, max(0.001, (cut0 * (1 - x) + cut1 * x) / 6000.0))
        lp += c * (rnd() - lp)
        j = start + i
        if 0 <= j < len(buf):
            buf[j] += amp * env(i, n, attack, release) * lp


def tone(t0, dur, f0, amp, f1=None, harm=(1.0, 0.3), attack=0.01, release=None, vib=0.0, vr=6.0):
    release = dur * 0.5 if release is None else release
    n, start, ph = int(dur * RATE), int(t0 * RATE), 0.0
    for i in range(n):
        x = i / n
        f = f0 if f1 is None else f0 * (1 - x) + f1 * x
        if vib:
            f *= 1 + vib * math.sin(2 * math.pi * vr * i / RATE)
        ph += 2 * math.pi * f / RATE
        s = sum(h * math.sin(ph * (k + 1)) for k, h in enumerate(harm))
        j = start + i
        if 0 <= j < len(buf):
            buf[j] += amp * env(i, n, attack, release) * s


def place(path, t0, gain=1.0):
    w = wave.open(path, "rb")
    n, rate, ch = w.getnframes(), w.getframerate(), w.getnchannels()
    raw = w.readframes(n)
    data = struct.unpack(f"<{len(raw) // 2}h", raw)
    if ch == 2:
        data = data[0::2]
    start = int(t0 * RATE)
    if rate != RATE:                      # the voices are already 44.1 kHz
        ratio = rate / RATE
        data = [data[min(len(data) - 1, int(i * ratio))] for i in range(int(len(data) / ratio))]
    for i, s in enumerate(data):
        j = start + i
        if 0 <= j < len(buf):
            buf[j] += gain * s / 32768.0
    return len(data) / RATE


def ambience():
    """Open air: a wide low bed, plus distant traffic that never resolves."""
    n = int(DURATION * RATE)
    lp = 0.0
    for i in range(n):
        lp += 0.0016 * (rnd() - lp)
        buf[i] += 0.42 * lp
    for k in range(9):
        noise_band(2.0 + k * 6.3, 2.6, 0.030, 240, 90, attack=0.8, release=1.2)


def crowd_bed(start=0.0, end=DURATION, level=0.055):
    """A rally crowd: murmur that swells slightly and never becomes words."""
    t = start
    i = 0
    while t < end:
        dur = 1.4
        amp = level * (0.65 + 0.45 * math.sin(i * 0.7))
        noise_band(t, dur * 1.3, amp, 900, 420, attack=0.5, release=0.7)
        t += dur
        i += 1


def crowd_react(t0, amp=0.1):
    noise_band(t0, 1.6, amp, 1400, 500, attack=0.12, release=0.9)
    for k in range(5):
        tone(t0 + 0.1 * k, 0.5, 180 + 40 * k, 0.012, harm=(1.0, 0.4), attack=0.05)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ASSETS, "audio", "mix.wav")
    cues = json.load(open(os.path.join(ASSETS, "cues.json")))

    ambience()
    crowd_bed(0.0, 57.0)

    # scene 1: the rally comes up as the camera arrives
    crowd_react(1.2, 0.09)
    noise_band(0.0, 3.0, 0.05, 600, 300, attack=1.5, release=1.2)

    # the public-address system has a presence of its own
    tone(3.9, 0.22, 920, 0.035, f1=1180, harm=(1.0, 0.2), attack=0.02)

    # scene 3: the pipe gives way, then water keeps running underneath
    burst = [e for e in cues["events"] if e["id"] == "water_burst"][0]["start"]
    noise_band(burst - 0.1, 0.5, 0.26, 300, 2600, attack=0.01, release=0.3)
    noise_band(burst + 0.2, 1.4, 0.17, 3000, 1200, attack=0.05, release=0.8)
    t = burst + 0.6
    while t < 57.0:                       # the leak does not stop after the shot
        noise_band(t, 1.1, 0.030, 2600, 1500, attack=0.3, release=0.5)
        t += 1.0
    crowd_react(burst + 0.9, 0.11)

    # scene 4: the microphone is turned up — one short squeal, then more level
    mic = [e for e in cues["events"] if e["id"] == "mic_turn"][0]["start"]
    tone(mic, 0.65, 1750, 0.085, f1=2350, harm=(1.0, 0.45, 0.2), attack=0.03, release=0.35, vib=0.012, vr=5)
    tone(mic + 0.1, 0.5, 880, 0.04, f1=1020, harm=(1.0, 0.3), attack=0.05)
    crowd_react(mic + 0.8, 0.09)

    # the banner lets go
    ban = [e for e in cues["events"] if e["id"] == "banner_fall"][0]["start"]
    for k in range(4):
        noise_band(ban + 0.16 * k, 0.26, 0.085 - 0.016 * k, 1900, 700, attack=0.01, release=0.18)
    tone(ban + 0.55, 0.35, 120, 0.05, f1=80, harm=(1.0, 0.5), attack=0.01)
    crowd_react(ban + 0.7, 0.12)

    # scene 5: the crowd falls away under the child's question
    for k in range(26):
        t0 = 48.0 + k * 0.35
        noise_band(t0, 0.5, 0.045 * max(0.0, 1 - k / 24.0), 800, 380, attack=0.2, release=0.3)
    tone(56.6, 2.2, 146.8, 0.055, harm=(1.0, 0.25, 0.1), attack=0.6, release=1.4)
    tone(56.9, 2.0, 220.0, 0.035, harm=(1.0, 0.2), attack=0.8, release=1.2)

    # dialogue last, so it sits on top of everything
    log = []
    for c in cues["lines"]:
        p = os.path.join(ASSETS, "audio", "voice", f"{c['id']}.wav")
        gain = 1.25 if c["speaker"] == "politician" else 1.35
        dur = place(p, c["start"], gain=gain)
        log.append(f"{c['id']:10s} at {c['start']:6.2f}s  {dur:5.2f}s  gain {gain}")

    peak = max(abs(v) for v in buf) or 1.0
    gain = 0.92 / peak
    frames = bytearray()
    for v in buf[:int(DURATION * RATE)]:
        s = int(max(-1.0, min(1.0, v * gain)) * 32767)
        frames += struct.pack("<hh", s, s)
    with wave.open(out, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(bytes(frames))
    print("\n".join(log))
    print(f"MIX {out} {DURATION:.1f}s peak_before_norm={peak:.3f} gain={gain:.3f}")


if __name__ == "__main__":
    main()
