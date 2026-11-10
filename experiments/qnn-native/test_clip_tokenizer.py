"""Offline unit tests for the archive's CLIP byte-level BPE tokenizer."""

import importlib.util
from pathlib import Path
import unittest


MODULE_PATH = Path(__file__).with_name("clip_tokenizer.py")
SPEC = importlib.util.spec_from_file_location("clip_tokenizer", MODULE_PATH)
clip = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(clip)


def config(vocab, merges):
    return {
        "normalizer": {
            "type": "Sequence",
            "normalizers": [
                {"type": "NFC"},
                {"type": "Replace", "pattern": {"Regex": r"\s+"}, "content": " "},
                {"type": "Lowercase"},
            ],
        },
        "pre_tokenizer": {
            "type": "Sequence",
            "pretokenizers": [
                {"type": "Split", "pattern": {"Regex":
                 r"'s|'t|'re|'ve|'m|'ll|'d|[\p{L}]+|[\p{N}]|[^\s\p{L}\p{N}]+"},
                 "behavior": "Removed", "invert": True},
                {"type": "ByteLevel", "add_prefix_space": False,
                 "trim_offsets": True, "use_regex": True},
            ],
        },
        "model": {
            "type": "BPE", "dropout": None, "unk_token": "<|endoftext|>",
            "continuing_subword_prefix": "", "end_of_word_suffix": "</w>",
            "fuse_unk": False, "byte_fallback": False, "ignore_merges": False,
            "vocab": vocab, "merges": merges,
        },
        "added_tokens": [
            {"id": 49406, "content": "<|startoftext|>", "special": True},
            {"id": 49407, "content": "<|endoftext|>", "special": True},
        ],
    }


class ClipTokenizerTests(unittest.TestCase):
    def setUp(self):
        self.tokenizer = clip.ClipBpeTokenizer(config({
            "<|endoftext|>": 49407,
            "a</w>": 320,
            "c": 1,
            "a": 2,
            "t</w>": 3,
            "ca": 4,
            "cat</w>": 2368,
            "it</w>": 10,
            "'s</w>": 11,
            "1</w>": 12,
            "2</w>": 13,
        }, [["c", "a"], ["ca", "t</w>"], ["i", "t</w>"], ["'", "s</w>"]]))

    def test_archive_known_answer_and_normalization(self):
        self.assertEqual(self.tokenizer.encode("a cat"), [320, 2368])
        self.assertEqual(self.tokenizer.encode("  A\tCAT  "), [320, 2368])

    def test_unicode_nfc_is_equivalent_to_decomposed_input(self):
        byte_encoder = clip.bytes_to_unicode()
        symbols = [byte_encoder[value] for value in "é".encode("utf-8")]
        symbols[-1] += "</w>"
        merges = []
        current = symbols[0]
        for symbol in symbols[1:]:
            merges.append([current, symbol])
            current += symbol
        tokenizer = clip.ClipBpeTokenizer(config({"<|endoftext|>": 49407, current: 90}, merges))
        self.assertEqual(tokenizer.encode("é"), [90])
        self.assertEqual(tokenizer.encode("e\u0301"), [90])

    def test_contractions_digits_and_special_tokens(self):
        self.assertEqual(self.tokenizer.encode("it's"), [10, 11])
        self.assertEqual(self.tokenizer.encode("12"), [12, 13])
        self.assertEqual(self.tokenizer.encode("<|endoftext|>"), [49407])

    def test_rejects_tokenizer_with_an_unexpected_normalizer(self):
        broken = config({"<|endoftext|>": 49407}, [])
        broken["normalizer"]["normalizers"].pop()
        with self.assertRaises(ValueError):
            clip.ClipBpeTokenizer(broken)


if __name__ == "__main__":
    unittest.main()
