"""Load every language from sources.json into the canonical structure."""

import json
import os

import parse
from canon import OSIS_IDS
from fetch_sources import CACHE, HERE, cache_path

OT = OSIS_IDS[:39]
NT = OSIS_IDS[39:]


def load_sources():
    with open(os.path.join(HERE, "sources.json"), encoding="utf-8") as f:
        return json.load(f)


def _books(spec):
    return {"all": OSIS_IDS, "ot": OT, "nt": NT}[spec]


def _parse_part(part):
    files = part["files"]
    parser = part["parser"]
    books = _books(part["books"])
    if parser in ("usfx", "osis", "midvash", "chapters_json", "scrollmapper"):
        path = cache_path(files[0])
        if parser == "usfx":
            bible = parse.parse_usfx(path)
        elif parser == "osis":
            bible = parse.parse_osis(path)
        elif parser == "midvash":
            bible = parse.parse_midvash_file(path)
        elif parser == "chapters_json":
            bible = parse.parse_chapters_json(path)
        else:
            bible = parse.parse_scrollmapper(path, books=set(books))
    elif parser == "usfm_dir":
        bible = parse.parse_usfm_dir(
            os.path.dirname(cache_path(files[0])),
            fixes=[tuple(x) for x in part.get("sourceFixes", [])],
        )
    else:
        raise ValueError(f"unknown parser {parser}")
    return {b: bible[b] for b in books if b in bible}


def load_language(spec):
    """Parse all parts of one language and merge them."""
    merged = {}
    for part in spec["parts"]:
        merged.update(_parse_part(part))
    missing = [b for b in OSIS_IDS if b not in merged]
    if missing:
        raise ValueError(f"missing books: {missing}")
    return merged


def load_cross(spec):
    return _parse_part({"parser": spec["parser"], "books": "all", "files": spec["files"]})
