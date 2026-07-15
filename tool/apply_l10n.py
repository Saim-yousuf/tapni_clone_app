#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Apply l10n replacements across screens/widgets dart files."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"
MAP_PATH = Path(__file__).resolve().parent / "string_key_map.json"
IMPORT_LINE = "import 'package:tapni_app/l10n/app_localizations_fallback.dart';\n"
INCLUDE = {"screens", "widgets", "helper"}
SKIP_FILES = {
    "app_language_screen.dart",  # already done carefully
}

# Page/tab IDs that must stay as English constants for navigation logic
KEEP_AS_IS = {
    "My Card",
    "Links",
    "Contacts",
    "Explore",
    "Settings",
}


def load_map() -> dict[str, str]:
    raw = json.loads(MAP_PATH.read_text(encoding="utf-8"))
    # Prefer longer strings first when replacing
    return raw


def process_file(path: Path, mapping: dict[str, str]) -> bool:
    if path.name in SKIP_FILES:
        return False
    text = path.read_text(encoding="utf-8")
    original = text

    # Sort by length desc to avoid partial issues (N/A for exact quotes)
    items = sorted(mapping.items(), key=lambda kv: len(kv[0]), reverse=True)

    replaced_any = False
    for english, key in items:
        if english in KEEP_AS_IS:
            # Still allow label: 'Links' etc. ONLY when not comparison?
            # Safer: never auto-replace KEEP_AS_IS; handle nav labels manually.
            continue

        # Skip empty / tiny
        if len(english) < 2:
            continue

        # Build patterns for '...' and "..."
        for quote in ("'", '"'):
            lit = quote + english.replace("\\", "\\\\").replace(quote, "\\" + quote) + quote
            # Avoid replacing import paths etc already filtered
            if lit not in text and english not in text:
                continue

            # Replace quoted literal with l10n.key
            # but NOT inside // comments only? keep simple
            def repl_literal(src: str) -> tuple[str, bool]:
                did = False
                pattern = re.compile(re.escape(lit))
                if not pattern.search(src):
                    return src, False

                def replace_match(m: re.Match) -> str:
                    nonlocal did
                    start = m.start()
                    line_start = src.rfind("\n", 0, start) + 1
                    line_end = src.find("\n", start)
                    if line_end < 0:
                        line_end = len(src)
                    line = src[line_start:line_end]
                    if "import " in line or "assets/" in line or "package:" in line:
                        return m.group(0)
                    if re.search(r"(==|!=|case\s+)\s*$", src[max(0, start - 12) : start]):
                        return m.group(0)
                    if "currentPage:" in line or "_currentPage =" in line or "_switchTab(" in line:
                        return m.group(0)
                    did = True
                    return f"l10n.{key}"

                return pattern.sub(replace_match, src), did

            text2, ch = repl_literal(text)
            if ch:
                text = text2
                replaced_any = True

    if not replaced_any:
        return False

    # Remove const before constructors that now contain l10n.
    # e.g. const Text(l10n.x) -> Text(l10n.x)
    # const InputDecoration( ... l10n. ... )
    text = re.sub(r"\bconst\s+(Text)\(\s*l10n\.", r"\1(l10n.", text)
    text = re.sub(
        r"\bconst\s+(InputDecoration|SnackBar|AlertDialog|TextStyle|AppBar|ListTile|Center)\(",
        r"\1(",
        text,
    )
    # Broader: if a const widget body contains l10n., strip that const
    # This is imperfect - second pass line-based:
    lines = text.splitlines(keepends=True)
    new_lines = []
    for line in lines:
        if "l10n." in line and re.search(r"\bconst\s+", line):
            # Don't strip const Icon/SizedBox etc without l10n on same token carefully
            line = re.sub(r"\bconst\s+(?=.*l10n\.)", "", line, count=1)
        new_lines.append(line)
    text = "".join(new_lines)

    # Add import
    if "app_localizations_fallback.dart" not in text:
        # After last import
        import_matches = list(re.finditer(r"^import .*;\s*\n", text, re.M))
        if import_matches:
            last = import_matches[-1]
            text = text[: last.end()] + IMPORT_LINE + text[last.end() :]
        else:
            text = IMPORT_LINE + text

    # Inject final l10n = context.l10n; into build methods that use l10n but don't define it
    if "l10n." in text and "context.l10n" not in text and "final l10n =" not in text:
        text = inject_l10n_in_builds(text)

    # Also inject into build methods when l10n. used
    if "l10n." in text:
        text = ensure_l10n_locals(text)

    if text != original:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def inject_l10n_in_builds(text: str) -> str:
    # Widget build(BuildContext context) { ... }
    pattern = re.compile(
        r"(Widget\s+build\(\s*BuildContext\s+context\s*\)\s*\{)"
    )

    def add(m: re.Match) -> str:
        return m.group(1) + "\n    final l10n = context.l10n;"

    return pattern.sub(add, text)


def ensure_l10n_locals(text: str) -> str:
    """Ensure each build method that references l10n has a local binding."""
    # Split by build methods roughly
    parts = re.split(r"(Widget\s+build\(\s*BuildContext\s+context\s*\)\s*\{)", text)
    if len(parts) == 1:
        # Maybe builder: (context, ...) patterns - add at first use sites is harder.
        # Add near top of State classes? Skip.
        if "final l10n = context.l10n" not in text and "l10n." in text:
            # try StatefulBuilder / builder callbacks
            text = re.sub(
                r"(builder:\s*\(\s*context\s*(?:,\s*\w+)?\s*\)\s*\{)",
                r"\1\n                  final l10n = context.l10n;",
                text,
            )
        return text

    out = [parts[0]]
    i = 1
    while i < len(parts):
        header = parts[i]
        body = parts[i + 1] if i + 1 < len(parts) else ""
        # Only first portion of body until next method is ambiguous; check if l10n used in following chunk
        chunk = body
        if "l10n." in chunk and "final l10n = context.l10n" not in chunk[:400]:
            body = "\n    final l10n = context.l10n;" + body
        out.append(header)
        out.append(body)
        i += 2
    return "".join(out)


def main() -> None:
    mapping = load_map()
    changed = []
    for path in LIB.rglob("*.dart"):
        try:
            top = path.relative_to(LIB).parts[0]
        except Exception:
            continue
        if top not in INCLUDE:
            continue
        if process_file(path, mapping):
            changed.append(path.relative_to(LIB).as_posix())
    print(f"updated {len(changed)} files")
    for c in changed:
        print(" ", c)


if __name__ == "__main__":
    main()
