"""Build the downloadable Bible packs, manifest and notices.

Reads sources.json, applies corrections.json (every change logged), validates,
then writes website/scripture/. Output is deterministic: same sources, same bytes.
Run: python3 tools/scripture/build_packs.py
"""
import gzip
import hashlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import corrections  # noqa: E402
import sources_io  # noqa: E402
from canon import OSIS_IDS  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(ROOT, "website", "scripture")
PACK_VERSION = 1
LICENSES = {
    "en": "Public domain",
    "es": "Public domain",
    "fr": "Public domain",
    "de": "Public domain",
    "pt_BR": "CC BY 4.0",
    "ar": "Public domain",
    "hi": "CC BY-SA 4.0",
    "ja": "Public domain",
    "ko": "Public domain",
    "zh_Hans": "Public domain",
    "he": "Public domain",
}


def to_lists(bible):
    """{book: {chapter: {verse: text}}} -> {book: [[text, ...], ...]}; gaps become empty strings."""
    books = {}
    for osis in OSIS_IDS:
        chapters = bible[osis]
        if sorted(chapters) != list(range(1, len(chapters) + 1)):
            raise ValueError(f"{osis}: chapter numbers are not 1..{len(chapters)}")
        out = []
        for c in range(1, len(chapters) + 1):
            verses = chapters[c]
            top = max(verses)
            if top > 200:
                raise ValueError(f"{osis} {c}: verse {top} is implausible")
            out.append([verses.get(v, "") for v in range(1, top + 1)])
        books[osis] = out
    return books


def validate(lang, books):
    problems = []
    empties = 0
    for osis, chapters in books.items():
        for ci, verses in enumerate(chapters, 1):
            if not verses or all(v == "" for v in verses):
                problems.append(f"{osis} {ci}: empty chapter")
            for vi, t in enumerate(verses, 1):
                if t == "":
                    empties += 1
                elif t != t.strip() or "  " in t:
                    problems.append(f"{osis} {ci}:{vi}: untidy whitespace")
                elif any(ch in t for ch in "\\<>{}"):
                    problems.append(f"{osis} {ci}:{vi}: stray markup")
    return problems, empties


def main():
    sources = json.load(open(os.path.join(HERE, "sources.json"), encoding="utf-8"))
    notices = json.load(open(os.path.join(HERE, "notices.json"), encoding="utf-8"))["notices"]
    os.makedirs(os.path.join(OUT, "notices"), exist_ok=True)
    packs, report, canon = [], [], {}
    failed = False
    for lang, spec in sources["languages"].items():
        bible = sources_io.load_language(spec)
        bible, log = corrections.apply_corrections(lang, bible)
        books = to_lists(bible)
        problems, empties = validate(lang, books)
        if problems:
            failed = True
            print(f"{lang}: {len(problems)} problems", *problems[:10], sep="\n  ")
        n = notices[lang]
        notice_text = n["title"] + "\n\n" + "\n\n".join(n["lines"]) + "\n"
        pack = {
            "schemaVersion": 1,
            "language": lang,
            "translationId": spec["translationId"],
            "source": spec["name"],
            "license": LICENSES[lang],
            "books": books,
        }
        raw = json.dumps(pack, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        gz = gzip.compress(raw, compresslevel=9, mtime=0)
        name = f"{lang}-{PACK_VERSION}.json.gz"
        with open(os.path.join(OUT, name), "wb") as f:
            f.write(gz)
        with open(os.path.join(OUT, "notices", f"{lang}.txt"), "w", encoding="utf-8", newline="\n") as f:
            f.write(notice_text)
        packs.append({
            "language": lang,
            "translationId": spec["translationId"],
            "version": PACK_VERSION,
            "url": f"/scripture/{name}",
            "bytes": len(gz),
            "sha256": hashlib.sha256(gz).hexdigest(),
            "noticePath": f"/scripture/notices/{lang}.txt",
        })
        verses = sum(1 for b in books.values() for c in b for v in c if v)
        report.append((lang, spec["translationId"], verses, empties, len(gz), log))
        canon[lang] = {o: [len(c) for c in books[o]] for o in OSIS_IDS}
    if failed:
        sys.exit("validation failed")
    manifest = {"schemaVersion": 1, "packs": packs}
    with open(os.path.join(OUT, "manifest.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
        f.write("\n")
    with open(os.path.join(HERE, "canon_counts.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(canon, f, ensure_ascii=False, separators=(",", ":"), sort_keys=True)
        f.write("\n")
    for lang, tid, v, e, size, log in report:
        print(f"{lang:8} {tid:10} verses={v:6} blank={e:3} gz={size:8} corrections={log}")


if __name__ == "__main__":
    main()
