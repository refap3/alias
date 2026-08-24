#!/usr/bin/env python3
"""
strip_oceanofpdf.py - remove every trace of the "OceanofPDF" branding from EPUB files.

What it removes
---------------
  * <a href="https://oceanofpdf.com/..."> links (the whole anchor, not just the href)
  * anchors whose visible text is the brand
  * plain-text mentions: "OceanofPDF.com", "Ocean of PDF", "www.oceanofpdf.com", ...
  * <img>/<link> tags pointing at branded assets
  * whole inserted watermark pages, plus their manifest / spine / guide / TOC entries
  * any file whose *name* contains the brand (banner images, extra stylesheets, ...)
  * OPF metadata that is only branding (dc:source, dc:publisher, <meta>, ...)
  * "(OceanofPDF.com)" appended to dc:title, and the empty "()" left behind
  * leftover empty <p>/<div>/<h1..h6>/<span> shells

Only the Python standard library is required (tested on 3.8+).

Usage
-----
    python3 strip_oceanofpdf.py book.epub                 # in place, keeps book.epub.bak
    python3 strip_oceanofpdf.py book.epub -o clean.epub   # write to a new file
    python3 strip_oceanofpdf.py *.epub --dry-run          # report only, change nothing
    python3 strip_oceanofpdf.py book.epub --no-backup
    python3 strip_oceanofpdf.py book.epub --keep-pages    # clean pages but never delete them
"""

from __future__ import annotations

import argparse
import posixpath
import re
import shutil
import sys
import zipfile
from pathlib import Path
from urllib.parse import unquote

# ---------------------------------------------------------------------------
# patterns
# ---------------------------------------------------------------------------

# "OceanofPDF", "Ocean of PDF", "ocean-of-pdf", "OceanOfPdf" ...
_BRAND = r"ocean\s*[-_]?\s*of\s*[-_]?\s*pdf"
# same, but as it appears inside URLs / file names (no whitespace)
_BRAND_URL = r"ocean[-_ ]?of[-_ ]?pdf"

BRAND_ANY = re.compile(_BRAND, re.I)
BRAND_IN_NAME = re.compile(_BRAND_URL, re.I)

# full textual mention incl. protocol / www / .com / trailing slash
BRAND_TEXT = re.compile(
    r"(?:https?://)?(?:www\.)?" + _BRAND + r"(?:\s*\.\s*com)?/?", re.I
)

A_BY_HREF = re.compile(
    r"<a\b[^>]*href\s*=\s*[\"'][^\"']*" + _BRAND_URL + r"[^\"']*[\"'][^>]*>.*?</a>",
    re.I | re.S,
)
A_BY_TEXT = re.compile(
    r"<a\b[^>]*>(?:(?!</a>).)*?" + _BRAND + r"(?:(?!</a>).)*?</a>", re.I | re.S
)
IMG_TAG = re.compile(
    r"<img\b[^>]*(?:src|alt|title)\s*=\s*[\"'][^\"']*" + _BRAND_URL + r"[^\"']*[\"'][^>]*/?>",
    re.I,
)
LINK_TAG = re.compile(
    r"<link\b[^>]*href\s*=\s*[\"'][^\"']*" + _BRAND_URL + r"[^\"']*[\"'][^>]*/?>", re.I
)
# CSS: url(.../oceanofpdf...)
CSS_URL = re.compile(r"url\(\s*[\"']?[^)\"']*" + _BRAND_URL + r"[^)\"']*[\"']?\s*\)", re.I)

EMPTY_BLOCK = re.compile(
    r"<(p|div|span|h[1-6]|blockquote|center|em|strong|i|b)\b[^>]*>"
    r"(?:\s|&nbsp;|&#160;|&#xa0;|<br\s*/?>)*"
    r"</\1>",
    re.I,
)
EMPTY_BRACKETS = re.compile(r"[\(\[\{]\s*[\)\]\}]")
TAG = re.compile(r"<[^>]+>")

TEXT_EXT = {
    ".xhtml", ".html", ".htm", ".xml", ".opf", ".ncx",
    ".css", ".txt", ".svg", ".json", ".smil",
}

# metadata elements that must survive even if they end up empty
KEEP_EVEN_IF_EMPTY = {"dc:title", "dc:identifier", "dc:language", "dc:creator"}


# ---------------------------------------------------------------------------
# small helpers
# ---------------------------------------------------------------------------

def is_text(name: str) -> bool:
    return posixpath.splitext(name)[1].lower() in TEXT_EXT


def resolve(base_file: str, href: str) -> str:
    """Resolve an href found in *base_file* to a full path inside the zip."""
    href = unquote(href.split("#")[0].strip())
    if not href or href.startswith(("http:", "https:", "mailto:", "data:")):
        return ""
    return posixpath.normpath(posixpath.join(posixpath.dirname(base_file), href))


def find_blocks(xml: str, tag: str):
    """Return (start, end) spans of every <tag>...</tag>, nesting-aware."""
    pat = re.compile(r"<(/?)" + tag + r"\b([^>]*)>", re.I)
    stack, spans = [], []
    for m in pat.finditer(xml):
        if m.group(1):  # closing tag
            if stack:
                spans.append((stack.pop(), m.end()))
        elif m.group(2).rstrip().endswith("/"):  # self-closing
            spans.append((m.start(), m.end()))
        else:
            stack.append(m.start())
    return sorted(spans)


def remove_blocks(xml: str, tag: str, predicate) -> tuple[str, int]:
    """Delete every <tag> element whose source text satisfies *predicate*."""
    hits = [(s, e) for s, e in find_blocks(xml, tag) if predicate(xml[s:e])]
    # drop hits nested inside another hit
    outer, last_end = [], -1
    for s, e in hits:
        if s >= last_end:
            outer.append((s, e))
            last_end = e
    for s, e in reversed(outer):
        xml = xml[:s] + xml[e:]
    return xml, len(outer)


def visible_text(html: str) -> str:
    body = re.search(r"<body\b[^>]*>(.*)</body>", html, re.I | re.S)
    txt = TAG.sub(" ", body.group(1) if body else html)
    txt = re.sub(r"&(nbsp|#160|#xa0);", " ", txt, flags=re.I)
    return txt.strip()


def has_media(html: str) -> bool:
    body = re.search(r"<body\b[^>]*>(.*)</body>", html, re.I | re.S)
    return bool(re.search(r"<(img|image|svg|video|audio)\b", body.group(1) if body else html, re.I))


# ---------------------------------------------------------------------------
# cleaning a single text member
# ---------------------------------------------------------------------------

def clean_text_member(name: str, text: str) -> tuple[str, dict]:
    stats = {"links": 0, "images": 0, "mentions": 0, "empty": 0}

    text, n = A_BY_HREF.subn("", text)
    stats["links"] += n
    text, n = A_BY_TEXT.subn("", text)
    stats["links"] += n
    text, n = IMG_TAG.subn("", text)
    stats["images"] += n
    text, n = LINK_TAG.subn("", text)
    stats["images"] += n
    text, n = CSS_URL.subn("none", text)
    stats["images"] += n

    # remaining plain-text mentions
    text, n = BRAND_TEXT.subn("", text)
    stats["mentions"] += n
    text, n = BRAND_ANY.subn("", text)          # any odd leftover spelling
    stats["mentions"] += n

    # tidy up what the removals left behind
    text = EMPTY_BRACKETS.sub("", text)
    text = re.sub(r"[ \t]+([,.;:!?])", r"\1", text)
    text = re.sub(r"[ \t]{2,}", " ", text)
    for _ in range(4):                           # collapse nested empty wrappers
        text, n = EMPTY_BLOCK.subn("", text)
        stats["empty"] += n
        if not n:
            break
    text = re.sub(r"(\n[ \t]*){3,}", "\n\n", text)
    return text, stats


def clean_opf_metadata(opf: str) -> str:
    """Drop metadata elements that became empty after brand removal."""
    def dead_dc(block: str) -> bool:
        m = re.match(r"<(dc:[A-Za-z]+)", block, re.I)
        if not m or m.group(1).lower() in KEEP_EVEN_IF_EMPTY:
            return False
        return not TAG.sub("", block).strip()

    for tag in sorted({m.group(1) for m in re.finditer(r"<(dc:[A-Za-z]+)\b", opf, re.I)}):
        opf, _ = remove_blocks(opf, re.escape(tag), dead_dc)

    # <meta ... content=""/> and <meta>...</meta> left empty
    opf = re.sub(r"<meta\b[^>]*content\s*=\s*([\"'])\s*\1[^>]*/?>", "", opf, flags=re.I)
    opf, _ = remove_blocks(opf, "meta", lambda b: "</meta>" in b.lower() and not TAG.sub("", b).strip())
    return opf


# ---------------------------------------------------------------------------
# manifest / spine / TOC surgery
# ---------------------------------------------------------------------------

def purge_from_opf(opf: str, opf_path: str, dead: set[str]) -> str:
    ids = set()
    for m in re.finditer(r"<item\b[^>]*/?>", opf, re.I):
        item = m.group(0)
        href = re.search(r"href\s*=\s*[\"']([^\"']+)[\"']", item, re.I)
        ident = re.search(r"\bid\s*=\s*[\"']([^\"']+)[\"']", item, re.I)
        if href and resolve(opf_path, href.group(1)) in dead and ident:
            ids.add(ident.group(1))

    def drop(tag: str, attr: str, values: set[str], xml: str) -> str:
        pat = re.compile(r"<" + tag + r"\b[^>]*/?>(?:\s*</" + tag + r">)?", re.I)
        out = []
        pos = 0
        for m in pat.finditer(xml):
            v = re.search(attr + r"\s*=\s*[\"']([^\"']+)[\"']", m.group(0), re.I)
            if v and (v.group(1) in values or resolve(opf_path, v.group(1)) in dead):
                out.append(xml[pos:m.start()])
                pos = m.end()
        out.append(xml[pos:])
        return "".join(out)

    opf = drop("item", "href", set(), opf)          # manifest entries (by href)
    opf = drop("itemref", "idref", ids, opf)        # spine entries (by idref)
    opf = drop("reference", "href", set(), opf)     # guide entries (by href)
    # a cover <meta name="cover" content="id"> pointing at a deleted image
    for i in ids:
        opf = re.sub(
            r"<meta\b[^>]*name\s*=\s*[\"']cover[\"'][^>]*content\s*=\s*[\"']"
            + re.escape(i) + r"[\"'][^>]*/?>", "", opf, flags=re.I)
    return opf


def purge_from_ncx(ncx: str, ncx_path: str, dead: set[str]) -> str:
    def is_dead(block: str) -> bool:
        src = re.search(r"<content\b[^>]*src\s*=\s*[\"']([^\"']+)[\"']", block, re.I)
        return bool(src) and resolve(ncx_path, src.group(1)) in dead

    ncx, _ = remove_blocks(ncx, "navPoint", is_dead)
    for n, m in enumerate(re.finditer(r"playOrder\s*=\s*[\"'](\d+)[\"']", ncx), 1):
        pass  # playOrder gaps are harmless; readers ignore them
    return ncx


def purge_from_nav(nav: str, nav_path: str, dead: set[str]) -> str:
    def is_dead(block: str) -> bool:
        for m in re.finditer(r"<a\b[^>]*href\s*=\s*[\"']([^\"']+)[\"']", block, re.I):
            if resolve(nav_path, m.group(1)) in dead:
                return True
        return False

    nav, _ = remove_blocks(nav, "li", is_dead)
    return nav


# ---------------------------------------------------------------------------
# main worker
# ---------------------------------------------------------------------------

def process(src: Path, dest: Path, dry_run: bool, keep_pages: bool, verbose: bool) -> bool:
    with zipfile.ZipFile(src) as zf:
        names = zf.namelist()
        data = {n: zf.read(n) for n in names}
        infos = {n: zf.getinfo(n) for n in names}

    report = []
    total = {"links": 0, "images": 0, "mentions": 0, "empty": 0}
    dead: set[str] = set()

    # 1. files whose *name* is branded
    for n in names:
        if BRAND_IN_NAME.search(posixpath.basename(n)):
            dead.add(n)
            report.append(f"  delete file (branded name): {n}")

    # 2. locate the OPF
    opf_path = next((n for n in names if n.lower().endswith(".opf")), None)
    if opf_path is None:
        print(f"!! {src.name}: no .opf found - not a valid EPUB?", file=sys.stderr)
        return False

    # 3. identify structure files - they must be purged *before* their text is
    #    rewritten, otherwise branded hrefs no longer match the dead paths
    nav_docs = set()
    for n in names:
        if n.lower().endswith((".xhtml", ".html")):
            head = data[n][:4000].decode("utf-8", "replace")
            if re.search(r"epub:type\s*=\s*[\"'][^\"']*\btoc\b", head, re.I):
                nav_docs.add(n)
    structure = {opf_path} | {n for n in names if n.lower().endswith(".ncx")} | nav_docs

    # 4. clean every ordinary text member
    content_docs = [n for n in names
                    if posixpath.splitext(n)[1].lower() in (".xhtml", ".html", ".htm")
                    and n not in nav_docs]
    for n in list(data):
        if n in dead or n in structure or not is_text(n):
            continue
        raw = data[n]
        try:
            text = raw.decode("utf-8")
            enc = "utf-8"
        except UnicodeDecodeError:
            text = raw.decode("utf-8", "replace")
            enc = "utf-8"
        if not BRAND_ANY.search(text):
            continue

        cleaned, stats = clean_text_member(n, text)
        for k in total:
            total[k] += stats[k]

        # whole watermark page?
        if (not keep_pages and n in content_docs and n != opf_path
                and not visible_text(cleaned) and not has_media(cleaned)
                and len(content_docs) - len(dead) > 1):
            dead.add(n)
            report.append(f"  delete page (nothing left but branding): {n}")
            continue

        data[n] = cleaned.encode(enc)
        bits = ", ".join(f"{v} {k}" for k, v in stats.items() if v)
        if bits:
            report.append(f"  clean {n}: {bits}")

    # 5. remove dead entries from manifest / spine / guide / TOC (still untouched text)
    if dead:
        data[opf_path] = purge_from_opf(
            data[opf_path].decode("utf-8", "replace"), opf_path, dead).encode("utf-8")
        for n in structure - {opf_path}:
            blob = data[n].decode("utf-8", "replace")
            blob = purge_from_ncx(blob, n, dead) if n.lower().endswith(".ncx") \
                else purge_from_nav(blob, n, dead)
            data[n] = blob.encode("utf-8")
        for n in dead:
            data.pop(n, None)

    # 6. now clean the remaining branding out of the structure files themselves
    for n in structure:
        if n not in data:
            continue
        text = data[n].decode("utf-8", "replace")
        if BRAND_ANY.search(text):
            cleaned, stats = clean_text_member(n, text)
            for k in total:
                total[k] += stats[k]
            data[n] = cleaned.encode("utf-8")
            bits = ", ".join(f"{v} {k}" for k, v in stats.items() if v)
            if bits:
                report.append(f"  clean {n}: {bits}")

    # 7. tidy OPF metadata
    data[opf_path] = clean_opf_metadata(
        data[opf_path].decode("utf-8", "replace")).encode("utf-8")

    changed = bool(dead) or any(total.values())
    label = f"{src.name}"
    if not changed:
        print(f"== {label}: clean already, nothing to do")
        return False

    print(f"== {label}")
    if verbose or dry_run:
        for line in report:
            print(line)
    print("   totals: " + ", ".join(f"{v} {k}" for k, v in total.items() if v)
          + (f", {len(dead)} file(s) removed" if dead else ""))

    if dry_run:
        print("   (dry run - nothing written)")
        return True

    # 6. write the new EPUB: 'mimetype' first and uncompressed, everything else deflated
    tmp = dest.with_suffix(dest.suffix + ".tmp")
    with zipfile.ZipFile(tmp, "w") as out:
        if "mimetype" in data:
            zi = zipfile.ZipInfo("mimetype")
            zi.compress_type = zipfile.ZIP_STORED
            zi.external_attr = infos["mimetype"].external_attr
            out.writestr(zi, data.pop("mimetype"))
        for n in names:
            if n not in data:
                continue
            zi = zipfile.ZipInfo(n, date_time=infos[n].date_time)
            zi.compress_type = zipfile.ZIP_DEFLATED
            zi.external_attr = infos[n].external_attr
            out.writestr(zi, data[n])
    tmp.replace(dest)
    print(f"   -> {dest}")
    return True


def clean_filename(p: Path) -> Path:
    stem = BRAND_IN_NAME.sub("", p.stem)
    stem = re.sub(r"[\(\[\{]\s*[\)\]\}]", "", stem)
    stem = re.sub(r"^[\s._-]+|[\s._-]+$", "", stem)
    stem = re.sub(r"[\s._-]{2,}", " ", stem).strip()
    return p.with_name((stem or p.stem) + p.suffix)


def main() -> int:
    ap = argparse.ArgumentParser(description="Strip OceanofPDF branding from EPUB files.")
    ap.add_argument("epubs", nargs="+", type=Path, help="EPUB file(s) to clean")
    ap.add_argument("-o", "--output", type=Path, help="write result here (single input only)")
    ap.add_argument("--dry-run", action="store_true", help="report what would change, write nothing")
    ap.add_argument("--no-backup", action="store_true", help="do not keep a .bak copy")
    ap.add_argument("--keep-pages", action="store_true", help="never delete whole pages")
    ap.add_argument("--rename", action="store_true", help="also strip the brand from the file name")
    ap.add_argument("-v", "--verbose", action="store_true", help="list every change")
    args = ap.parse_args()

    if args.output and len(args.epubs) > 1:
        ap.error("-o/--output works with a single input file only")

    rc = 0
    for src in args.epubs:
        if not src.is_file():
            print(f"!! not found: {src}", file=sys.stderr)
            rc = 1
            continue
        dest = args.output or src
        if dest == src and not args.dry_run and not args.no_backup:
            bak = src.with_suffix(src.suffix + ".bak")
            if not bak.exists():
                shutil.copy2(src, bak)
        try:
            touched = process(src, dest, args.dry_run, args.keep_pages, args.verbose)
        except zipfile.BadZipFile:
            print(f"!! {src.name}: not a readable zip/EPUB", file=sys.stderr)
            rc = 1
            continue
        if touched and args.rename and not args.dry_run:
            new = clean_filename(dest)
            if new != dest and not new.exists():
                dest.rename(new)
                print(f"   renamed -> {new.name}")
    return rc


if __name__ == "__main__":
    sys.exit(main())