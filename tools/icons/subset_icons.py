"""Builds app/assets/icons/PhosphorBold.ttf: the Phosphor bold icon font reduced to the icons in
icon_set.json. The glyph codepoints are unchanged, so the Dart constants in
app/lib/theme/icon_aliases.dart can be checked against icon_set.json.

Phosphor Icons are MIT licensed (copyright 2020-2021 Phosphor Icons); the license text is kept
beside the font.

Usage:
    pip install fonttools
    python3 tools/icons/subset_icons.py <path to Phosphor-Bold.ttf> <output PhosphorBold.ttf>
"""
import json
import pathlib
import subprocess
import sys


def main() -> None:
    source = sys.argv[1]
    output = sys.argv[2]
    names = json.loads((pathlib.Path(__file__).parent / "icon_set.json").read_text())
    unicodes = ",".join(f"U+{int(code, 16):04X}" for code in names.values())
    subprocess.run(
        ["pyftsubset", source, f"--unicodes={unicodes}", f"--output-file={output}", "--no-hinting"],
        check=True,
    )


if __name__ == "__main__":
    main()
