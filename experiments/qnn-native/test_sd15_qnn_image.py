"""Host-side tests for bounded QNN SD1.5 batching."""

from contextlib import contextmanager, redirect_stdout
import io
import json
from pathlib import Path
import tempfile
import types
import unittest
from unittest import mock
import zipfile

import numpy as np

import sd15_qnn_image as runner


class FakeProcess:
    def __init__(self):
        self.stdin = io.BytesIO()
        self.returncode = None

    def wait(self, timeout=None):
        self.returncode = 0
        return self.returncode

    def poll(self):
        return self.returncode

    def kill(self):
        self.returncode = -9


class QnnBatchTests(unittest.TestCase):
    def test_image_output_names_are_stable_and_create_only(self):
        base = Path("/tmp/landscape.png")
        self.assertEqual(runner._image_outputs(base, 1), [base])
        self.assertEqual(
            runner._image_outputs(base, 3),
            [Path("/tmp/landscape-001.png"), Path("/tmp/landscape-002.png"),
             Path("/tmp/landscape-003.png")],
        )
        self.assertEqual(runner._image_outputs(Path("/tmp/images"), 2),
                         [Path("/tmp/images-001.png"), Path("/tmp/images-002.png")])

    def test_batch_streams_and_starts_each_context_once(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive = root / "empty.zip"
            with zipfile.ZipFile(archive, "w"):
                pass
            outputs = runner._image_outputs(root / "image.png", 2)
            processes = {"--serve-unet": FakeProcess(), "--serve-decoder": FakeProcess()}
            ready = {
                "--serve-unet": {"kind": "unet", "output_scale": 1.0, "output_offset": 0},
                "--serve-decoder": {"kind": "decoder", "output_scale": 1.0, "output_offset": 0},
            }

            @contextmanager
            def fake_member_fd(_archive, member):
                digest = runner.UNET_SHA256 if member == "unet.bin" else runner.DECODER_SHA256
                yield 10, {"member": member, "sha256": digest, "bytes": 1, "seconds": 0.0}

            args = types.SimpleNamespace(
                count=2, steps=2, seed=20, negative_prompt="bad", prompt="scene", cfg=7.5,
            )
            stdout = io.StringIO()
            with (mock.patch.object(runner, "_clip_hidden", return_value=[
                    np.zeros(77 * 768, dtype=np.float32),
                    np.ones(77 * 768, dtype=np.float32),
                 ]) as clip,
                 mock.patch.object(runner, "member_fd", side_effect=fake_member_fd) as stream_member,
                 mock.patch.object(runner, "_start_server",
                                   side_effect=lambda _helper, _fd, mode, _runtime, _log:
                                   (processes[mode], ready[mode])) as start_server,
                 mock.patch.object(runner, "_qnn_run_unet",
                                   return_value=np.zeros((1, 4, 64, 64), dtype=np.float32)) as unet,
                 mock.patch.object(runner, "dpm_step",
                                   side_effect=lambda sample, *_args: (sample.copy(), sample.copy())),
                 mock.patch.object(runner, "_qnn_decode", return_value=b"pixels") as decode,
                 mock.patch.object(runner, "_write_png", return_value=("abc123", 42)) as write_png,
                 redirect_stdout(stdout)):
                runner._run_batch(args, archive, Path("helper"), root, outputs)

            self.assertEqual(clip.call_count, 1)
            self.assertEqual(stream_member.call_count, 2)
            self.assertEqual(start_server.call_count, 2)
            self.assertEqual(unet.call_count, 8)
            self.assertEqual(decode.call_count, 2)
            self.assertEqual(write_png.call_count, 2)
            events = [json.loads(line) for line in stdout.getvalue().splitlines()]
            completed = [event for event in events if event["stage"] == "image_complete"]
            self.assertEqual([event["path"] for event in completed], [str(p) for p in outputs])
            self.assertEqual([event["seed"] for event in completed], [20, 21])
            self.assertEqual([event["image_index"] for event in completed], [1, 2])
            self.assertTrue(all("image_work_seconds" in event for event in completed))
            self.assertNotIn("total_seconds", completed[0])
            self.assertEqual(processes["--serve-unet"].returncode, 0)
            self.assertEqual(processes["--serve-decoder"].returncode, 0)


if __name__ == "__main__":
    unittest.main()
