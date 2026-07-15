#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Extract leftover UI strings, add to EN ARB, and replace with context.l10n."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"
EN_PATH = LIB / "l10n" / "app_en.arb"
IMPORT = "import 'package:tapni_app/l10n/app_localizations_fallback.dart';\n"

RESERVED = {
    "assert", "break", "case", "catch", "class", "const", "continue", "default",
    "do", "else", "enum", "extends", "false", "final", "finally", "for", "if",
    "in", "is", "new", "null", "rethrow", "return", "super", "switch", "this",
    "throw", "true", "try", "var", "void", "while", "with", "async", "await",
    "yield", "late", "required", "typedef", "abstract", "as", "on", "show",
    "hide", "of", "get", "set", "part", "library", "import", "export",
}

SKIP_EXACT = {
    "My Card", "Links", "Contacts", "Explore", "Settings",
    "personal", "business", "cardType", "label", "firstName", "lastName",
    "bio", "phone", "email", "website", "company", "jobTitle", "fax",
    "address", "street", "number", "city", "zip", "country",
    "businessPhone", "businessEmail", "businessWebsite", "businessAddress",
    "businessStreet", "businessNumber", "businessCity", "businessZip",
    "businessCountry", "title", "completed", "onTap", "name", "photo",
    "cover", "social", "voice", "gallery", "true", "false", "null",
}

UI_PATTERNS = [
    re.compile(r"""Text\(\s*'([^'\\]*(?:\\.[^'\\]*)*)'"""),
    re.compile(r'''Text\(\s*"([^"\\]*(?:\\.[^"\\]*)*)"'''),
    re.compile(
        r"""(?:hintText|labelText|helperText|tooltip|semanticLabel|buttonLabel|message)\s*:\s*'([^'\\]*(?:\\.[^'\\]*)*)'"""
    ),
    re.compile(
        r'''(?:hintText|labelText|helperText|tooltip|semanticLabel|buttonLabel|message)\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"'''
    ),
    # Map / list titles used as UI: 'title': 'Add Bio'
    re.compile(r"""['\"]title['\"]\s*:\s*'([^'\\]*(?:\\.[^'\\]*)*)'"""),
    re.compile(r'''['\"]title['\"]\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"'''),
    # SnackBar content: Text('...')
    re.compile(r"""SnackBar\([^;]{0,200}?Text\(\s*'([^']+)'"""),
]


def is_ui(s: str) -> bool:
    s = s.strip()
    if len(s) < 2 or len(s) > 140:
        return False
    if s in SKIP_EXACT:
        return False
    if "${" in s or "$" in s:
        return False
    if s.startswith(("assets/", "package:", "http")):
        return False
    # camelCase / snake identifiers
    if re.fullmatch(r"[a-z]+([A-Z][a-z0-9]+)+", s):
        return False
    if re.fullmatch(r"[a-z][a-z0-9_]*", s) and "_" in s:
        return False
    if not re.search(r"[A-Za-z]", s):
        return False
    # Prefer phrases with spaces, punctuation, or Title Case words
    if " " in s or any(ch in s for ch in ".!?,:;-—–/'"):
        return True
    # Single Title/UPPER words that look like labels
    if re.fullmatch(r"[A-Z][A-Za-z0-9+&/()-]{1,30}", s):
        return True
    if re.fullmatch(r"[A-Z]{2,20}", s):
        return True
    return False


def to_key(s: str) -> str:
    raw = s.replace("—", " ").replace("–", " ").replace("'", "").replace("'", "")
    raw = re.sub(r"[^A-Za-z0-9\s]+", " ", raw)
    parts = [p for p in raw.split() if p]
    if not parts:
        return "strExtra"
    key = parts[0].lower() + "".join(p[:1].upper() + p[1:] for p in parts[1:])
    if key[0].isdigit():
        key = "n" + key
    if key in RESERVED:
        key += "Label"
    return key[:80]


def collect() -> dict[str, set[str]]:
    found: dict[str, set[str]] = {}
    for folder in ("screens", "widgets"):
        for path in (LIB / folder).rglob("*.dart"):
            text = path.read_text(encoding="utf-8", errors="ignore")
            hits: set[str] = set()
            for pat in UI_PATTERNS:
                for m in pat.findall(text):
                    if is_ui(m):
                        hits.add(m.replace("\\'", "'").replace('\\"', '"'))
            # Also catch standalone 'Title Case Phrase' in UI maps commonly used
            for m in re.findall(r"""'([A-Z][^']{2,80})'""", text):
                if is_ui(m) and (" " in m or m.endswith("?") or m.endswith("!")):
                    hits.add(m)
            if hits:
                found[path.as_posix()] = hits
    return found


def main() -> None:
    en = json.loads(EN_PATH.read_text(encoding="utf-8"))
    value_to_key = {
        v: k
        for k, v in en.items()
        if isinstance(v, str) and not k.startswith("@") and k != "@@locale"
    }
    used = set(value_to_key.values())

    by_file = collect()
    all_strings: set[str] = set()
    for ss in by_file.values():
        all_strings |= ss

    added = 0
    for s in sorted(all_strings):
        if s in value_to_key:
            continue
        base = to_key(s)
        key = base
        n = 2
        while key in used:
            key = f"{base}{n}"
            n += 1
        en[key] = s
        value_to_key[s] = key
        used.add(key)
        added += 1

    EN_PATH.write_text(json.dumps(en, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"added {added} keys to EN ARB; total strings targeted {len(all_strings)}")

    # Apply replacements
    items = sorted(value_to_key.items(), key=lambda kv: len(kv[0]), reverse=True)
    changed_files = 0
    for folder in ("screens", "widgets"):
        for path in (LIB / folder).rglob("*.dart"):
            text = path.read_text(encoding="utf-8")
            orig = text
            for english, key in items:
                if english in {"My Card", "Links", "Contacts", "Explore", "Settings"}:
                    continue
                for quote in ("'", '"'):
                    lit = quote + english.replace("\\", "\\\\").replace(quote, "\\" + quote) + quote
                    if lit not in text:
                        continue

                    def repl(m, _key=key):
                        start = m.start()
                        line_start = text.rfind("\n", 0, start) + 1
                        line_end = text.find("\n", start)
                        if line_end < 0:
                            line_end = len(text)
                        line = text[line_start:line_end]
                        if "import " in line or "assets/" in line:
                            return m.group(0)
                        if re.search(r"(==|!=|case\s+)\s*$", text[max(0, start - 12):start]):
                            return m.group(0)
                        if "currentPage" in line or "_switchTab" in line:
                            return m.group(0)
                        return f"context.l10n.{_key}"

                    text = re.sub(re.escape(lit), repl, text)

            if text == orig:
                continue

            # strip const near context.l10n
            lines = []
            for line in text.splitlines(keepends=True):
                if "context.l10n." in line and "const " in line:
                    line = line.replace("const ", "", 1)
                lines.append(line)
            text = "".join(lines)

            # strip const before blocks containing l10n
            def strip_const_blocks(src: str) -> str:
                out = []
                i = 0
                while True:
                    m = re.search(r"\bconst\s+", src[i:])
                    if not m:
                        out.append(src[i:])
                        break
                    start = i + m.start()
                    after = i + m.end()
                    out.append(src[i:start])
                    window = src[after : after + 1000]
                    if "context.l10n." in window:
                        i = after
                    else:
                        out.append(src[start:after])
                        i = after
                return "".join(out)

            text = strip_const_blocks(text)

            if "app_localizations_fallback.dart" not in text and "context.l10n." in text:
                im = list(re.finditer(r"^import .*;\s*\n", text, re.M))
                if im:
                    e = im[-1].end()
                    text = text[:e] + IMPORT + text[e:]
                else:
                    text = IMPORT + text

            path.write_text(text, encoding="utf-8")
            changed_files += 1
            print("updated", path.relative_to(LIB))

    print(f"changed_files={changed_files}")


if __name__ == "__main__":
    main()
