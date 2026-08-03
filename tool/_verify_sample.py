import json
from pathlib import Path

d = Path(r"lib/l10n")
for name in ("app_ar.arb", "app_hi.arb"):
    data = json.loads((d / name).read_text(encoding="utf-8"))
    line = f"{name}: tools={data.get('tools')!r} contacts={data.get('contacts')!r} appLanguage={data.get('appLanguage')!r}\n"
    Path("_verify_l10n.txt").write_text(line, encoding="utf-8", append=False) if name.endswith("ar.arb") else None
    with open("_verify_l10n.txt", "a", encoding="utf-8") as f:
        f.write(line)
print("ok")
