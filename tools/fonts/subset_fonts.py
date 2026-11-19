"""Rebuilds the bundled Latin fonts in app/assets/fonts from the upstream TrueType files.

Inter is subset as is. Source Sans 3 is subset and its family name is changed to
"Tehillah Reading Sans", because its license reserves the name "Source" for unmodified
versions. Arabic, Hindi, Japanese, Korean, Chinese and Hebrew use the platform fonts.

Usage:
    npm install @expo-google-fonts/inter @expo-google-fonts/source-sans-3
    pip install fonttools brotli
    python3 tools/fonts/subset_fonts.py <path to node_modules/@expo-google-fonts> <output dir>
"""
import pathlib
import subprocess
import sys

from fontTools.ttLib import TTFont

UNICODES = (
    "U+0000-024F,U+0259,U+1E00-1EFF,U+2000-206F,U+20A0-20CF,U+2100-2122,"
    "U+2190-2199,U+2212,U+2215,U+2248,U+2260,U+2264,U+2265,U+25CF,U+2713,U+00D7"
)
FEATURES = "kern,liga,tnum,pnum,ccmp,locl,mark,mkmk,calt,case"
FAMILY = "Tehillah Reading Sans"

INTER = [
    ("400Regular/Inter_400Regular", "Inter-Regular"),
    ("500Medium/Inter_500Medium", "Inter-Medium"),
    ("600SemiBold/Inter_600SemiBold", "Inter-SemiBold"),
    ("700Bold/Inter_700Bold", "Inter-Bold"),
]
SOURCE = [
    ("400Regular/SourceSans3_400Regular", "ReadingSans-Regular", "Regular"),
    ("600SemiBold/SourceSans3_600SemiBold", "ReadingSans-SemiBold", "SemiBold"),
]


def subset(src: pathlib.Path, dst: pathlib.Path) -> None:
    subprocess.run(
        [
            "pyftsubset",
            str(src),
            f"--unicodes={UNICODES}",
            f"--layout-features={FEATURES}",
            f"--output-file={dst}",
            "--no-hinting",
            "--desubroutinize",
        ],
        check=True,
    )


def rename(path: pathlib.Path, style: str) -> None:
    font = TTFont(path)
    for rec in font["name"].names:
        i = rec.nameID
        if i == 1:
            rec.string = FAMILY if style == "Regular" else f"{FAMILY} {style}"
        elif i == 16:
            rec.string = FAMILY
        elif i == 2:
            rec.string = "Regular"
        elif i == 17:
            rec.string = style
        elif i == 4:
            rec.string = f"{FAMILY} {style}"
        elif i == 6:
            rec.string = f"TehillahReadingSans-{style}"
        elif i == 3:
            rec.string = f"TehillahReadingSans-{style};subset"
    font.save(path)


def main() -> None:
    base = pathlib.Path(sys.argv[1])
    out = pathlib.Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    for rel, name in INTER:
        subset(base / "inter" / f"{rel}.ttf", out / f"{name}.ttf")
    for rel, name, style in SOURCE:
        target = out / f"{name}.ttf"
        subset(base / "source-sans-3" / f"{rel}.ttf", target)
        rename(target, style)


if __name__ == "__main__":
    main()
