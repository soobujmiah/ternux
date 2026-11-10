"""Small standard-library CLIP byte-level BPE tokenizer for the pinned SD1.5 model."""

import json
import unicodedata


_SUFFIX = "</w>"
_CONTRACTIONS = ("'s", "'t", "'re", "'ve", "'m", "'ll", "'d")
_SPLIT_PATTERN = r"'s|'t|'re|'ve|'m|'ll|'d|[\p{L}]+|[\p{N}]|[^\s\p{L}\p{N}]+"
# Unicode White_Space property used by the Rust regex tokenizer.
_WHITE_SPACE = frozenset(
    " \t\n\v\f\r\x85\u00a0\u1680\u2000\u2001\u2002\u2003"
    "\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u2028\u2029"
    "\u202f\u205f\u3000"
)


def bytes_to_unicode():
    """Return the reversible GPT-2 byte-to-visible-Unicode alphabet."""
    visible = list(range(ord("!"), ord("~") + 1))
    visible += list(range(ord("¡"), ord("¬") + 1))
    visible += list(range(ord("®"), ord("ÿ") + 1))
    codepoints = visible.copy()
    extra = 0
    for value in range(256):
        if value not in visible:
            visible.append(value)
            codepoints.append(256 + extra)
            extra += 1
    return {value: chr(codepoint) for value, codepoint in zip(visible, codepoints)}


def _category(ch):
    return unicodedata.category(ch)


def _is_letter(ch):
    return _category(ch).startswith("L")


def _is_number(ch):
    return _category(ch).startswith("N")


def _pieces(text, special_tokens):
    """Mirror the archive's Split(invert=True) and ByteLevel regex behavior."""
    index = 0
    while index < len(text):
        special = next((token for token in special_tokens
                        if text.startswith(token, index)), None)
        if special is not None:
            yield special_tokens[special]
            index += len(special)
            continue
        ch = text[index]
        if ch in _WHITE_SPACE:
            index += 1  # Split(behavior=Removed) drops whitespace.
            continue
        contraction = next((suffix for suffix in _CONTRACTIONS
                            if text.startswith(suffix, index)), None)
        if contraction is not None:
            yield contraction
            index += len(contraction)
            continue
        if _is_letter(ch):
            end = index + 1
            while end < len(text) and _is_letter(text[end]):
                end += 1
        elif _is_number(ch):
            end = index + 1  # The configured regex intentionally matches one digit.
        else:
            end = index + 1
            while (end < len(text) and text[end] not in _WHITE_SPACE
                   and not _is_letter(text[end]) and not _is_number(text[end])):
                end += 1
        yield text[index:end]
        index = end


class ClipBpeTokenizer:
    """Tokenizer for this archive's NFC/whitespace/lowercase CLIP BPE model."""

    def __init__(self, config):
        self._validate(config)
        model = config["model"]
        self.vocab = model["vocab"]
        self.unk_id = self.vocab[model["unk_token"]]
        self.end_of_word_suffix = model["end_of_word_suffix"]
        self.ranks = {}
        for rank, merge in enumerate(model["merges"]):
            if isinstance(merge, str):
                pair = tuple(merge.split(" ", 1))
            else:
                pair = tuple(merge)
            if len(pair) != 2:
                raise ValueError("invalid BPE merge entry")
            self.ranks[pair] = rank
        self.byte_encoder = bytes_to_unicode()
        self.special_tokens = {
            item["content"]: item["id"] for item in config.get("added_tokens", [])
            if item.get("special")
        }

    @staticmethod
    def _validate(config):
        model = config.get("model", {})
        if (model.get("type") != "BPE" or model.get("dropout") is not None
                or model.get("continuing_subword_prefix") not in (None, "")
                or model.get("end_of_word_suffix") != _SUFFIX
                or model.get("byte_fallback") is not False
                or model.get("fuse_unk") is not False
                or model.get("ignore_merges") is True):
            raise ValueError("unsupported CLIP BPE model configuration")
        normalizer = config.get("normalizer", {})
        normalizers = normalizer.get("normalizers", [])
        if (normalizer.get("type") != "Sequence"
                or [item.get("type") for item in normalizers] != ["NFC", "Replace", "Lowercase"]
                or normalizers[1].get("pattern") != {"Regex": r"\s+"}
                or normalizers[1].get("content") != " "):
            raise ValueError("unsupported CLIP text normalizer")
        pre = config.get("pre_tokenizer", {})
        pretokenizers = pre.get("pretokenizers", [])
        if (pre.get("type") != "Sequence" or len(pretokenizers) != 2
                or pretokenizers[0].get("type") != "Split"
                or pretokenizers[0].get("behavior") != "Removed"
                or pretokenizers[0].get("invert") is not True
                or pretokenizers[0].get("pattern") != {"Regex": _SPLIT_PATTERN}
                or pretokenizers[1].get("type") != "ByteLevel"
                or pretokenizers[1].get("add_prefix_space") is not False
                or pretokenizers[1].get("use_regex") is not True):
            raise ValueError("unsupported CLIP pre-tokenizer")
        if not isinstance(model.get("vocab"), dict) or not isinstance(model.get("merges"), list):
            raise ValueError("missing CLIP BPE vocabulary or merges")
        if model.get("unk_token") not in model["vocab"]:
            raise ValueError("CLIP unknown token is missing from the vocabulary")

    @classmethod
    def from_json(cls, source):
        if isinstance(source, (bytes, bytearray)):
            source = source.decode("utf-8")
        return cls(json.loads(source))

    @staticmethod
    def normalize(text):
        if not isinstance(text, str):
            raise TypeError("prompt must be a string")
        text = unicodedata.normalize("NFC", text)
        out = []
        in_space = False
        for ch in text:
            if ch in _WHITE_SPACE:
                if not in_space:
                    out.append(" ")
                in_space = True
            else:
                out.append(ch)
                in_space = False
        return "".join(out).lower()

    def _bpe(self, piece):
        encoded = "".join(self.byte_encoder[value] for value in piece.encode("utf-8"))
        if not encoded:
            return []
        symbols = list(encoded)
        symbols[-1] += self.end_of_word_suffix
        while len(symbols) > 1:
            best_rank = None
            best_index = -1
            for index in range(len(symbols) - 1):
                rank = self.ranks.get((symbols[index], symbols[index + 1]))
                if rank is not None and (best_rank is None or rank < best_rank):
                    best_rank, best_index = rank, index
            if best_index < 0:
                break
            merged = []
            index = 0
            while index < len(symbols):
                if (index + 1 < len(symbols)
                        and self.ranks.get((symbols[index], symbols[index + 1])) == best_rank):
                    merged.append(symbols[index] + symbols[index + 1])
                    index += 2
                else:
                    merged.append(symbols[index])
                    index += 1
            symbols = merged
        return [self.vocab.get(symbol, self.unk_id) for symbol in symbols]

    def encode(self, text):
        normalized = self.normalize(text)
        ids = []
        for piece in _pieces(normalized, self.special_tokens):
            if isinstance(piece, int):
                ids.append(piece)
            else:
                ids.extend(self._bpe(piece))
        return ids
