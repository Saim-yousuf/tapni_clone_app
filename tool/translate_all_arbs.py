#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Translate app_en.arb into all unique WhatsApp app languages.
Regional variants (es_MX, ar_EG, en_US...) reuse base ARBs via Flutter fallback.
"""
from __future__ import annotations

import json
import re
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
L10N = ROOT / "lib" / "l10n"
EN_PATH = L10N / "app_en.arb"
PLACEHOLDER_RE = re.compile(r"\{[a-zA-Z_][a-zA-Z0-9_]*\}")

# Flutter ARB locale -> MyMemory / Google-compatible target
TARGETS: dict[str, str] = {
    "af": "af",
    "sq": "sq",
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
    "prs_AF": "fa",  # Dari ~ Persian
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
    "pt_BR": "pt-BR",
    "pt_PT": "pt-PT",
    "pa": "pa",
    "ro": "ro",
    "ru": "ru",
    "sr": "sr",
    "si_LK": "si",
    "sk": "sk",
    "sl": "sl",
    "sw": "sw",
    "sv": "sv",
    "ta": "ta",
    "te": "te",
    "th": "th",
    "tr": "tr",
    "uk": "uk",
    "uz": "uz",
    "vi": "vi",
    "zu": "zu",
    # Complete / refresh existing non-English packs to full key coverage
    "ur": "ur",
    "ar": "ar",
    "hi": "hi",
    "es": "es",
}

SKIP_IF_COMPLETE = {"en"}  # never overwrite template

KEEP_AS_IS_KEYS = {"appTitle", "barqody", "tapni", "aabbccdd", "jpg", "png", "ai", "pro"}


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


def translate_one(text: str, target: str) -> str:
    protected, phs = protect(text)
    q = urllib.parse.quote(protected[:450])
    url = (
        "https://api.mymemory.translated.net/get"
        f"?q={q}&langpair=en|{urllib.parse.quote(target)}"
    )
    try:
        with urllib.request.urlopen(url, timeout=15) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        tr = data.get("responseData", {}).get("translatedText") or protected
        upper = tr.upper()
        if "INVALID" in upper or "MYMEMORY WARNING" in upper or "QUERY LENGTH" in upper:
            return text
        return restore(tr, phs)
    except Exception:
        return text


def is_complete(path: Path, expected_keys: set[str]) -> bool:
    if not path.exists():
        return False
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return False
    keys = {k for k in data if not k.startswith("@") and k != "@@locale"}
    return expected_keys.issubset(keys)


def translate_locale(locale: str, mm_target: str, en: dict, keys: list[str]) -> None:
    out_path = L10N / f"app_{locale}.arb"
    expected = set(keys)
    if locale in SKIP_IF_COMPLETE:
        return
    if is_complete(out_path, expected) and locale not in {"ur", "ar", "hi"}:
        # Always refresh short packs; skip complete others
        print(f"SKIP complete {locale}")
        return

    # Refresh ur/ar/hi/es if incomplete
    if is_complete(out_path, expected):
        print(f"SKIP complete {locale}")
        return

    print(f"TRANSLATING {locale} ({mm_target}) ...")
    out: dict = {"@@locale": locale.replace("-", "_")}
    # ensure @@locale matches Flutter (underscore)
    out["@@locale"] = locale

    pending: list[tuple[str, str]] = []
    for k in keys:
        src = en[k]
        if k in KEEP_AS_IS_KEYS:
            out[k] = src if k != "appTitle" else "BarQody"
            continue
        pending.append((k, src))

    results: dict[str, str] = {}
    with ThreadPoolExecutor(max_workers=8) as pool:
        futs = {
            pool.submit(translate_one, text, mm_target): key for key, text in pending
        }
        done = 0
        for fut in as_completed(futs):
            key = futs[fut]
            results[key] = fut.result()
            done += 1
            if done % 50 == 0:
                print(f"  {locale}: {done}/{len(pending)}")
                time.sleep(0.15)

    out.update(results)
    for k in keys:
        meta = en.get("@" + k)
        if isinstance(meta, dict):
            out["@" + k] = meta

    out_path.write_text(
        json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"WROTE {out_path.name}")


def main() -> None:
    en = json.loads(EN_PATH.read_text(encoding="utf-8"))
    keys = [
        k
        for k, v in en.items()
        if not k.startswith("@") and k != "@@locale" and isinstance(v, str)
    ]
    print(f"source keys={len(keys)} targets={len(TARGETS)}")

    # Translate incomplete existing packs first (user-facing)
    priority = ["es", "ur", "ar", "hi", "fr", "de", "pt_BR", "id", "tr", "ru"]
    ordered = priority + [k for k in TARGETS if k not in priority]

    for locale in ordered:
        mm = TARGETS[locale]
        try:
            translate_locale(locale, mm, en, keys)
        except Exception as e:
            print(f"FAIL {locale}: {e!r}")
        time.sleep(0.4)

    print("ALL DONE")


if __name__ == "__main__":
    main()
