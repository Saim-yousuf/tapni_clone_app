#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Copy regional packs to base aliases Flutter may resolve (be, si, rw, ky, ps, zh, pt)."""
from __future__ import annotations

import json
from pathlib import Path

L10N = Path(__file__).resolve().parents[1] / "lib" / "l10n"

COPIES = {
    "be_BY": "be",
    "si_LK": "si",
    "rw_RW": "rw",
    "ky_KG": "ky",
    "ps_AF": "ps",
    "zh_CN": "zh",
    "pt_BR": "pt",
    "prs_AF": None,  # Dari uses fa via fallback; no separate base
}


def main() -> None:
    for src, dst in COPIES.items():
        if not dst:
            continue
        src_path = L10N / f"app_{src}.arb"
        dst_path = L10N / f"app_{dst}.arb"
        if not src_path.exists():
            print(f"skip missing {src_path.name}")
            continue
        data = json.loads(src_path.read_text(encoding="utf-8"))
        data["@@locale"] = dst
        dst_path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        print(f"copied {src} -> {dst}")


if __name__ == "__main__":
    main()
