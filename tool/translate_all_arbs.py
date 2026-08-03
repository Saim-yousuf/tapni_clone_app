#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fast parallel ARB translator — many locales at once."""
from __future__ import annotations

import json
import re
import sys
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
L10N = ROOT / "lib" / "l10n"
EN_PATH = L10N / "app_en.arb"
PLACEHOLDER_RE = re.compile(r"\{[a-zA-Z_][a-zA-Z0-9_]*\}")

TARGETS: dict[str, str] = {
    "af": "af",
    "sq": "sq",
    "ar": "ar",
    "az": "az",
    "be_BY": "be",
    "bn": "bn",
    "bg": "bg",
    "ca": "ca",
    "zh_CN": "zh-CN",
    "zh_HK": "zh-TW",
    "zh_TW": "zh-TW",
    "hr": "hr",
    "cs": "cs",
    "da": "da",
    "prs_AF": "fa",
    "nl": "nl",
    "et": "et",
    "fil": "tl",
    "fi": "fi",
    "fr": "fr",
    "ka": "ka",
    "de": "de",
    "el": "el",
    "gu": "gu",
    "ha": "ha",
    "he": "he",
    "hi": "hi",
    "hu": "hu",
    "id": "id",
    "ga": "ga",
    "it": "it",
    "ja": "ja",
    "kn": "kn",
    "kk": "kk",
    "rw_RW": "rw",
    "ko": "ko",
    "ky_KG": "ky",
    "lo": "lo",
    "lv": "lv",
    "lt": "lt",
    "mk": "mk",
    "ms": "ms",
    "ml": "ml",
    "mr": "mr",
    "nb": "no",
    "ps_AF": "ps",
    "fa": "fa",
    "pl": "pl",
    "pt_BR": "pt",
    "pt_PT": "pt",
    "pa": "pa",
    "ro": "ro",
    "ru": "ru",
    "sr": "sr",
    "si_LK": "si",
    "sk": "sk",
    "sl": "sl",
    "es": "es",
    "sw": "sw",
    "sv": "sv",
    "ta": "ta",
    "te": "te",
    "th": "th",
    "tr": "tr",
    "uk": "uk",
    "ur": "ur",
    "uz": "uz",
    "vi": "vi",
    "zu": "zu",
}

KEEP = {"appTitle", "barqody", "tapni", "aabbccdd", "jpg", "png", "ai", "pro"}


def protect(text: str) -> tuple[str, list[str]]:
    found = PLACEHOLDER_RE.findall(text)
    out = text
    for i, ph in enumerate(found):
        out = out.replace(ph, f"__PH{i}__", 1)
    return out, found


def restore(text: str, found: list[str]) -> str:
    out = text
    for i, ph in enumerate(found):
        out = out.replace(f"__PH{i}__", ph).replace(f"__ph{i}__", ph)
    return out


def translate_google(text: str, target: str) -> str | None:
    q = urllib.parse.quote(text)
    tl = urllib.parse.quote(target)
    url = (
        "https://translate.googleapis.com/translate_a/single"
        f"?client=gtx&sl=en&tl={tl}&dt=t&q={q}"
    )
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        parts = []
        for chunk in data[0]:
            if isinstance(chunk, list) and chunk and isinstance(chunk[0], str):
                parts.append(chunk[0])
        out = "".join(parts).strip()
        return out or None
    except Exception:
        return None


def translate_one(text: str, target: str) -> str:
    protected, phs = protect(text)
    if not protected.strip():
        return text
    tr = translate_google(protected, target)
    if not tr:
        return text
    return restore(tr, phs)


def coverage(path: Path, en: dict, keys: list[str]) -> float:
    if not path.exists():
        return 0.0
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return 0.0
    diff = 0
    for k in keys:
        if k in KEEP:
            continue
        v = data.get(k)
        if isinstance(v, str) and v and v != en[k]:
            diff += 1
    denom = max(1, len(keys) - len(KEEP))
    return diff / denom


def translate_locale(locale: str, target: str, en: dict, keys: list[str]) -> str:
    out_path = L10N / f"app_{locale}.arb"
    existing = {}
    if out_path.exists():
        try:
            existing = json.loads(out_path.read_text(encoding="utf-8"))
        except Exception:
            existing = {}

    out: dict = {"@@locale": locale}
    pending: list[tuple[str, str]] = []
    for k in keys:
        src = en[k]
        if k in KEEP:
            out[k] = "BarQody" if k == "appTitle" else src
            continue
        cur = existing.get(k)
        if isinstance(cur, str) and cur.strip() and cur != src:
            out[k] = cur
        else:
            pending.append((k, src))

    if not pending:
        for k in keys:
            meta = en.get("@" + k)
            if isinstance(meta, dict):
                out["@" + k] = meta
        out_path.write_text(
            json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        return f"SKIP {locale}"

    results: dict[str, str] = {}
    # High parallelism per locale
    with ThreadPoolExecutor(max_workers=16) as pool:
        futs = {pool.submit(translate_one, text, target): key for key, text in pending}
        for fut in as_completed(futs):
            results[futs[fut]] = fut.result()

    out.update(results)
    for k in keys:
        if k not in out:
            out[k] = en[k]
        meta = en.get("@" + k)
        if isinstance(meta, dict):
            out["@" + k] = meta

    out_path.write_text(
        json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    changed = sum(1 for k, v in results.items() if v != en[k])
    return f"OK {locale} {changed}/{len(pending)}"


def main() -> None:
    # unbuffered prints
    sys.stdout.reconfigure(encoding="utf-8", errors="replace") if hasattr(
        sys.stdout, "reconfigure"
    ) else None

    en = json.loads(EN_PATH.read_text(encoding="utf-8"))
    keys = [
        k
        for k, v in en.items()
        if not k.startswith("@") and k != "@@locale" and isinstance(v, str)
    ]

    only = [a for a in sys.argv[1:] if not a.startswith("-")]
    force = "--force" in sys.argv
    locales = list(TARGETS.keys()) if not only else [x for x in only if x in TARGETS]

    todo = []
    for loc in locales:
        cov = coverage(L10N / f"app_{loc}.arb", en, keys)
        if not force and cov >= 0.85:
            print(f"DONE-ish {loc} cov={cov:.0%}", flush=True)
            continue
        todo.append(loc)

    print(f"keys={len(keys)} todo={len(todo)} parallel_locales=8", flush=True)
    t0 = time.time()

    # Translate several locales concurrently
    with ThreadPoolExecutor(max_workers=8) as pool:
        futs = {
            pool.submit(translate_locale, loc, TARGETS[loc], en, keys): loc
            for loc in todo
        }
        for fut in as_completed(futs):
            loc = futs[fut]
            try:
                print(fut.result(), flush=True)
            except Exception as e:
                print(f"FAIL {loc}: {e!r}", flush=True)

    print(f"ALL DONE in {time.time() - t0:.0f}s", flush=True)


if __name__ == "__main__":
    main()
