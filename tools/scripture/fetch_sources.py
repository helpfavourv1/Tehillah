#!/usr/bin/env python3
"""Download every source file listed in sources.json at its recorded commit
and verify its SHA-256. Files go to tools/scripture/.cache/ (never committed).

    python3 tools/scripture/fetch_sources.py [--cross-checks]
"""

import argparse
import hashlib
import json
import os
import sys
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(HERE, ".cache")


def cache_path(entry):
    return os.path.join(CACHE, entry["repo"].replace("/", "__"), entry["commit"][:12], entry["path"])


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def fetch(entry):
    dest = cache_path(entry)
    if os.path.exists(dest) and sha256_file(dest) == entry["sha256"]:
        return dest
    url = "https://raw.githubusercontent.com/{}/{}/{}".format(
        entry["repo"], entry["commit"], urllib.parse.quote(entry["path"])
    )
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    last = None
    for _ in range(3):
        try:
            with urllib.request.urlopen(url, timeout=120) as r, open(dest + ".part", "wb") as out:
                out.write(r.read())
            os.replace(dest + ".part", dest)
            break
        except OSError as e:  # network hiccup: retry
            last = e
    else:
        raise SystemExit(f"cannot download {url}: {last}")
    got = sha256_file(dest)
    if got != entry["sha256"]:
        os.remove(dest)
        raise SystemExit(f"checksum mismatch for {entry['path']}: expected {entry['sha256']}, got {got}")
    return dest


def entries(sources, with_cross):
    for lang in sources["languages"].values():
        for part in lang["parts"]:
            yield from part["files"]
    if with_cross:
        for cross in sources["crossChecks"].values():
            yield from cross["files"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cross-checks", action="store_true", help="also fetch the second sources")
    args = ap.parse_args()
    with open(os.path.join(HERE, "sources.json"), encoding="utf-8") as f:
        sources = json.load(f)
    count = 0
    for entry in entries(sources, args.cross_checks):
        fetch(entry)
        count += 1
    print(f"{count} source files present and verified in {CACHE}")


if __name__ == "__main__":
    sys.exit(main())
