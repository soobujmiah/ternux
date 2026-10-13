"""Stream SD1.5 CLIP tables from the authorized ZIP into anonymous memory.

Requires the Python `tokenizers` package. No ZIP member is extracted to disk.
The output is CLIP input_embedding, not the CLIP model's hidden state.
"""

import argparse
import hashlib
import os
import struct
import zipfile
from pathlib import Path

from clip_conditioning import ROWS, WIDTH, build_input, padded_ids


PREFIX = "output_512/qnn_models_8gen2/"
EXPECTED_SIZES = {
    "tokenizer.json": 3642034,
    "token_emb.bin": 75890688,
    "pos_emb.bin": 236544,
}
EXPECTED_SHA256 = {
    "tokenizer.json": "5f120510b5c01ccdb9a7d29d2beca07cac667f76472cab123ffb1c2f0b27cdeb",
    "token_emb.bin": "dfd2e186ff1db4a808516b8c26e920a2050e79cc4e4f86eeec3fdaa1ae5dc749",
    "pos_emb.bin": "a48c4b7bdf7359ba9e28042f18fc5e2670a588f03809a35df5c32da6fac61b89",
}


def stream_memfd(archive, name):
    member = PREFIX + name
    if archive.getinfo(member).file_size != EXPECTED_SIZES[name]:
        raise ValueError(f"unexpected size for {member}")
    fd = os.memfd_create("ternux-clip-" + name, flags=0)
    try:
        digest = hashlib.sha256()
        with archive.open(member) as source, os.fdopen(os.dup(fd), "wb") as target:
            while chunk := source.read(1024 * 1024):
                digest.update(chunk)
                target.write(chunk)
        if digest.hexdigest() != EXPECTED_SHA256[name]:
            raise ValueError(f"unexpected SHA-256 for {member}")
        return fd
    except BaseException:
        os.close(fd)
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--output", type=Path, required=True,
                        help="new scratch path for 77x768 FP32 binary")
    args = parser.parse_args()
    try:
        from tokenizers import Tokenizer
    except ImportError as error:
        parser.error(f"Python tokenizers package is required: {error}")

    with zipfile.ZipFile(args.archive) as archive:
        tokenizer_name = PREFIX + "tokenizer.json"
        if archive.getinfo(tokenizer_name).file_size != EXPECTED_SIZES["tokenizer.json"]:
            raise ValueError("unexpected tokenizer size")
        tokenizer_blob = archive.read(tokenizer_name)
        if hashlib.sha256(tokenizer_blob).hexdigest() != EXPECTED_SHA256["tokenizer.json"]:
            raise ValueError("unexpected tokenizer SHA-256")
        tokenizer = Tokenizer.from_str(tokenizer_blob.decode("utf-8"))
        content_ids = tokenizer.encode(args.prompt, add_special_tokens=False).ids
        ids = padded_ids(content_ids)
        token_fd = stream_memfd(archive, "token_emb.bin")
        try:
            pos_fd = stream_memfd(archive, "pos_emb.bin")
            try:
                values = build_input(content_ids, Path(f"/proc/self/fd/{token_fd}"),
                                     Path(f"/proc/self/fd/{pos_fd}"))
            finally:
                os.close(pos_fd)
        finally:
            os.close(token_fd)

    payload = struct.pack(f"<{ROWS * WIDTH}f", *values)
    with args.output.open("xb") as output:
        output.write(payload)
    print("content_ids", content_ids)
    print("first_ids", ids[:min(len(content_ids) + 2, ROWS)])
    print("shape", [1, ROWS, WIDTH], "dtype", "float32")
    print("bytes", len(payload), "sha256", hashlib.sha256(payload).hexdigest())


if __name__ == "__main__":
    main()
