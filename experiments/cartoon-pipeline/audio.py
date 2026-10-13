#!/usr/bin/env python3
"""Synthesise the film's soundtrack: music bed, ambience and spot effects.

Pure standard library, so the pipeline needs nothing beyond Blender and ffmpeg.
Every generator is deterministic — the noise source is a seeded LCG — so the
same checkout produces the same WAV byte for byte.

    python3 audio.py out/audio.wav
"""

import math
import struct
import sys
import wave

RATE = 44100
FPS = 24
SHOT_FRAMES = [144, 144, 168, 192]

# Absolute start time of each shot, in seconds.
SHOT_START = []
_acc = 0
for _n in SHOT_FRAMES:
    SHOT_START.append(_acc / FPS)
    _acc += _n
DURATION = _acc / FPS


def at(shot, frame):
    """Absolute seconds for a frame inside a shot (1-based, as Blender counts)."""
    return SHOT_START[shot - 1] + (frame - 1) / FPS


class Noise:
    """Deterministic white noise, so the soundtrack is reproducible."""

    def __init__(self, seed=20261014):
        self.state = seed

    def __call__(self):
        self.state = (1103515245 * self.state + 12345) & 0x7FFFFFFF
        return self.state / 0x3FFFFFFF - 1.0


buf = [0.0] * int(DURATION * RATE + RATE)
noise = Noise()


def _env(i, n, attack, release):
    """Linear attack, flat body, exponential-ish release."""
    a = max(1, int(attack * RATE))
    r = max(1, int(release * RATE))
    if i < a:
        return i / a
    if i > n - r:
        x = (n - i) / r
        return x * x
    return 1.0


def tone(t0, dur, freq, amp=0.2, freq_end=None, harm=(1.0, 0.25, 0.1),
         attack=0.01, release=None, vibrato=0.0, vib_rate=6.0):
    """An additive-harmonic voice with an optional pitch glide and vibrato."""
    release = dur * 0.5 if release is None else release
    n = int(dur * RATE)
    start = int(t0 * RATE)
    phase = 0.0
    for i in range(n):
        x = i / n
        f = freq if freq_end is None else freq * (1 - x) + freq_end * x
        if vibrato:
            f *= 1.0 + vibrato * math.sin(2 * math.pi * vib_rate * i / RATE)
        phase += 2 * math.pi * f / RATE
        s = sum(h * math.sin(phase * (k + 1)) for k, h in enumerate(harm))
        j = start + i
        if 0 <= j < len(buf):
            buf[j] += amp * _env(i, n, attack, release) * s


def hit(t0, dur, amp=0.3, cutoff=0.25, tone_freq=None):
    """Filtered noise, for thumps, whooshes and leaf rustle."""
    n = int(dur * RATE)
    start = int(t0 * RATE)
    lp = 0.0
    phase = 0.0
    for i in range(n):
        lp += cutoff * (noise() - lp)
        s = lp
        if tone_freq:
            phase += 2 * math.pi * tone_freq / RATE
            s = 0.6 * lp + 0.4 * math.sin(phase)
        j = start + i
        if 0 <= j < len(buf):
            buf[j] += amp * _env(i, n, 0.004, dur * 0.8) * s


def whoosh(t0, dur, f0=900, f1=180, amp=0.22):
    """A noise band whose centre frequency sweeps — motion, not impact."""
    n = int(dur * RATE)
    start = int(t0 * RATE)
    lp = 0.0
    for i in range(n):
        x = i / n
        cutoff = min(0.9, max(0.02, (f0 * (1 - x) + f1 * x) / 4000.0))
        lp += cutoff * (noise() - lp)
        j = start + i
        if 0 <= j < len(buf):
            buf[j] += amp * _env(i, n, dur * 0.25, dur * 0.5) * lp


def boing(t0, amp=0.3, f_start=520, f_end=120, dur=0.55):
    """The spring: a fast downward glide with heavy vibrato."""
    tone(t0, dur, f_start, amp=amp, freq_end=f_end, harm=(1.0, 0.4, 0.2),
         attack=0.005, release=dur * 0.6, vibrato=0.22, vib_rate=15)


def chirp(t0, amp=0.12, f0=1800, f1=2600, dur=0.12):
    tone(t0, dur, f0, amp=amp, freq_end=f1, harm=(1.0, 0.15), attack=0.01, release=dur * 0.6)


def bell(t0, freq, amp=0.16, dur=0.9):
    tone(t0, dur, freq, amp=amp, harm=(1.0, 0.0, 0.35, 0.0, 0.12),
         attack=0.004, release=dur * 0.9)


# --------------------------------------------------------------------- music

MAJOR_PENT = [0, 2, 4, 7, 9, 12, 14, 16]          # C D E G A C D E
ROOT = 261.63                                      # C4


def note_hz(step, octave=0):
    return ROOT * (2 ** ((MAJOR_PENT[step % len(MAJOR_PENT)] + 12 * octave) / 12.0))


def music():
    """A light pentatonic bed: bass on the bar, a melody phrase per shot, and a
    soft tick on the beat so the cut has a pulse to sit against."""
    beat = 0.5                                     # 120 bpm
    bars = int(DURATION / (beat * 4)) + 1
    melody = [0, 2, 4, 2, 5, 4, 2, 0, 3, 4, 5, 4, 2, 1, 0, 2]
    for bar in range(bars):
        t = bar * beat * 4
        if t > DURATION:
            break
        root = [0, 3, 4, 2][bar % 4]
        tone(t, beat * 2.6, note_hz(root, -2), amp=0.085, harm=(1.0, 0.18),
             attack=0.02, release=beat * 1.8)
        for b in range(4):
            tb = t + b * beat
            if tb > DURATION:
                break
            hit(tb, 0.05, amp=0.035, cutoff=0.5)
            step = melody[(bar * 4 + b) % len(melody)]
            # the melody thins out under the loud shots and returns for the end
            amp = 0.075 if tb < at(3, 40) or tb > at(4, 60) else 0.035
            tone(tb + 0.02, beat * 0.85, note_hz(step, 0), amp=amp,
                 harm=(1.0, 0.22, 0.08), attack=0.012, release=beat * 0.6)


def ambience():
    """Wind under everything, with a few distant birds."""
    n = int(DURATION * RATE)
    lp = 0.0
    for i in range(n):
        lp += 0.0022 * (noise() - lp)
        buf[i] += 0.5 * lp
    for t, f0, f1 in [(1.6, 2100, 2500), (4.9, 2400, 1900), (9.3, 2000, 2600),
                      (16.1, 2300, 2000), (21.0, 2200, 2700), (25.4, 2500, 2100)]:
        chirp(t, amp=0.05, f0=f0, f1=f1, dur=0.1)
        chirp(t + 0.14, amp=0.035, f0=f1, f1=f0 + 200, dur=0.08)


# ----------------------------------------------------------------------- sfx

def effects():
    # Shot 1 — the drop and the landing
    whoosh(at(1, 1), 0.46, f0=420, f1=1500, amp=0.26)
    hit(at(1, 12), 0.30, amp=0.42, cutoff=0.06, tone_freq=62)      # the thump
    hit(at(1, 12), 0.09, amp=0.18, cutoff=0.9)                      # its click
    boing(at(1, 16), amp=0.14, f_start=300, f_end=190, dur=0.3)     # the rebound
    for f in (54, 120):                                             # blinks
        hit(at(1, f), 0.04, amp=0.05, cutoff=0.8)
    bell(at(1, 78), 1174.7, amp=0.17)                               # he sees it
    bell(at(1, 82), 1567.9, amp=0.12)

    # Shot 2 — two hops and a reach the flower keeps dodging
    for start, land in ((8, 32), (46, 70)):
        whoosh(at(2, start + 5), 0.3, f0=300, f1=900, amp=0.13)
        hit(at(2, land), 0.22, amp=0.3, cutoff=0.08, tone_freq=78)
        hit(at(2, land), 0.07, amp=0.12, cutoff=0.9)
    tone(at(2, 92), 0.9, 160, amp=0.1, freq_end=230, harm=(1.0, 0.3),
         attack=0.1, release=0.5, vibrato=0.04, vib_rate=5)          # the stretch
    for f in (108, 126):                                             # the dodges
        whoosh(at(2, f), 0.26, f0=1400, f1=600, amp=0.1)

    # Shot 3 — the grab, the pull, the snap and the fall
    hit(at(3, 14), 0.08, amp=0.14, cutoff=0.7)                       # the grab
    tone(at(3, 18), 1.2, 120, amp=0.11, freq_end=260, harm=(1.0, 0.35, 0.12),
         attack=0.2, release=0.4, vibrato=0.05, vib_rate=7)          # the pull
    boing(at(3, 53), amp=0.38, f_start=640, f_end=110, dur=0.7)      # the snap
    hit(at(3, 54), 0.26, amp=0.4, cutoff=0.1, tone_freq=150)         # the bonk
    whoosh(at(3, 56), 0.45, f0=1200, f1=400, amp=0.16)               # the spin
    hit(at(3, 84), 0.34, amp=0.42, cutoff=0.05, tone_freq=54)        # he lands
    for i, f in enumerate(range(100, 130, 8)):                       # dizzy
        tone(at(3, f), 0.42, 320 if i % 2 == 0 else 250, amp=0.07,
             harm=(1.0, 0.2), attack=0.03, release=0.3, vibrato=0.1, vib_rate=9)
    hit(at(3, 118), 0.04, amp=0.05, cutoff=0.8)
    bell(at(3, 160), 987.8, amp=0.1)

    # Shot 4 — the bloom and the exit
    for i, f in enumerate(range(22, 62, 6)):                         # it opens
        bell(at(4, f), note_hz(i % 6, 1), amp=0.085, dur=0.75)
    hit(at(4, 58), 0.12, amp=0.1, cutoff=0.6)                        # the pop
    chirp(at(4, 46), amp=0.1, f0=900, f1=1700, dur=0.16)             # his delight
    for f in (72, 88, 104):                                          # three bounces
        hit(at(4, f + 12), 0.18, amp=0.22, cutoff=0.1, tone_freq=90)
        chirp(at(4, f + 2), amp=0.07, f0=1300, f1=1900, dur=0.1)
    for f in range(128, 152, 7):                                     # the wave
        whoosh(at(4, f), 0.16, f0=900, f1=500, amp=0.07)
    whoosh(at(4, 168), 0.5, f0=250, f1=1400, amp=0.2)                # and away
    bell(at(4, 176), 1318.5, amp=0.13)
    bell(at(4, 182), 1760.0, amp=0.11)


def write(path):
    music()
    ambience()
    effects()
    peak = max(abs(v) for v in buf) or 1.0
    gain = 0.89 / peak
    frames = bytearray()
    for v in buf[:int(DURATION * RATE)]:   # the buffer carries a second of slack
        s = int(max(-1.0, min(1.0, v * gain)) * 32767)
        frames += struct.pack("<hh", s, s)
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(bytes(frames))
    print(f"AUDIO {path} {DURATION:.2f}s peak_before_norm={peak:.3f}")


if __name__ == "__main__":
    write(sys.argv[1] if len(sys.argv) > 1 else "out/audio.wav")
