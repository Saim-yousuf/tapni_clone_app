#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build app_en.arb keys from extracted UI strings + existing ARB keys."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
L10N = ROOT / "lib" / "l10n"
EXTRACTED = Path(__file__).resolve().parent / "extracted_ui_strings.txt"
EXISTING = L10N / "app_en.arb"
OUT_ARB = L10N / "app_en.arb"
OUT_MAP = Path(__file__).resolve().parent / "string_key_map.json"

# Existing keys to keep verbatim (value -> keep key)
# We'll merge: existing ARB is source of truth for those values.


def to_key(s: str) -> str:
    # Normalize
    s = s.replace("—", " ").replace("–", " ").replace("'", "").replace("'", "")
    s = re.sub(r"[^A-Za-z0-9\s]+", " ", s)
    parts = [p for p in s.split() if p]
    if not parts:
        return "str"
    key = parts[0].lower() + "".join(p[:1].upper() + p[1:] for p in parts[1:])
    if key[0].isdigit():
        key = "n" + key
    # reserve words
    if key in {"continue", "class", "return", "new", "default", "switch"}:
        key = key + "Label"
    return key[:80]


def is_dynamic(s: str) -> bool:
    if "${" in s or "$" in s:
        return True
    if "\\" in s and "n" in s:
        return True
    if s.count("%") >= 1:
        return True
    return False


def is_garbage(s: str) -> bool:
    if len(s) < 2 or len(s) > 120:
        return True
    if s.startswith("#") and len(s) < 4:
        return True
    if "toStringAsFixed" in s or "toRadixString" in s:
        return True
    if "DateFormat" in s:
        return True
    if s.startswith("@$"):
        return True
    # code-like
    if re.match(r"^[a-z_]+$", s) and "_" in s and " " not in s:
        return False  # snake might be ok as labels rarely
    return False


def load_all_unique() -> list[str]:
    text = EXTRACTED.read_text(encoding="utf-8", errors="ignore")
    if "=== ALL UNIQUE ===" in text:
        part = text.split("=== ALL UNIQUE ===", 1)[1]
    else:
        part = text
    lines = []
    for line in part.splitlines():
        s = line.strip()
        if not s or s.startswith("==="):
            continue
        lines.append(s)
    return lines


def main() -> None:
    existing = json.loads(EXISTING.read_text(encoding="utf-8"))
    # value -> key for existing non-meta
    value_to_key = {}
    for k, v in existing.items():
        if k.startswith("@"):
            continue
        if isinstance(v, str):
            value_to_key[v] = k

    strings = load_all_unique()
    arb = {"@@locale": "en"}
    # keep existing first
    for k, v in existing.items():
        if k == "@@locale":
            continue
        arb[k] = v

    mapping = dict(value_to_key)  # english -> key
    used_keys = set(k for k in arb if not k.startswith("@") and k != "@@locale")

    added = 0
    skipped_dynamic = 0
    for s in strings:
        if is_dynamic(s) or is_garbage(s):
            skipped_dynamic += 1
            continue
        if s in mapping:
            continue
        base = to_key(s)
        key = base
        n = 2
        while key in used_keys:
            key = f"{base}{n}"
            n += 1
        arb[key] = s
        mapping[s] = key
        used_keys.add(key)
        added += 1

    # Stable sorted keys: locale first, then existing order-ish, then alpha for new
    # Just write as-is JSON with indent
    OUT_ARB.write_text(json.dumps(arb, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    OUT_MAP.write_text(json.dumps(mapping, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"arb_keys={len([k for k in arb if not k.startswith('@')])} added={added} skipped={skipped_dynamic}")
    print(f"wrote {OUT_ARB}")
    print(f"wrote {OUT_MAP}")


if __name__ == "__main__":
    main()
