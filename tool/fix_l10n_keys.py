#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fix reserved-word ARB keys and inject missing l10n locals."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
L10N = ROOT / "lib" / "l10n"
EN = L10N / "app_en.arb"
MAP = Path(__file__).resolve().parent / "string_key_map.json"
LIB = ROOT / "lib"

RESERVED = {
    "assert", "break", "case", "catch", "class", "const", "continue", "default",
    "do", "else", "enum", "extends", "false", "final", "finally", "for", "if",
    "in", "is", "new", "null", "rethrow", "return", "super", "switch", "this",
    "throw", "true", "try", "var", "void", "while", "with", "async", "await",
    "yield", "late", "required", "typedef", "abstract", "covariant", "dynamic",
    "export", "extension", "external", "factory", "get", "implements", "import",
    "interface", "library", "mixin", "operator", "part", "set", "static",
    "as", "on", "show", "hide", "of", "function",
}


def fix_arb_keys() -> dict[str, str]:
    """Returns old_key -> new_key renames."""
    arb = json.loads(EN.read_text(encoding="utf-8"))
    renames: dict[str, str] = {}
    keys = list(arb.keys())
    for k in keys:
        if k.startswith("@") or k == "@@locale":
            continue
        if k in RESERVED or not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", k):
            new_k = f"{k}Label" if k in RESERVED else f"str_{re.sub(r'[^A-Za-z0-9_]', '', k)}"
            if not new_k[0].isalpha() and new_k[0] != "_":
                new_k = "s" + new_k
            # ensure unique
            base = new_k
            n = 2
            while new_k in arb or new_k in renames.values():
                new_k = f"{base}{n}"
                n += 1
            renames[k] = new_k

    if not renames:
        print("no renames needed")
        return {}

    new_arb = {"@@locale": "en"}
    for k, v in arb.items():
        if k == "@@locale":
            continue
        if k.startswith("@"):
            base = k[1:]
            if base in renames:
                new_arb["@" + renames[base]] = v
            else:
                new_arb[k] = v
            continue
        if k in renames:
            new_arb[renames[k]] = v
        else:
            new_arb[k] = v

    EN.write_text(json.dumps(new_arb, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"renamed {len(renames)} keys: {renames}")

    for locale_file in ("app_ur.arb", "app_ar.arb", "app_hi.arb"):
        p = L10N / locale_file
        if not p.exists():
            continue
        loc = json.loads(p.read_text(encoding="utf-8"))
        new_loc = {}
        for k, v in loc.items():
            if k.startswith("@") and k != "@@locale":
                base = k[1:]
                new_loc["@" + renames.get(base, base)] = v
            elif k in renames:
                new_loc[renames[k]] = v
            else:
                new_loc[k] = v
        p.write_text(json.dumps(new_loc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print("updated locale", locale_file)

    # update map values
    mapping = json.loads(MAP.read_text(encoding="utf-8"))
    for eng, key in list(mapping.items()):
        if key in renames:
            mapping[eng] = renames[key]
    MAP.write_text(json.dumps(mapping, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # update dart references l10n.old -> l10n.new
    for path in LIB.rglob("*.dart"):
        if "l10n" in path.parts and path.name.startswith("app_localizations"):
            continue
        text = path.read_text(encoding="utf-8")
        orig = text
        for old, new in renames.items():
            text = re.sub(rf"\bl10n\.{re.escape(old)}\b", f"l10n.{new}", text)
        if text != orig:
            path.write_text(text, encoding="utf-8")
            print("updated refs", path.relative_to(LIB))

    return renames


def inject_missing_l10n() -> None:
    """For dart files that use l10n. but have undefined scopes, inject locals."""
    include = {"screens", "widgets", "helper"}
    for path in LIB.rglob("*.dart"):
        try:
            top = path.relative_to(LIB).parts[0]
        except Exception:
            continue
        if top not in include:
            continue
        text = path.read_text(encoding="utf-8")
        if "l10n." not in text:
            continue
        if "app_localizations_fallback.dart" not in text:
            # add import
            m = list(re.finditer(r"^import .*;\s*\n", text, re.M))
            if m:
                i = m[-1].end()
                text = (
                    text[:i]
                    + "import 'package:tapni_app/l10n/app_localizations_fallback.dart';\n"
                    + text[i:]
                )

        # In every function/method body that references l10n. without a nearby final l10n
        # Strategy: for each `) {` that starts a block containing l10n., ensure first line has final l10n if context available.

        # Inject into build methods
        def fix_build(m: re.Match) -> str:
            header = m.group(1)
            return header + "\n    final l10n = context.l10n;"

        # Only add if build doesn't already have it at the start
        text2 = re.sub(
            r"(Widget\s+build\(\s*BuildContext\s+context\s*\)\s*\{)(?!\s*final l10n = context\.l10n)",
            fix_build,
            text,
        )

        # builder: (context) {
        text2 = re.sub(
            r"(builder:\s*\(\s*context\s*(?:,\s*[^)]+)?\s*\)\s*\{)(?!\s*final l10n = context\.l10n)",
            r"\1\n      final l10n = context.l10n;",
            text2,
        )

        # showModalBottomSheet / showDialog builder
        text2 = re.sub(
            r"(builder:\s*\(?(?:BuildContext\s+)?ctx\)\s*\{)(?!\s*final l10n)",
            r"\1\n        final l10n = ctx.l10n;",
            text2,
        )
        text2 = re.sub(
            r"(builder:\s*\(?(?:BuildContext\s+)?context\)\s*\{)(?!\s*final l10n)",
            r"\1\n        final l10n = context.l10n;",
            text2,
        )

        # Methods with BuildContext context that use l10n
        # e.g. void foo(BuildContext context) async {
        text2 = re.sub(
            r"((?:void|Future<[^>]+>|Widget|String|bool)\s+\w+\([^)]*BuildContext\s+context[^)]*\)\s*(?:async\s*)?\{)(?![^}]*final l10n = context\.l10n)",
            lambda m: m.group(1) + "\n    final l10n = context.l10n;" if "l10n." in text[m.end():m.end()+800] else m.group(1),
            text2,
        )

        # Deduplicate consecutive final l10n lines
        text2 = re.sub(
            r"(final l10n = context\.l10n;\s*){2,}",
            "final l10n = context.l10n;\n",
            text2,
        )
        text2 = re.sub(
            r"(final l10n = ctx\.l10n;\s*){2,}",
            "final l10n = ctx.l10n;\n",
            text2,
        )

        if text2 != text:
            path.write_text(text2, encoding="utf-8")
            print("injected", path.relative_to(LIB))


def strip_invalid_const() -> None:
    for path in LIB.rglob("*.dart"):
        try:
            top = path.relative_to(LIB).parts[0]
        except Exception:
            continue
        if top not in {"screens", "widgets", "helper"}:
            continue
        text = path.read_text(encoding="utf-8")
        orig = text
        # Remove const when line has l10n.
        lines = []
        for line in text.splitlines(keepends=True):
            if "l10n." in line and "const " in line:
                line = line.replace("const ", "", 1)
            lines.append(line)
        text = "".join(lines)
        if text != orig:
            path.write_text(text, encoding="utf-8")


def main() -> None:
    fix_arb_keys()
    inject_missing_l10n()
    strip_invalid_const()
    print("done")


if __name__ == "__main__":
    main()
