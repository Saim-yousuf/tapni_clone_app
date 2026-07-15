#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Find remaining hardcoded UI strings in screens/widgets."""
from __future__ import annotations

import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"
OUT = Path(__file__).resolve().parent / "remaining_hardcoded.txt"

PATTERNS = [
    re.compile(r"""Text\(\s*'([^'\\]*(?:\\.[^'\\]*)*)'"""),
    re.compile(r'''Text\(\s*"([^"\\]*(?:\\.[^"\\]*)*)"'''),
    re.compile(
        r"""(?:hintText|labelText|title|subtitle|label|content|helperText|tooltip|buttonLabel|message|semanticLabel)\s*:\s*'([^'\\]*(?:\\.[^'\\]*)*)'"""
    ),
    re.compile(
        r'''(?:hintText|labelText|title|subtitle|label|content|helperText|tooltip|buttonLabel|message|semanticLabel)\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"'''
    ),
]


def ok(s: str) -> bool:
    s = s.strip()
    if len(s) < 2:
        return False
    if s.startswith(("assets/", "package:", "http")):
        return False
    if s in {"?", ".", ",", "...", "–", "—"}:
        return False
    if "${" in s or s.startswith("$"):
        return False
    if not re.search(r"[A-Za-z\u0600-\u06FF\u0900-\u097F\u4e00-\u9fff]", s):
        return False
    # skip pure identifiers used as keys sometimes
    if s in {"My Card", "Links", "Contacts", "Explore", "Settings"}:
        return False
    return True


def main() -> None:
    by_file: dict[str, set[str]] = defaultdict(set)
    for folder in ("screens", "widgets", "helper"):
        base = ROOT / folder
        if not base.exists():
            continue
        for path in base.rglob("*.dart"):
            if "app_language" in path.name:
                continue
            src = path.read_text(encoding="utf-8", errors="ignore")
            found: set[str] = set()
            for pat in PATTERNS:
                for m in pat.findall(src):
                    if ok(m):
                        found.add(m.replace("\\'", "'"))
            if found:
                by_file[path.relative_to(ROOT).as_posix()] = found

    lines = [
        f"FILES={len(by_file)}",
        f"STRINGS={sum(len(v) for v in by_file.values())}",
        "",
    ]
    for rel in sorted(by_file, key=lambda k: -len(by_file[k])):
        lines.append(f"=== {rel} ({len(by_file[rel])})")
        for s in sorted(by_file[rel]):
            lines.append(f"  {s}")
        lines.append("")
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {OUT}")
    print(f"FILES={len(by_file)} STRINGS={sum(len(v) for v in by_file.values())}")
    for rel in sorted(by_file, key=lambda k: -len(by_file[k]))[:20]:
        print(f"  {len(by_file[rel]):3d} {rel}")


if __name__ == "__main__":
    main()
