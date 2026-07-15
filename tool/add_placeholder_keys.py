#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
from pathlib import Path

p = Path(__file__).resolve().parents[1] / "lib" / "l10n" / "app_en.arb"
en = json.loads(p.read_text(encoding="utf-8"))
adds = {
    "addCatalogItem": "Add {label} item",
    "@addCatalogItem": {"placeholders": {"label": {"type": "String"}}},
    "addAtLeastOneCatalogItem": "Add at least one {label} item",
    "@addAtLeastOneCatalogItem": {"placeholders": {"label": {"type": "String"}}},
    "noCatalogItemsAvailable": "No {label} items available.",
    "@noCatalogItemsAvailable": {"placeholders": {"label": {"type": "String"}}},
    "noItemsYetAddFirstCatalogItem": "No items yet. Add your first {label} item.",
    "@noItemsYetAddFirstCatalogItem": {
        "placeholders": {"label": {"type": "String"}}
    },
    "noPublicProfileMatchesQuery": 'No public profile matches "@{query}".',
    "@noPublicProfileMatchesQuery": {
        "placeholders": {"query": {"type": "String"}}
    },
    "codeWithValue": "Code: {code}",
    "@codeWithValue": {"placeholders": {"code": {"type": "String"}}},
}
en.update(adds)
p.write_text(json.dumps(en, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("ok")
