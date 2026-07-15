#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Aggressive scan: any user-facing English quoted literal still in UI code."""
from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"
EN = json.loads((LIB / "l10n" / "app_en.arb").read_text(encoding="utf-8"))
EN_VALUES = {v for k, v in EN.items() if isinstance(v, str) and not k.startswith("@")}

# quoted strings
Q = re.compile(r"""(['"])([^'"\\\n]{2,120})(\1)""")

SKIP_LINE = re.compile(
    r"import |package:|assets/|http|RegExp|Key\(|Route\(|debug|print\(|log\(|throw |assert\(|IconData|Color\(0x|Fonts\.|fontFamily"
)


def main() -> None:
    by_file: dict[str, list[str]] = defaultdict(list)
    for folder in ("screens", "widgets"):
        for path in (LIB / folder).rglob("*.dart"):
            lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
            for i, line in enumerate(lines, 1):
                if SKIP_LINE.search(line):
                    continue
                if "l10n." in line:
                    continue
                if "currentPage" in line or "_switchTab" in line or "case '" in line:
                    continue
                for m in Q.finditer(line):
                    s = m.group(2)
                    if not re.search(r"[A-Za-z]{2,}", s):
                        continue
                    if s.startswith(("$", "@$", "#")):
                        continue
                    # looks English / UI
                    if re.search(r"[A-Za-z]", s):
                        by_file[path.relative_to(LIB).as_posix()].append(f"L{i}: {s}")

    out = ROOT / "tool" / "remaining_aggressive.txt"
    lines_out = [f"FILES={len(by_file)}", ""]
    for f in sorted(by_file, key=lambda k: -len(by_file[k])):
        lines_out.append(f"=== {f} ({len(by_file[f])})")
        for s in by_file[f][:80]:
            lines_out.append(f"  {s}")
        if len(by_file[f]) > 80:
            lines_out.append(f"  ... {len(by_file[f])-80} more")
        lines_out.append("")
    out.write_text("\n".join(lines_out), encoding="utf-8")
    print(f"wrote {out}")
    print("FILES", len(by_file), "hits", sum(len(v) for v in by_file.values()))
    for f in sorted(by_file, key=lambda k: -len(by_file[k]))[:30]:
        print(f"{len(by_file[f]):4d} {f}")


if __name__ == "__main__":
    main()
