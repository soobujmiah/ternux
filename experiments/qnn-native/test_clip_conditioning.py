import importlib.util
import struct
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("clip_conditioning.py")
SPEC = importlib.util.spec_from_file_location("clip_conditioning", MODULE_PATH)
clip = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(clip)


class ClipConditioningTest(unittest.TestCase):
    def test_special_tokens_and_padding(self):
        ids = clip.padded_ids([12, 34])
        self.assertEqual(len(ids), 77)
        self.assertEqual(ids[:4], [49406, 12, 34, 49407])
        self.assertTrue(all(x == 49407 for x in ids[3:]))
        with self.assertRaises(ValueError):
            clip.padded_ids([1] * 76)

    def test_fp16_lookup_weight_and_position(self):
        with tempfile.TemporaryDirectory() as temp:
            token_path = Path(temp) / "token_emb.bin"
            pos_path = Path(temp) / "pos_emb.bin"
            # Sparse synthetic tables exercise real SD1.5 offsets and sizes.
            with token_path.open("wb") as table:
                table.truncate(clip.TABLE_ELEMENTS * 2)
            with token_path.open("r+b") as table:
                for token_id, value in [(clip.BOS, 1.5), (7, 2.0), (clip.EOS, 3.0)]:
                    table.seek(token_id * clip.WIDTH * 2)
                    table.write(struct.pack(f"<{clip.WIDTH}e", *([value] * clip.WIDTH)))
            with pos_path.open("wb") as table:
                for row in range(clip.ROWS):
                    table.write(struct.pack(f"<{clip.WIDTH}f", *([row / 10] * clip.WIDTH)))
            weights = [1.0] * clip.ROWS
            weights[1] = 0.5
            result = clip.build_input([7], token_path, pos_path, weights)
            self.assertEqual(len(result), clip.ROWS * clip.WIDTH)
            self.assertEqual(result[0], 1.5)
            self.assertAlmostEqual(result[clip.WIDTH], 1.1, places=6)
            self.assertAlmostEqual(result[2 * clip.WIDTH], 3.2, places=6)
            self.assertAlmostEqual(result[76 * clip.WIDTH], 10.6, places=6)

    def test_legacy_fp32_table_is_narrowed_before_lookup(self):
        with tempfile.TemporaryDirectory() as temp:
            token_path = Path(temp) / "token_emb.bin"
            pos_path = Path(temp) / "pos_emb.bin"
            with token_path.open("wb") as table:
                table.truncate(clip.TABLE_ELEMENTS * 4)
            with token_path.open("r+b") as table:
                table.seek(clip.BOS * clip.WIDTH * 4)
                table.write(struct.pack("<f", 1.0001))
            with pos_path.open("wb") as table:
                table.truncate(clip.ROWS * clip.WIDTH * 4)
            result = clip.build_input([], token_path, pos_path)
            self.assertEqual(result[0], 1.0)


if __name__ == "__main__":
    unittest.main()
