"""Apply corrections.json to a parsed Bible and report what changed."""

import json
import os
import re

from fetch_sources import HERE


def load_rules():
    with open(os.path.join(HERE, "corrections.json"), encoding="utf-8") as f:
        return json.load(f)["rules"]


def apply_corrections(lang, bible, rules=None):
    """Returns (bible, log) where log is {rule id: number of verses changed}."""
    rules = load_rules() if rules is None else rules
    log = {}
    for rule in rules:
        if lang not in rule["languages"]:
            continue
        changed = 0
        for book, chapters in bible.items():
            for chapter, verses in chapters.items():
                for verse, text in list(verses.items()):
                    ref = f"{book}.{chapter}.{verse}"
                    new = text
                    if rule["type"] == "regex":
                        new = re.sub(rule["pattern"], rule["replace"], text)
                    elif rule["type"] == "replace":
                        if rule["ref"] == ref:
                            new = text.replace(rule["find"], rule["replace"])
                            if new == text:
                                raise ValueError(f"correction {rule['id']} found nothing at {ref}")
                    elif rule["type"] == "blank_if_matches":
                        if re.search(rule["pattern"], text):
                            new = ""
                    else:
                        raise ValueError(f"unknown correction type {rule['type']}")
                    new = new.strip()
                    if new != text:
                        verses[verse] = new
                        changed += 1
        if changed == 0:
            raise ValueError(f"correction {rule['id']} changed nothing for {lang}")
        log[rule["id"]] = changed
    return bible, log
