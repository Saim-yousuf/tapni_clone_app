#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Normalize l10n access to context.l10n and strip invalid const."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"
INCLUDE = {"screens", "widgets", "helper"}


def process(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    orig = text

    # Remove local final l10n = ... lines (we'll use context.l10n directly)
    text = re.sub(r"^[ \t]*final l10n = context\.l10n;\s*\n", "", text, flags=re.M)
    text = re.sub(r"^[ \t]*final l10n = ctx\.l10n;\s*\n", "", text, flags=re.M)

    # Don't touch the extension file definition
    if path.name == "app_localizations_fallback.dart":
        return False

    # Replace bare l10n. with context.l10n. except already context.l10n / ctx.l10n
    text = re.sub(r"(?<![\w.])l10n\.", "context.l10n.", text)

    # In builders that use (ctx) fix context.l10n back to ctx.l10n within that block is hard.
    # Heuristic: if file contains builder: (ctx) then within nearby lines using context.l10n
    # after `builder: (ctx)` replace context.l10n -> ctx.l10n until matching braces roughly.
    if "builder: (ctx)" in text or "builder: (ctx," in text or "(BuildContext ctx)" in text:
        # Replace in methods titled around showDialog where ctx is used
        text = re.sub(
            r"(builder:\s*\(\s*(?:BuildContext\s+)?ctx\s*\)\s*\{)([\s\S]*?)(\n\s*\})",
            lambda m: m.group(1)
            + m.group(2).replace("context.l10n.", "ctx.l10n.")
            + m.group(3),
            text,
            count=20,
        )

    # Strip const on lines containing context.l10n or ctx.l10n
    lines = []
    for line in text.splitlines(keepends=True):
        if ("context.l10n." in line or "ctx.l10n." in line) and "const " in line:
            # remove all const on that line (safe enough for UI)
            line = line.replace("const ", "")
        lines.append(line)
    text = "".join(lines)

    # Remove const from parent constructors that wrap l10n on following args - common patterns:
    # const [
    #   Text(context.l10n.xxx)
    text = re.sub(
        r"const\s+\[(\s*(?:\n|.)*?\bcontext\.l10n\.)",
        r"[\1",
        text,
        flags=re.M,
    )
    text = re.sub(
        r"const\s+(\w+)\(([^;]*?\bcontext\.l10n\.)",
        r"\1(\2",
        text,
        count=50,
    )

    # Broader pass: if a const widget block (same statement) contains context.l10n, remove const
    # Multi-line: `const Foo(` ... `context.l10n` before closing `),`
    def strip_const_blocks(src: str) -> str:
        out = []
        i = 0
        while True:
            m = re.search(r"\bconst\s+", src[i:])
            if not m:
                out.append(src[i:])
                break
            start = i + m.start()
            out.append(src[i:start])
            after = i + m.end()
            # find end of statement roughly - next `;` or balanced parens
            # take next 800 chars and see if context.l10n appears before `;`
            window = src[after : after + 1200]
            if "context.l10n." in window or "ctx.l10n." in window:
                # skip the const keyword
                i = after
            else:
                out.append(src[start:after])
                i = after
        return "".join(out)

    text = strip_const_blocks(text)

    if text != orig:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def main() -> None:
    n = 0
    for path in ROOT.rglob("*.dart"):
        try:
            top = path.relative_to(ROOT).parts[0]
        except Exception:
            continue
        if top not in INCLUDE:
            continue
        if process(path):
            n += 1
            print(path.relative_to(ROOT))
    print(f"updated {n}")


if __name__ == "__main__":
    main()
