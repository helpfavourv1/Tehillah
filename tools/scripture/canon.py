"""The 66-book canon: OSIS id, USFM id and English name, in canonical order.

OSIS ids are the keys used everywhere in the app (they match
app/lib/core/models/verse_ref.dart). The chapter and verse counts that every
language is checked against live in canon_counts.json, which is generated from
the English pack by build_packs.py --write-canon and reviewed.
"""

BOOKS = [
    ("Gen", "GEN", "Genesis"), ("Exod", "EXO", "Exodus"), ("Lev", "LEV", "Leviticus"),
    ("Num", "NUM", "Numbers"), ("Deut", "DEU", "Deuteronomy"), ("Josh", "JOS", "Joshua"),
    ("Judg", "JDG", "Judges"), ("Ruth", "RUT", "Ruth"), ("1Sam", "1SA", "1 Samuel"),
    ("2Sam", "2SA", "2 Samuel"), ("1Kgs", "1KI", "1 Kings"), ("2Kgs", "2KI", "2 Kings"),
    ("1Chr", "1CH", "1 Chronicles"), ("2Chr", "2CH", "2 Chronicles"), ("Ezra", "EZR", "Ezra"),
    ("Neh", "NEH", "Nehemiah"), ("Esth", "EST", "Esther"), ("Job", "JOB", "Job"),
    ("Ps", "PSA", "Psalms"), ("Prov", "PRO", "Proverbs"), ("Eccl", "ECC", "Ecclesiastes"),
    ("Song", "SNG", "Song of Solomon"), ("Isa", "ISA", "Isaiah"), ("Jer", "JER", "Jeremiah"),
    ("Lam", "LAM", "Lamentations"), ("Ezek", "EZK", "Ezekiel"), ("Dan", "DAN", "Daniel"),
    ("Hos", "HOS", "Hosea"), ("Joel", "JOL", "Joel"), ("Amos", "AMO", "Amos"),
    ("Obad", "OBA", "Obadiah"), ("Jonah", "JON", "Jonah"), ("Mic", "MIC", "Micah"),
    ("Nah", "NAM", "Nahum"), ("Hab", "HAB", "Habakkuk"), ("Zeph", "ZEP", "Zephaniah"),
    ("Hag", "HAG", "Haggai"), ("Zech", "ZEC", "Zechariah"), ("Mal", "MAL", "Malachi"),
    ("Matt", "MAT", "Matthew"), ("Mark", "MRK", "Mark"), ("Luke", "LUK", "Luke"),
    ("John", "JHN", "John"), ("Acts", "ACT", "Acts"), ("Rom", "ROM", "Romans"),
    ("1Cor", "1CO", "1 Corinthians"), ("2Cor", "2CO", "2 Corinthians"), ("Gal", "GAL", "Galatians"),
    ("Eph", "EPH", "Ephesians"), ("Phil", "PHP", "Philippians"), ("Col", "COL", "Colossians"),
    ("1Thess", "1TH", "1 Thessalonians"), ("2Thess", "2TH", "2 Thessalonians"),
    ("1Tim", "1TI", "1 Timothy"), ("2Tim", "2TI", "2 Timothy"), ("Titus", "TIT", "Titus"),
    ("Phlm", "PHM", "Philemon"), ("Heb", "HEB", "Hebrews"), ("Jas", "JAS", "James"),
    ("1Pet", "1PE", "1 Peter"), ("2Pet", "2PE", "2 Peter"), ("1John", "1JN", "1 John"),
    ("2John", "2JN", "2 John"), ("3John", "3JN", "3 John"), ("Jude", "JUD", "Jude"),
    ("Rev", "REV", "Revelation"),
]

OSIS_IDS = [b[0] for b in BOOKS]
USFM_TO_OSIS = {b[1]: b[0] for b in BOOKS}
OSIS_INDEX = {b[0]: i for i, b in enumerate(BOOKS)}
NAMES = {b[0]: b[2] for b in BOOKS}

assert len(BOOKS) == 66 and len(set(OSIS_IDS)) == 66 and len(USFM_TO_OSIS) == 66
