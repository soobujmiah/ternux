#!/usr/bin/env python3
"""Dependency-free structural checks for ternux documentation and website."""

from __future__ import annotations

import html
from html.parser import HTMLParser
from pathlib import Path
import re
import sys
import unicodedata
from urllib.parse import unquote
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
TEXT_SUFFIXES = {".md", ".html", ".yml", ".yaml", ".css", ".js", ".xml", ".txt"}
errors: list[str] = []
checks = 0


def check(condition: bool, message: str) -> None:
    global checks
    checks += 1
    if not condition:
        errors.append(message)


def read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except (UnicodeError, OSError) as exc:
        errors.append(f"{path.relative_to(ROOT)}: cannot read as UTF-8: {exc}")
        return ""


def front_matter(path: Path) -> dict[str, str]:
    text = read(path)
    if not text.startswith("---\n"):
        return {}
    end = text.find("\n---\n", 4)
    if end < 0:
        errors.append(f"{path.relative_to(ROOT)}: unclosed front matter")
        return {}
    result: dict[str, str] = {}
    for line in text[4:end].splitlines():
        match = re.match(r"^([A-Za-z_][\w-]*):\s*(.*?)\s*$", line)
        if not match:
            continue
        value = match.group(2).strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        result[match.group(1)] = value
    return result


def gh_slug(value: str) -> str:
    value = re.sub(r"<[^>]+>", "", value)
    value = re.sub(r"`([^`]*)`", r"\1", value).strip().lower()
    chars = []
    for char in value:
        category = unicodedata.category(char)
        if char in " -_" or category[0] in "LN" or category.startswith("M"):
            chars.append(char)
    return "".join(chars).replace(" ", "-")


def markdown_headings(path: Path) -> list[tuple[int, str]]:
    """Return ATX headings outside front matter and fenced code blocks."""
    text = read(path)
    if text.startswith("---\n"):
        end = text.find("\n---\n", 4)
        if end >= 0:
            text = text[end + 5 :]
    headings: list[tuple[int, str]] = []
    fence: str | None = None
    for line in text.splitlines():
        marker = re.match(r"^\s*(`{3,}|~{3,})", line)
        if marker:
            token = marker.group(1)
            if fence is None:
                fence = token[0]
            elif fence == token[0]:
                fence = None
            continue
        if fence is not None:
            continue
        match = re.match(r"^(#{1,6})\s+(.+?)\s*#*$", line)
        if match:
            headings.append((len(match.group(1)), match.group(2)))
    return headings


def document_heading_levels(path: Path) -> list[int]:
    """Return rendered heading levels in source order, including raw HTML headings."""
    text = read(path)
    if text.startswith("---\n"):
        end = text.find("\n---\n", 4)
        if end >= 0:
            text = text[end + 5 :]
    levels: list[int] = []
    fence: str | None = None
    for line in text.splitlines():
        marker = re.match(r"^\s*(`{3,}|~{3,})", line)
        if marker:
            token = marker.group(1)
            if fence is None:
                fence = token[0]
            elif fence == token[0]:
                fence = None
            continue
        if fence is not None:
            continue
        markdown = re.match(r"^(#{1,6})\s+", line)
        if markdown:
            levels.append(len(markdown.group(1)))
            continue
        levels.extend(int(match.group(1)) for match in re.finditer(r"<h([1-6])\b", line, re.I))
    return levels


def anchors(path: Path) -> set[str]:
    if not path.exists() or path.suffix.lower() not in {".md", ".html"}:
        return set()
    text = read(path)
    found = set(re.findall(r"<a\s+[^>]*(?:id|name)=[\"']([^\"']+)", text, re.I))
    found.update(re.findall(r"\sid=[\"']([^\"']+)", text, re.I))
    if path.suffix.lower() == ".md":
        seen: dict[str, int] = {}
        for _, heading in markdown_headings(path):
            title = re.sub(r"\s+\{#[^}]+\}\s*$", "", heading)
            slug = gh_slug(title)
            if not slug:
                continue
            count = seen.get(slug, 0)
            seen[slug] = count + 1
            found.add(slug if count == 0 else f"{slug}-{count}")
    return found


def resolve_target(source: Path, raw_path: str) -> Path | None:
    if raw_path.startswith("/"):
        candidate = ROOT / raw_path.lstrip("/")
    else:
        candidate = (source.parent / raw_path).resolve()
    candidates = [candidate]
    if candidate.suffix.lower() == ".html":
        candidates.extend((candidate.with_suffix(".md"), candidate.parent / candidate.stem / "index.html"))
    elif not candidate.suffix:
        candidates.extend((candidate.with_suffix(".md"), candidate.with_suffix(".html"), candidate / "index.html", candidate / "index.md"))
    for item in candidates:
        try:
            item.relative_to(ROOT)
        except ValueError:
            continue
        if item.exists():
            return item
    return None


class IdParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.ids: list[str] = []
        self.tags: dict[str, int] = {}
        self.empty_links = 0
        self.images_without_alt = 0

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        self.tags[tag] = self.tags.get(tag, 0) + 1
        if values.get("id"):
            self.ids.append(values["id"] or "")
        if tag == "a" and not (values.get("href") or "").strip():
            self.empty_links += 1
        if tag == "img" and "alt" not in values:
            self.images_without_alt += 1


# UTF-8 and replacement-character scan.
text_files = [p for p in ROOT.rglob("*") if p.is_file() and ".git" not in p.parts and p.suffix.lower() in TEXT_SUFFIXES]
for path in text_files:
    text = read(path)
    check("\ufffd" not in text, f"{path.relative_to(ROOT)}: contains Unicode replacement character")

# Paired published pages and reciprocal language metadata.
pairs: list[tuple[Path, Path]] = [(ROOT / "index.html", ROOT / "bn/index.html")]
for english in sorted((ROOT / "docs").glob("*.md")):
    if english.name == "README.md":
        continue
    pairs.append((english, ROOT / "bn/docs" / english.name))
pairs.extend(((ROOT / "CONTRIBUTING.md", ROOT / "bn/CONTRIBUTING.md"), (ROOT / "CHANGELOG.md", ROOT / "bn/CHANGELOG.md")))

for english, bengali in pairs:
    check(english.exists(), f"missing English page: {english.relative_to(ROOT)}")
    check(bengali.exists(), f"missing Bengali mirror: {bengali.relative_to(ROOT)}")
    if not english.exists() or not bengali.exists():
        continue
    en_meta, bn_meta = front_matter(english), front_matter(bengali)
    for field in ("title", "description", "lang", "alt_url"):
        check(bool(en_meta.get(field)), f"{english.relative_to(ROOT)}: missing {field} front matter")
        check(bool(bn_meta.get(field)), f"{bengali.relative_to(ROOT)}: missing {field} front matter")
    check(en_meta.get("lang") == "en", f"{english.relative_to(ROOT)}: lang must be en")
    check(bn_meta.get("lang") == "bn", f"{bengali.relative_to(ROOT)}: lang must be bn")
    en_heading_levels = document_heading_levels(english)
    bn_heading_levels = document_heading_levels(bengali)
    check(
        en_heading_levels == bn_heading_levels,
        f"{english.relative_to(ROOT)} / {bengali.relative_to(ROOT)}: "
        f"heading structures differ ({en_heading_levels} != {bn_heading_levels})",
    )
    for path in (english, bengali):
        if path.suffix.lower() == ".md":
            body_h1s = [heading for level, heading in markdown_headings(path) if level == 1]
            check(not body_h1s, f"{path.relative_to(ROOT)}: shell-rendered title must not be duplicated as a body H1")

# Canonical navigation has the same grouping and destination order in both languages.
nav_text = read(ROOT / "_data/docs.yml")
nav_sections = re.split(r"^bn:\s*$", nav_text, maxsplit=1, flags=re.M)
check(len(nav_sections) == 2, "_data/docs.yml: expected en and bn sections")
if len(nav_sections) == 2:
    en_part, bn_part = nav_sections
    en_groups = re.findall(r"^  - label:\s*(.+)$", en_part, re.M)
    bn_groups = re.findall(r"^  - label:\s*(.+)$", bn_part, re.M)
    en_urls = re.findall(r"^\s{8}url:\s*(\S+)\s*$", en_part, re.M)
    bn_urls = re.findall(r"^\s{8}url:\s*(\S+)\s*$", bn_part, re.M)
    check(len(en_groups) == len(bn_groups) == 4, "documentation navigation must have four mirrored groups")
    check(len(en_urls) == len(bn_urls) == 13, "documentation navigation must have 13 destinations per language")
    expected_bn = ["/bn" + url if url.startswith("/docs") else "/bn" + url for url in en_urls]
    check(expected_bn == bn_urls, "English/Bengali navigation destinations are not structural mirrors")

# Internal links and fragments.
links_checked = 0
for source in [p for p in ROOT.rglob("*") if p.is_file() and ".git" not in p.parts and p.suffix.lower() in {".md", ".html"}]:
    text = read(source)
    links: list[str] = []
    if source.suffix.lower() == ".md":
        links.extend(re.findall(r"(?<!!)\[[^\]]*\]\(([^)\s]+)(?:\s+[\"'][^)]*[\"'])?\)", text))
    links.extend(re.findall(r"\bhref=[\"']([^\"']+)", text, re.I))
    for raw in links:
        raw = html.unescape(raw)
        if raw.startswith(("http://", "https://", "mailto:", "tel:", "data:", "{{", "{%")) or "{{" in raw or "{%" in raw:
            continue
        target, _, fragment = raw.partition("#")
        target, fragment = unquote(target), unquote(fragment)
        destination = source if not target else resolve_target(source, target.split("?", 1)[0])
        if destination is None:
            errors.append(f"{source.relative_to(ROOT)}: missing target {raw}")
            continue
        links_checked += 1
        if fragment and fragment not in anchors(destination):
            errors.append(f"{source.relative_to(ROOT)}: missing #{fragment} in {destination.relative_to(ROOT)}")
check(links_checked >= 170, f"unexpectedly few internal links checked: {links_checked}")

# Static HTML template integrity after harmless Liquid-tag removal.
for path in (ROOT / "index.html", ROOT / "bn/index.html", ROOT / "_layouts/default.html"):
    source = read(path)
    source = re.sub(r"\A---\n.*?\n---\n", "", source, flags=re.S)
    source = re.sub(r"\{%.*?%\}", "", source, flags=re.S)
    source = re.sub(r"\{\{.*?\}\}", "/placeholder", source, flags=re.S)
    parser = IdParser()
    try:
        parser.feed(source)
        parser.close()
    except Exception as exc:  # HTMLParser reports malformed declarations and entities.
        errors.append(f"{path.relative_to(ROOT)}: HTML parse failed: {exc}")
        continue
    duplicates = sorted({value for value in parser.ids if parser.ids.count(value) > 1})
    check(not duplicates, f"{path.relative_to(ROOT)}: duplicate IDs: {duplicates}")
    check(parser.tags.get("main", 0) == 1, f"{path.relative_to(ROOT)}: expected exactly one main element")
    check(parser.tags.get("h1", 0) == 1, f"{path.relative_to(ROOT)}: expected exactly one shell/landing H1")
    check(parser.empty_links == 0, f"{path.relative_to(ROOT)}: contains empty href")
    check(parser.images_without_alt == 0, f"{path.relative_to(ROOT)}: image missing alt")

# Workload cards must point to upstream repositories in both landing pages.
upstream = {
    "https://projects.blender.org/blender/blender",
    "https://github.com/ggml-org/llama.cpp",
    "https://github.com/leejet/stable-diffusion.cpp",
    "https://github.com/glmark2/glmark2",
}
for path in (ROOT / "index.html", ROOT / "bn/index.html"):
    text = read(path)
    cards = set(re.findall(r'<a class="workload-card" href="([^"]+)"', text))
    check(cards == upstream, f"{path.relative_to(ROOT)}: workload cards must match upstream repositories")

# Social previews must retain explicit dimensions and accessible localized labels.
social_sources = (ROOT / "_layouts/default.html", ROOT / "index.html", ROOT / "bn/index.html")
for path in social_sources:
    text = read(path)
    for required in (
        'property="og:image"',
        'property="og:image:width" content="1200"',
        'property="og:image:height" content="630"',
        'property="og:image:alt"',
        'name="twitter:card" content="summary_large_image"',
        'name="twitter:image"',
        'name="twitter:image:alt"',
    ):
        check(required in text, f"{path.relative_to(ROOT)}: missing social metadata {required}")
check(
    "ternux terminal interface illustrating its auditable Android workspace setup" in read(ROOT / "index.html"),
    "index.html: missing English social-image description",
)
check(
    "ternux terminal interface-এ auditable Android workspace setup দেখানো হয়েছে" in read(ROOT / "bn/index.html"),
    "bn/index.html: missing Bengali social-image description",
)
card = (ROOT / "assets/img/og-card.png").read_bytes()
check(card[:8] == b"\x89PNG\r\n\x1a\n" and card[12:16] == b"IHDR", "assets/img/og-card.png: invalid PNG header")
if len(card) >= 26 and card[:8] == b"\x89PNG\r\n\x1a\n":
    card_size = (int.from_bytes(card[16:20], "big"), int.from_bytes(card[20:24], "big"))
    check(card_size == (1200, 630), f"assets/img/og-card.png: expected 1200x630, got {card_size}")
    check(card[24:26] == bytes((8, 2)), "assets/img/og-card.png: expected 8-bit RGB color")

# Benchmark invariants: 33 combined rows and matching evidence in both languages.
def benchmark_rows(path: Path) -> list[tuple[str, str]]:
    text = read(path)
    table_match = re.search(r"\| Scene \|.*?\n\|---\|---\|---:\|---:\|\n(.*?)(?=\n### )", text, re.S)
    if not table_match:
        return []
    rows = []
    for line in table_match.group(1).splitlines():
        if not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if len(cells) == 4:
            rows.append((cells[2], cells[3]))
    return rows

en_rows = benchmark_rows(ROOT / "docs/BENCHMARKS.md")
bn_rows = benchmark_rows(ROOT / "bn/docs/BENCHMARKS.md")
check(len(en_rows) == len(bn_rows) == 33, "benchmark archive must contain 33 GL/ES scene rows in each language")
check(en_rows == bn_rows, "English/Bengali benchmark numeric rows differ")
for path in (ROOT / "docs/BENCHMARKS.md", ROOT / "bn/docs/BENCHMARKS.md"):
    text = read(path)
    for required in ("**140**", "**364**", "zink Vulkan 1.4(Adreno (TM) 825 (MESA_TURNIP))", "45 FPS", "465 FPS"):
        check(required in text, f"{path.relative_to(ROOT)}: missing benchmark invariant {required}")

# Sitemap and canonical-host configuration.
config = read(ROOT / "_config.yml")
check(re.search(r"^url:\s+https://soobujmiah\.github\.io\s*$", config, re.M) is not None, "_config.yml: url must not duplicate baseurl")
check(re.search(r"^baseurl:\s+/ternux\s*$", config, re.M) is not None, "_config.yml: expected /ternux baseurl")
try:
    sitemap = ET.parse(ROOT / "sitemap.xml").getroot()
    namespace = {"s": "http://www.sitemaps.org/schemas/sitemap/0.9", "x": "http://www.w3.org/1999/xhtml"}
    entries = sitemap.findall("s:url", namespace)
    check(len(entries) == 28, "sitemap.xml: expected 28 bilingual URLs")
    for entry in entries:
        check(len(entry.findall("x:link", namespace)) == 3, "sitemap.xml: every URL needs en, bn, and x-default alternates")
except (ET.ParseError, OSError) as exc:
    errors.append(f"sitemap.xml: parse failed: {exc}")

# Markdown fence balance and rendered-ID uniqueness catch common documentation regressions.
for path in [p for p in ROOT.rglob("*.md") if ".git" not in p.parts]:
    text = read(path)
    count = sum(1 for line in text.splitlines() if re.match(r"^\s*```", line))
    check(count % 2 == 0, f"{path.relative_to(ROOT)}: unbalanced fenced code blocks")
    rendered_ids = re.findall(r"\sid=[\"']([^\"']+)", text, re.I)
    seen_slugs: dict[str, int] = {}
    for _, heading in markdown_headings(path):
        title = re.sub(r"\s+\{#[^}]+\}\s*$", "", heading)
        slug = gh_slug(title)
        if slug:
            ordinal = seen_slugs.get(slug, 0)
            seen_slugs[slug] = ordinal + 1
            rendered_ids.append(slug if ordinal == 0 else f"{slug}-{ordinal}")
    duplicates = sorted({value for value in rendered_ids if rendered_ids.count(value) > 1})
    check(not duplicates, f"{path.relative_to(ROOT)}: duplicate rendered IDs: {duplicates}")

if errors:
    print(f"documentation checks failed ({len(errors)} errors / {checks} assertions):", file=sys.stderr)
    for error in errors:
        print(f"- {error}", file=sys.stderr)
    raise SystemExit(1)

print(f"documentation checks passed: {checks} assertions, {links_checked} internal links, {len(pairs)} bilingual page pairs")
