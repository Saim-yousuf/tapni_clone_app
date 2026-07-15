#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Extract user-facing string candidates from Flutter UI dart files."""
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"
SKIP_NAMES = {
    "app_languages.dart",
    "app_localizations.dart",
    "app_localizations_en.dart",
    "app_localizations_ur.dart",
    "app_localizations_ar.dart",
    "app_localizations_hi.dart",
    "app_localizations_fallback.dart",
}
INCLUDE_TOP = {"screens", "widgets", "helper"}

PATTERNS = [
    re.compile(r"""Text\(\s*'([^'\\]*(?:\\.[^'\\]*)*)'"""),
    re.compile(r'''Text\(\s*"([^"\\]*(?:\\.[^"\\]*)*)"'''),
    re.compile(r"""(?:hintText|labelText|title|subtitle|label|content|helperText|tooltip|buttonLabel|message)\s*:\s*'([^'\\]*(?:\\.[^'\\]*)*)'"""),
    re.compile(r'''(?:hintText|labelText|title|subtitle|label|content|helperText|tooltip|buttonLabel|message)\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"'''),
    re.compile(r"""SnackBar\(\s*[^)]*?Text\(\s*'([^']+)'"""),
]

SKIP_PREFIXES = ("assets/", "package:", "http://", "https://", "/api")
SKIP_EXACT = {"My Card", "Links", "Contacts", "Explore", "Settings"}  # keep as keys for now, still localize labels


def should_keep(s: str) -> bool:
    s = s.strip()
    if len(s) < 2:
        return False
    if any(s.startswith(p) for p in SKIP_PREFIXES):
        return False
    if s.startswith("$") or s.startswith("${"):
        return False
    if re.fullmatch(r"[\d\s./:_-]+", s):
        return False
    if s in ("true", "false", "null"):
        return False
    # must have a letter
    if not re.search(r"[A-Za-z\u0600-\u06FF\u0900-\u097F]", s):
        return False
    return True


def main() -> None:
    by_file: dict[str, set[str]] = defaultdict(set)
    all_strings: set[str] = set()
    for path in ROOT.rglob("*.dart"):
        if path.name in SKIP_NAMES:
            continue
        if path.parts[path.parts.index("lib") + 1] not in INCLUDE_TOP:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        found: set[str] = set()
        for pat in PATTERNS:
            for m in pat.findall(text):
                if should_keep(m):
                    found.add(m.replace("\\'", "'").replace('\\"', '"'))
        if found:
            rel = path.relative_to(ROOT).as_posix()
            by_file[rel] = found
            all_strings |= found

    out = Path(__file__).resolve().parent / "extracted_ui_strings.txt"
    lines = [f"TOTAL_UNIQUE={len(all_strings)}", f"FILES={len(by_file)}", ""]
    for rel in sorted(by_file):
        lines.append(f"=== {rel} ({len(by_file[rel])})")
        for s in sorted(by_file[rel]):
            lines.append(f"  {s}")
        lines.append("")
    lines.append("=== ALL UNIQUE ===")
    for s in sorted(all_strings, key=lambda x: x.lower()):
        lines.append(s)
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {out} unique={len(all_strings)} files={len(by_file)}")


if __name__ == "__main__":
    main()
