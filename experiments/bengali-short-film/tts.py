#!/usr/bin/env python3
"""Bengali speech with MMS-TTS (VITS) through onnxruntime, on the CPU.

The model is a character-level VITS: text is filtered to the model's own vocab,
a blank token is interleaved between every character, and the network returns a
16 kHz waveform directly. One speaker only, so the characters are separated
afterwards by pitch and rate with ffmpeg's rubberband filter.

    tts/venv/bin/python scripts/tts.py lines.json out_dir
"""

import json
import os
import struct
import sys
import wave

import numpy as np
import onnxruntime as ort

HERE = os.path.dirname(os.path.abspath(__file__))
MODEL = os.path.join(HERE, "..", "tts", "model")
RATE = 16000


class BengaliVits:
    def __init__(self, model_dir=MODEL):
        self.vocab = json.load(open(os.path.join(model_dir, "vocab.json")))
        cfg = json.load(open(os.path.join(model_dir, "tokenizer_config.json")))
        self.pad = self.vocab[str(cfg.get("pad_token", "6"))]
        opts = ort.SessionOptions()
        opts.intra_op_num_threads = 4
        self.sess = ort.InferenceSession(os.path.join(model_dir, "model.onnx"),
                                         sess_options=opts, providers=["CPUExecutionProvider"])

    def encode(self, text):
        ids = [self.vocab[c] for c in text if c in self.vocab]
        out = [self.pad]
        for i in ids:                      # add_blank: a pad between every token
            out += [i, self.pad]
        return out

    def say(self, text):
        ids = self.encode(text)
        a = np.array([ids], dtype=np.int64)
        mask = np.ones_like(a)
        wav = self.sess.run(["waveform"], {"input_ids": a, "attention_mask": mask})[0][0]
        peak = float(np.max(np.abs(wav))) or 1.0
        return (wav / peak * 0.82).astype(np.float32)


def write_wav(path, samples, rate=RATE):
    data = (np.clip(samples, -1.0, 1.0) * 32767).astype("<i2").tobytes()
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(data)


def main():
    lines = json.load(open(sys.argv[1]))
    out_dir = sys.argv[2]
    os.makedirs(out_dir, exist_ok=True)
    tts = BengaliVits()
    report = []
    for item in lines:
        wav = tts.say(item["text"])
        path = os.path.join(out_dir, f"{item['id']}.wav")
        write_wav(path, wav)
        dur = len(wav) / RATE
        rms = float(np.sqrt(np.mean(wav.astype(np.float64) ** 2)))
        report.append(dict(id=item["id"], chars=len(item["text"]), seconds=round(dur, 3),
                           rms=round(rms, 4), speaker=item.get("speaker", "")))
        print(f"{item['id']:12s} {dur:6.2f}s rms={rms:.3f}  {item['text'][:42]}")
    json.dump(report, open(os.path.join(out_dir, "timing.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
