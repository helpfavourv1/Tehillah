"""Parsers that turn each source format into one canonical structure.

A parsed Bible is {osis_book_id: {chapter_number: {verse_number: text}}}. Only
text that belongs to a verse is kept: footnotes, cross references, headings and
other notes are dropped. Whitespace is collapsed. Nothing is corrected here;
scripted corrections live in corrections.json and are applied by build_packs.py.
"""

import json
import os
import re
import xml.etree.ElementTree as ET

from canon import OSIS_IDS, USFM_TO_OSIS

Bible = dict  # {book: {chapter: {verse: text}}}

_SPACE = re.compile(r"\s+")


def _clean(text):
    return _SPACE.sub(" ", text).strip()


def _local(tag):
    return tag.rsplit("}", 1)[-1] if isinstance(tag, str) else ""


def _add(bible, book, chapter, verse, text):
    """Append raw text (spacing is kept exactly; _finish collapses it later)."""
    chap = bible.setdefault(book, {}).setdefault(chapter, {})
    chap[verse] = chap.get(verse, "") + text


def _finish(bible):
    for chapters in bible.values():
        for verses in chapters.values():
            for number, text in verses.items():
                verses[number] = _clean(text)
    return bible


def _join(bible, book, chapter, verse, text):
    """Add text from a source that gives each verse whole: a space separates
    successive pieces of the same verse."""
    chap = bible.setdefault(book, {}).setdefault(chapter, {})
    chap[verse] = (chap[verse] + " " + text) if verse in chap else text


# ---------------------------------------------------------------- USFX

_USFX_SKIP = {"f", "x", "fr", "ft", "fq", "fqa", "fk", "fm", "fp", "fv", "fdc", "fl", "xt", "xo", "ref", "rq", "ca", "va", "cp", "d", "s", "s1", "s2", "r", "mr", "ms", "h", "toc", "id", "ide", "rem", "periph", "table"}


def parse_usfx(path):
    bible = {}
    book = None
    chapter = None
    verse = None
    stack_skip = 0

    def walk(el):
        nonlocal book, chapter, verse, stack_skip
        tag = _local(el.tag)
        if tag == "book":
            code = el.get("id")
            book = USFM_TO_OSIS.get(code)
            chapter = None
            verse = None
        if book is None and tag != "book":
            pass
        skipping = tag in _USFX_SKIP
        if tag == "c" and book:
            chapter = int(el.get("id"))
            verse = None
        elif tag == "v" and book and chapter:
            verse = int(re.match(r"\d+", el.get("id")).group())
        elif tag == "ve":
            verse = None
        if skipping:
            stack_skip += 1
        elif el.text and book and chapter and verse and stack_skip == 0:
            _add(bible, book, chapter, verse, el.text)
        for child in el:
            walk(child)
            if child.tail and book and chapter and verse and stack_skip == 0:
                _add(bible, book, chapter, verse, child.tail)
        if skipping:
            stack_skip -= 1

    root = ET.parse(path).getroot()
    walk(root)
    return _finish(bible)


# ---------------------------------------------------------------- OSIS

_OSIS_SKIP = {"note", "title", "header", "rdg", "reference_note"}


def _osis_book(osis_id):
    return osis_id if osis_id in OSIS_IDS else None


def parse_osis(path):
    bible = {}
    root = ET.parse(path).getroot()
    skip = 0
    current = {"ref": None}

    def walk(el):
        nonlocal skip
        tag = _local(el.tag)
        is_skip = tag in _OSIS_SKIP
        if tag == "verse":
            osis_id = el.get("osisID") or el.get("sID")
            if osis_id:
                first = osis_id.split()[0]
                parts = first.split("!")[0].split(".")
                if len(parts) == 3 and _osis_book(parts[0]) and parts[1].isdigit() and parts[2].isdigit():
                    current["ref"] = (parts[0], int(parts[1]), int(parts[2]))
            elif el.get("eID"):
                current["ref"] = None
        if is_skip:
            skip += 1
        elif el.text and current["ref"] and skip == 0:
            _add(bible, *current["ref"], el.text)
        for child in el:
            walk(child)
            if child.tail and current["ref"] and skip == 0:
                _add(bible, *current["ref"], child.tail)
        if is_skip:
            skip -= 1
        if tag == "verse" and not el.get("sID"):
            current["ref"] = None

    walk(root)
    return _finish(bible)


# ---------------------------------------------------------------- JSON

def parse_chapters_json(path):
    """thiagobodruk and scrollmapper-style: a list of 66 books in canonical
    order, each {chapters: [[verse text, ...], ...]} with verse 1 at index 0."""
    with open(path, encoding="utf-8-sig") as f:
        data = json.load(f)
    if len(data) != 66:
        raise ValueError(f"{path}: expected 66 books, found {len(data)}")
    bible = {}
    for osis, book in zip(OSIS_IDS, data):
        for ci, verses in enumerate(book["chapters"], start=1):
            for vi, text in enumerate(verses, start=1):
                _join(bible, osis, ci, vi, text)
    return _finish(bible)


def parse_midvash_file(path):
    """midvash/bible-data: <slug>.json holding {books: [{book, chapters:
    [{chapter, verses: [{number, text}]}]}]}; book ids are OSIS ids."""
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    bible = {}
    for book in data["books"]:
        if book["book"] not in OSIS_IDS:
            raise ValueError(f"{path}: unknown book {book['book']}")
        for chap in book["chapters"]:
            for v in chap["verses"]:
                _join(bible, book["book"], chap["chapter"], v["number"], v["text"])
    return _finish(bible)


def parse_scrollmapper(path, books=None):
    """scrollmapper/bible_databases formats/json: {books: [{chapters:
    [{chapter, verses: [{verse, text}]}]}]} in canonical order. `books` limits
    the result to a list of OSIS ids."""
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    if len(data["books"]) != 66:
        raise ValueError(f"{path}: expected 66 books")
    bible = {}
    for osis, book in zip(OSIS_IDS, data["books"]):
        if books is not None and osis not in books:
            continue
        for chap in book["chapters"]:
            for v in chap["verses"]:
                _join(bible, osis, chap["chapter"], v["verse"], v["text"])
    return _finish(bible)


# ---------------------------------------------------------------- USFM

_USFM_NOTE = re.compile(r"\\(f|x|fe)\b.*?\\\1\*", re.S)
_USFM_XREF = re.compile(r"\\(bdit|it)\s+\([^\\]*\)\s*\\\1\*")
_USFM_CHAR = re.compile(r"\\\+?(?:bdit|add|nd|tl|qt|qs|wj|w|k|sc|bk|pn|ord|sig|em|bd|it|bdit|no|sls|dc|ior|jmp|rb|lit|png)\*?(?:\|[^\\]*)?")
_USFM_SKIP_MARKERS = {"id", "ide", "h", "toc1", "toc2", "toc3", "mt", "mt1", "mt2", "mt3", "imt", "imt1", "imt2", "imt3", "ip", "ipi", "im", "is", "is1", "is2", "iot", "io", "io1", "io2", "ie", "s", "s1", "s2", "s3", "r", "mr", "ms", "ms1", "d", "sp", "rem", "cl", "cd", "periph", "b", "mte", "mte1", "mte2", "ib", "ili", "ili1", "ili2", "imq", "imi", "ipq", "ipr", "iq", "iq1", "iq2", "is3"}


def parse_usfm_dir(directory, fixes=()):
    import glob

    bible = {}
    for path in sorted(glob.glob(os.path.join(directory, "*.sfm")) + glob.glob(os.path.join(directory, "*.usfm"))):
        with open(path, encoding="utf-8-sig") as f:
            text = f.read()
        for needle, find, replace in fixes:
            if needle in os.path.basename(path):
                text = text.replace(find, replace)
        m = re.search(r"^\\id\s+([A-Z0-9]{3})", text, re.M)
        if not m or m.group(1) not in USFM_TO_OSIS:
            continue
        book = USFM_TO_OSIS[m.group(1)]
        text = _USFM_NOTE.sub("", text)
        text = _USFM_XREF.sub("", text)
        chapter = None
        verse = None
        for line in text.splitlines():
            mm = re.match(r"\\(\S+)\s?(.*)$", line)
            if not mm:
                if verse and chapter and line.strip():
                    _add(bible, book, chapter, verse, " " + _USFM_CHAR.sub("", line))
                continue
            marker, rest = mm.group(1), mm.group(2)
            if marker == "c":
                chapter = int(rest.split()[0])
                verse = None
                continue
            if marker in _USFM_SKIP_MARKERS:
                continue
            body = rest
            # A line may hold several \v markers (poetry) or start mid-verse.
            parts = re.split(r"\\v\s+(\d+)(?:-\d+)?\s*", "\\v " + body if marker == "v" else body)
            if marker == "v":
                parts = re.split(r"\\v\s+(\d+)(?:-\d+)?\s*", "\\v " + body)
            if len(parts) == 1:
                if verse and chapter:
                    _add(bible, book, chapter, verse, " " + _USFM_CHAR.sub("", parts[0]))
                continue
            head, pairs = parts[0], parts[1:]
            if head.strip() and verse and chapter:
                _add(bible, book, chapter, verse, " " + _USFM_CHAR.sub("", head))
            for i in range(0, len(pairs), 2):
                verse = int(pairs[i])
                seg = pairs[i + 1] if i + 1 < len(pairs) else ""
                if chapter:
                    _add(bible, book, chapter, verse, " " + _USFM_CHAR.sub("", seg))
    return _finish(bible)
