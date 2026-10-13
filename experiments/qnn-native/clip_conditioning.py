"""Build SD1.5 CLIP input_embedding rows from token IDs and embedding tables.

This is a CPU-side preparation step. It does not run the MNN CLIP model or
claim that a prompt has been encoded. The caller supplies content token IDs;
tokenization and prompt weighting remain separate concerns.
"""

import argparse
import json
import struct
from pathlib import Path


ROWS = 77
WIDTH = 768
BOS = 49406
EOS = 49407
VOCAB = 49408
TABLE_ELEMENTS = VOCAB * WIDTH


def padded_ids(content_ids):
    if len(content_ids) > ROWS - 2:
        raise ValueError("SD1.5 supports at most 75 content tokens per chunk")
    if any(not isinstance(x, int) or isinstance(x, bool) or x < 0 or x >= VOCAB
           for x in content_ids):
        raise ValueError("content token ID outside CLIP vocabulary")
    return [BOS, *content_ids, *([EOS] * (ROWS - len(content_ids) - 1))]


def _table_format(path):
    size = path.stat().st_size
    if size == TABLE_ELEMENTS * 2:
        return "e"
    if size == TABLE_ELEMENTS * 4:
        return "f"
    raise ValueError(f"unexpected token table size: {size} bytes")


def build_input(content_ids, token_table, position_table, weights=None):
    """Return 77*768 FP32 values, matching SD1.5 table narrowing semantics.

    A legacy FP32 token table is rounded to FP16 before lookup. The arithmetic
    is performed as FP32 operations. The caller may pass 77 position weights;
    without them every position uses weight 1.0.
    """
    ids = padded_ids(content_ids)
    weights = [1.0] * ROWS if weights is None else list(weights)
    if len(weights) != ROWS:
        raise ValueError("weights must have 77 entries")
    token_table = Path(token_table)
    position_table = Path(position_table)
    fmt = _table_format(token_table)
    if position_table.stat().st_size != ROWS * WIDTH * 4:
        raise ValueError("position table must have 77*768 FP32 values")
    result = []
    with token_table.open("rb") as token_file, position_table.open("rb") as pos_file:
        for row, token_id in enumerate(ids):
            token_file.seek(token_id * WIDTH * struct.calcsize(fmt))
            raw = token_file.read(WIDTH * struct.calcsize(fmt))
            if len(raw) != WIDTH * struct.calcsize(fmt):
                raise ValueError("short token table read")
            values = struct.unpack(f"<{WIDTH}{fmt}", raw)
            if fmt == "f":
                # The reference narrows a legacy FP32 table into FP16 memory.
                values = struct.unpack(f"<{WIDTH}e", struct.pack(f"<{WIDTH}e", *values))
            pos_raw = pos_file.read(WIDTH * 4)
            if len(pos_raw) != WIDTH * 4:
                raise ValueError("short position table read")
            positions = struct.unpack(f"<{WIDTH}f", pos_raw)
            weight = struct.unpack("<f", struct.pack("<f", weights[row]))[0]
            for token_value, pos_value in zip(values, positions):
                product = struct.unpack("<f", struct.pack("<f", token_value * weight))[0]
                result.append(struct.unpack("<f", struct.pack("<f", product + pos_value))[0])
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--content-ids-json", type=Path, required=True,
                        help="JSON array of already-tokenized content IDs")
    parser.add_argument("--token-emb", type=Path, required=True)
    parser.add_argument("--pos-emb", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True,
                        help="new binary FP32 input_embedding file")
    args = parser.parse_args()
    ids = json.loads(args.content_ids_json.read_text())
    if not isinstance(ids, list):
        parser.error("content IDs must be a JSON array")
    values = build_input(ids, args.token_emb, args.pos_emb)
    with args.output.open("xb") as output:
        for start in range(0, len(values), WIDTH):
            output.write(struct.pack(f"<{WIDTH}f", *values[start:start + WIDTH]))
    print(f"wrote {len(values)} FP32 values ({args.output.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
