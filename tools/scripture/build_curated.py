"""Build the bundled curated verses from the packs in website/scripture/.

A candidate is kept only if, in all 11 languages, its chapter has the same
verse count, the verse is not blank, quotation marks balance, and it is short
enough for a verse card. Dropped candidates are listed with the reason.
Run: python3 tools/scripture/build_curated.py
"""
import gzip
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from canon import OSIS_IDS  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
PACKS = os.path.join(ROOT, "website", "scripture")
OUT = os.path.join(ROOT, "app", "assets", "verses")
LANGS = ["en", "es", "fr", "de", "pt_BR", "ar", "hi", "ja", "ko", "zh_Hans", "he"]
MAX_EN = 200
MAX_ANY = 260
PAIRS = [("“", "”"), ("«", "»"), ("「", "」"), ("『", "』")]
MOMENTS = ["miss", "goal", "selah", "win", "daily"]


def quotes_balanced(text):
    for a, b in PAIRS:
        if text.count(a) != text.count(b):
            return False
    return text.count('"') % 2 == 0 and text.count("(") == text.count(")")


def main():
    packs = {}
    for lang in LANGS:
        packs[lang] = json.loads(gzip.decompress(open(os.path.join(PACKS, f"{lang}-1.json.gz"), "rb").read()))
    refs = json.load(open(os.path.join(HERE, "curated_refs.json"), encoding="utf-8"))["refs"]
    kept, dropped, texts = [], [], {lang: {} for lang in LANGS}
    seen = set()
    for ref, moments in refs:
        if ref in seen:
            raise SystemExit(f"duplicate candidate {ref}")
        seen.add(ref)
        book, c, v = ref.split(".")
        c, v = int(c), int(v)
        if book not in OSIS_IDS:
            raise SystemExit(f"unknown book in {ref}")
        why = None
        counts = set()
        got = {}
        for lang in LANGS:
            chapters = packs[lang]["books"][book]
            if c > len(chapters):
                why = f"{lang}: no chapter {c}"
                break
            counts.add(len(chapters[c - 1]))
            if v > len(chapters[c - 1]):
                why = f"{lang}: no verse {v}"
                break
            got[lang] = chapters[c - 1][v - 1]
        if not why and len(counts) != 1:
            why = f"verse counts differ across languages {sorted(counts)}"
        if not why:
            for lang, t in got.items():
                if not t:
                    why = f"{lang}: blank"
                elif not quotes_balanced(t):
                    why = f"{lang}: unbalanced quotation marks or brackets"
                elif len(t) > MAX_ANY:
                    why = f"{lang}: {len(t)} characters"
                if why:
                    break
            if not why and got["en"][0].islower():
                why = "en: starts mid-sentence"
            if not why and len(got["en"]) > MAX_EN:
                why = f"en: {len(got['en'])} characters"
        if why:
            dropped.append((ref, why))
            continue
        vid = ref.replace(".", "_").lower()
        kept.append({"id": vid, "ref": ref, "moments": moments})
        for lang in LANGS:
            texts[lang][vid] = got[lang]
    os.makedirs(OUT, exist_ok=True)

    def dump(path, obj):
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            json.dump(obj, f, ensure_ascii=False, indent=1)
            f.write("\n")

    dump(os.path.join(OUT, "curated.json"), {"schemaVersion": 1, "verses": kept})
    for lang in LANGS:
        dump(os.path.join(OUT, f"{lang}.json"), {
            "schemaVersion": 1,
            "language": lang,
            "translationId": packs[lang]["translationId"],
            "texts": texts[lang],
        })
    per = {m: sum(1 for k in kept if m in k["moments"]) for m in MOMENTS}
    print("kept", len(kept), "of", len(refs), per)
    for ref, why in dropped:
        print("dropped", ref, "-", why)


if __name__ == "__main__":
    main()
