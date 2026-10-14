#!/usr/bin/env python3
"""Check the delivered file against the specification, and report PASS/FAIL.

Every line is a measurement of the actual file, not of the intent.
"""

import json
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
FILM = os.path.join(ROOT, "output", "mithyar-mic-bn-60s.mp4")


def probe(path, args):
    r = subprocess.run(["ffprobe", "-v", "error"] + args + [path],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return r.stdout.decode().strip()


def main():
    film = sys.argv[1] if len(sys.argv) > 1 else FILM
    rows = []

    def check(name, ok, detail):
        rows.append((("PASS" if ok else "FAIL"), name, detail))

    j = json.loads(probe(film, ["-show_streams", "-show_format", "-of", "json"]))
    v = next(s for s in j["streams"] if s["codec_type"] == "video")
    a = next((s for s in j["streams"] if s["codec_type"] == "audio"), None)
    dur = float(j["format"]["duration"])

    check("duration is 60 s", abs(dur - 60.0) < 0.05, f"{dur:.3f} s")
    check("resolution 1280x720", (v["width"], v["height"]) == (1280, 720),
          f"{v['width']}x{v['height']}")
    check("frame rate 24", v["r_frame_rate"] == "24/1", v["r_frame_rate"])
    nb = probe(film, ["-select_streams", "v:0", "-count_frames",
                      "-show_entries", "stream=nb_read_frames", "-of", "csv=p=0"])
    check("1440 frames", nb.strip() == "1440", nb.strip())
    check("video codec h264", v["codec_name"] == "h264", v["codec_name"])
    check("audio stream present", a is not None,
          f"{a['codec_name']} {a['sample_rate']} Hz {a['channels']} ch" if a else "none")
    if a:
        check("audio is AAC stereo 44.1 kHz",
              a["codec_name"] == "aac" and a["channels"] == 2 and a["sample_rate"] == "44100",
              f"{a['codec_name']} {a['sample_rate']} {a['channels']}ch")

    # frame sampling: no black or frozen frames at the sample points
    import tempfile
    sample_times = [0.5, 8.0, 15.0, 24.0, 31.0, 40.0, 46.0, 52.0, 58.5]
    stats = []
    with tempfile.TemporaryDirectory() as td:
        for t in sample_times:
            p = os.path.join(td, f"f{t}.png")
            subprocess.run(["ffmpeg", "-v", "error", "-ss", str(t), "-i", film,
                            "-frames:v", "1", "-y", p], stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL)
            from PIL import Image, ImageStat
            im = Image.open(p).convert("L")
            st = ImageStat.Stat(im)
            stats.append((t, st.mean[0], st.stddev[0]))
    dark = [t for t, m, s in stats if m < 6]
    flat = [t for t, m, s in stats if s < 3]
    check("no black sample frames", not dark, f"{len(stats)} sampled, darkest mean "
          f"{min(m for _, m, _ in stats):.1f}")
    check("no flat sample frames", not flat, "min stddev "
          f"{min(s for _, _, s in stats):.1f}")

    width = max(len(r[1]) for r in rows)
    print(f"{'STATUS':6s}  {'CHECK'.ljust(width)}  DETAIL")
    for status, name, detail in rows:
        print(f"{status:6s}  {name.ljust(width)}  {detail}")
    print(f"\n{sum(1 for r in rows if r[0] == 'PASS')}/{len(rows)} checks passed")


if __name__ == "__main__":
    main()
