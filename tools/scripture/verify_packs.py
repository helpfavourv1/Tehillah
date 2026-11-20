"""Independent check of website/scripture/ as shipped. Exit code 1 on any failure.
Run: python3 tools/scripture/verify_packs.py
"""
import gzip
import hashlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from canon import OSIS_IDS  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.dirname(HERE)), "website", "scripture")
LANGS = ["en", "es", "fr", "de", "pt_BR", "ar", "hi", "ja", "ko", "zh_Hans", "he"]
# (book, chapter, verse) -> distinctive substring per language, checked in every pack.
SPOT = {
    ("John", 3, 16): {"en": "God so loved", "es": "Porque de tal manera", "fr": "Car Dieu a tant aimé", "de": "Also hat Gott", "pt_BR": "Deus amou", "hi": "परमेश्वर ने जगत से ऐसा प्रेम", "zh_Hans": "神爱世人"},
    ("Ps", 23, 1): {"en": "LORD is my shepherd", "es": "pastor", "fr": "Éternel est mon berger", "de": "HERR ist mein Hirte", "hi": "चरवाहा"},
    ("Gen", 1, 1): {"en": "In the beginning", "es": "principio", "fr": "Au commencement", "de": "Am Anfang", "he": "בראשית", "hi": "आदि में"},
}


def _bare(text):
    """Drop combining marks so Hebrew letters can be matched without vowel points."""
    import unicodedata
    return "".join(ch for ch in text if not unicodedata.combining(ch))


def main():
    errors = []
    manifest = json.load(open(os.path.join(OUT, "manifest.json"), encoding="utf-8"))
    entries = {e["language"]: e for e in manifest["packs"]}
    if sorted(entries) != sorted(LANGS):
        errors.append(f"manifest languages {sorted(entries)}")
    for lang in LANGS:
        e = entries.get(lang)
        if not e:
            continue
        path = os.path.join(OUT, os.path.basename(e["url"]))
        data = open(path, "rb").read()
        if len(data) != e["bytes"]:
            errors.append(f"{lang}: size differs from manifest")
        if hashlib.sha256(data).hexdigest() != e["sha256"]:
            errors.append(f"{lang}: sha256 differs from manifest")
        if not os.path.isfile(os.path.join(OUT, "notices", lang + ".txt")):
            errors.append(f"{lang}: notice missing")
        pack = json.loads(gzip.decompress(data))
        if pack["language"] != lang or list(pack["books"]) != OSIS_IDS:
            errors.append(f"{lang}: header or book order wrong")
            continue
        total = sum(1 for b in pack["books"].values() for c in b for v in c if v)
        if not 31000 <= total <= 31400:
            errors.append(f"{lang}: {total} verses is outside the expected range")
        for (b, c, v), want in SPOT.items():
            if lang in want:
                text = pack["books"][b][c - 1][v - 1]
                if lang == "he":
                    text = _bare(text)
                if want[lang] not in text:
                    errors.append(f"{lang} {b} {c}:{v} does not contain {want[lang]!r}")
    if errors:
        print("\n".join(errors))
        sys.exit(1)
    print("scripture packs OK:", len(LANGS), "languages")


if __name__ == "__main__":
    main()
