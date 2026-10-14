# মিথ্যার মাইক — a 60-second Bengali film, rendered on the phone

A complete narrative short produced end to end on a Redmi Turbo 4 Pro under
ternux: five scenes cut into twelve shots, 1,440 frames at 1280×720, Bengali
dialogue, synchronised mouths, burnt-in Bengali captions and a synthesised
soundtrack. It is kept here as evidence of what the workstation can carry, and
as a starting point for doing it again.

Nothing is modelled by hand and no asset is downloaded except the speech model:
the characters, the rally and every sound come out of these scripts.

## What it needs

| Piece | Install | Why |
|---|---|---|
| Blender 4.3.2 | `--with-blender` | EEVEE Next is the only GPU engine on Adreno |
| `xvfb` | `sudo apt install -y xvfb` | a GL context without an X11 app on screen |
| `ffmpeg` | `sudo apt install -y ffmpeg` | encode, caption and mux |
| Python `onnxruntime` + `numpy` | a venv, ~22 MB | runs the Bengali speech model on the CPU |
| MMS-TTS Bengali ONNX | ~114 MB, see below | the voices |

The speech model is Meta's MMS-TTS Bengali (`facebook/mms-tts-ben`), used through
an ONNX export. **Its licence is CC-BY-NC-4.0: non-commercial use only.** A
commercial production has to replace the voice; nothing else in the pipeline
depends on it.

```sh
python3 -m venv tts/venv && tts/venv/bin/pip install onnxruntime numpy
mkdir -p tts/model && cd tts/model
for f in onnx/model.onnx tokenizer.json vocab.json config.json tokenizer_config.json; do
  curl -sL -O "https://huggingface.co/PRAMSSS/mms-tts-bengali-webgpu/resolve/main/$f"
done
```

## Produce it

```sh
tts/venv/bin/python tts.py assets/lines.json assets/audio/raw   # speech
sh voice_treatment.sh                                           # a voice per character
python3 lipsync.py assets/lines.json assets/audio/voice assets/lipsync.json
./render_all.sh                                                 # 1,440 frames, one process per scene
python3 generate_audio.py assets/audio/mix.wav                  # ambience, crowd, effects, dialogue
python3 subtitles.py assets/subs                                # shaped Bengali captions
python3 assemble_video.py                                       # encode, caption, mux
python3 validate_output.py                                      # measure the delivered file
```

## Measured, 2026-10-14

1,280×720, 16 samples, EEVEE Next, one Blender process per scene, rendered
headless on `Xvfb :9` with `GALLIUM_DRIVER=zink`.

| Scene | Frames | Blender render | Mean | First frame |
|---|---|---|---|---|
| 1 | 240 | 427.7 s | 1.782 s | 22.6 s |
| 2 | 288 | 501.3 s | 1.741 s | 9.3 s |
| 3 | 312 | 569.9 s | 1.826 s | 8.5 s |
| 4 | 312 | 633.4 s | 2.030 s | 13.0 s |
| 5 | 288 | 666.5 s | 2.314 s | 8.9 s |
| **All** | **1,440** | **2,798.8 s** | **1.944 s** | |

Peak Blender memory 459.1 MB. The first frame of each scene is slow because
shader compilation is paid once per process — a sequence must never be rendered
one process per frame.

An earlier pass of the same film at 24 samples, with two subdivision levels on
every body and a shadow-casting fill light, cost **3.22 s/frame and 713.7 MB**.
Dropping to 16 samples, one subdivision level below the neck, no shadow map on
the sky fill, and depth of field only in the shots that use it brought that to
1.944 s/frame with no visible loss at these shot sizes.

The delivered file measures 60.000 s, 1280×720, 24 fps, 1,440 frames, H.264 with
AAC stereo at 44.1 kHz — all nine checks in `validate_output.py` pass.

## How it is put together

| File | Role |
|---|---|
| `head.py` | skull, nose, lips and ears, lofted from anatomical cross-sections |
| `humans.py` | skin and eye shaders, hair, the assembled head, the full figure |
| `environment.py` | stage, podium, sound system, banner, street, water, props |
| `film.py` | cast, lighting, five scenes cut into twelve shots |
| `render_film.py` | render a scene, a still, or a frame range |
| `tts.py` | Bengali speech from MMS-TTS through onnxruntime |
| `lipsync.py` | per-frame mouth opening, from each line's own amplitude envelope |
| `generate_audio.py` | ambience, crowd, spot effects, and the dialogue mix |
| `subtitles.py` | shaped Bengali captions and the closing card |
| `assemble_video.py` | per-scene encode, concatenation, captions, audio mux |
| `validate_output.py` | measures the delivered file and prints PASS/FAIL |

## Things that cost a render to learn

- **Parent with the parent inverse, then place.** `attach()` preserves a child's
  world transform, so setting a character's root position *before* attaching its
  parts cancels the move exactly: the figure stays at the origin.
- **Aim cameras at a point, never at Euler angles by hand.** `film.aim()` inverts
  the camera's forward vector. Guessed angles put the first version of every shot
  tens of degrees off its subject.
- **Check who is standing in the sight-line.** A crowd figure between camera and
  subject reads as a translucent smear once it is far out of focus, not as a
  person, so it is easy to misread as a render artifact.
- **A banner swings from the corner it still hangs by.** Rotating it about the
  frame's centre throws it out of shot.
- **Captions are stills, and a still has one timestamp.** Fading one against the
  film's clock leaves it transparent for ever; the overlay's `enable` window is
  what does the timing.

## Honest limits

The characters are stylised, not photoreal: procedural geometry with
subsurface-scattering skin and shaped features, not sculpted or scanned humans.
Lip sync follows amplitude, not phonemes. The figures are posed through parented
pivots rather than a skinned armature. The speech model is non-commercial.
