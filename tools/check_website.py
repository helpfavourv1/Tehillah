"""Checks the static website: every local link and asset resolves, every page has the required basics."""
import pathlib
import re
import sys
from html.parser import HTMLParser

ROOT = pathlib.Path(__file__).resolve().parent.parent / "website"
PAGES = sorted(ROOT.glob("*.html"))
errors = []


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.refs = []
        self.title = False
        self.has_title = False
        self.has_lang = False
        self.has_viewport = False
        self.ids = set()

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "html" and a.get("lang"):
            self.has_lang = True
        if tag == "title":
            self.title = True
        if tag == "meta" and a.get("name") == "viewport":
            self.has_viewport = True
        for key in ("href", "src"):
            if a.get(key):
                self.refs.append(a[key])
        if a.get("id"):
            self.ids.add(a["id"])

    def handle_data(self, data):
        if self.title and data.strip():
            self.has_title = True

    def handle_endtag(self, tag):
        if tag == "title":
            self.title = False


if not PAGES:
    errors.append("no html pages found in website/")

for page in PAGES:
    p = Links()
    p.feed(page.read_text(encoding="utf-8"))
    for flag, msg in ((p.has_lang, "lang attribute"), (p.has_title, "title"), (p.has_viewport, "viewport meta")):
        if not flag:
            errors.append(f"{page.name}: missing {msg}")
    for ref in p.refs:
        if re.match(r"^(https?:|mailto:|tel:|data:)", ref):
            continue
        if ref.startswith("#"):
            if ref[1:] not in p.ids:
                errors.append(f"{page.name}: anchor {ref} not found")
            continue
        path = ref.split("#")[0].split("?")[0]
        target = ROOT / path.lstrip("/") if path != "/" else ROOT / "index.html"
        if not target.exists() and not target.with_name(target.name + ".html").exists():
            errors.append(f"{page.name}: broken reference {ref}")

for required in ("index.html", "privacy.html", "support.html", "404.html", "style.css", "_headers"):
    if not (ROOT / required).exists():
        errors.append(f"missing website/{required}")

css = (ROOT / "style.css").read_text(encoding="utf-8")
for m in re.finditer(r"url\(\"?(/[^)\"]+)", css):
    if not (ROOT / m.group(1).lstrip("/")).exists():
        errors.append(f"style.css: missing asset {m.group(1)}")

if errors:
    for e in errors:
        print(f"::error::{e}")
    sys.exit(1)
print(f"Website OK: {len(PAGES)} pages checked.")
