#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""EN -> ES via MyMemory (threaded)."""
from __future__ import annotations

import json
import re
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EN_PATH = ROOT / "lib" / "l10n" / "app_en.arb"
OUT_PATH = ROOT / "lib" / "l10n" / "app_es.arb"
PLACEHOLDER_RE = re.compile(r"\{[a-zA-Z_][a-zA-Z0-9_]*\}")

# High-quality overrides for core UI (no API needed)
OVERRIDES = {
    "tools": "Herramientas",
    "accountSettings": "Ajustes de la cuenta",
    "notifications": "Notificaciones",
    "forYou": "Para ti",
    "yourProfile": "Tu perfil",
    "editProfile": "Editar perfil",
    "editProfileSubtitle": "Cambia tu nombre, foto y biografía",
    "username": "Nombre de usuario",
    "setUsernameSubtitle": "Elige un nombre de usuario único",
    "socialLinks": "Enlaces sociales",
    "socialLinksSubtitle": "Añade Instagram, WhatsApp, sitio web y más",
    "publicProfile": "Perfil público",
    "publicProfileOn": "Cualquiera puede encontrar y ver tu perfil",
    "publicProfileOff": "Oculto en la búsqueda: otros no pueden encontrarte",
    "shareQr": "Compartir mi código QR",
    "shareQrSubtitle": "Deja que otros escaneen tu tarjeta digital",
    "shoppingRewards": "Compras y recompensas",
    "myOrders": "Mis pedidos",
    "myOrdersSubtitle": "Sigue los pedidos de las tiendas",
    "myRewardCards": "Mis tarjetas de recompensa",
    "myRewardCardsSubtitle": "Ver sellos y puntos de programas de fidelidad",
    "workplace": "Lugar de trabajo",
    "employeeInvitations": "Invitaciones de empleado",
    "employeeInvitationsSubtitle": "Acepta o rechaza invitaciones de empresas",
    "workplaceCheckIn": "Fichaje laboral",
    "workplaceCheckInSubtitle": "Entra y sal del trabajo con ubicación",
    "accountsAndDevices": "Cuentas y dispositivos",
    "linkedDevices": "Dispositivos vinculados",
    "linkedDevicesSubtitle": "Vincula otro teléfono como WhatsApp",
    "accounts": "Cuentas",
    "accountsSubtitle": "Añadir o cambiar cuentas",
    "accountsSwitchSubtitle": "Cambiar entre {count} cuentas",
    "helpAndAccount": "Ayuda y cuenta",
    "appLanguage": "Idioma de la app",
    "appLanguageSubtitle": "Cambia el idioma usado en la app",
    "searchLanguage": "Buscar idioma",
    "phoneLanguage": "Idioma del teléfono",
    "languageUpdated": "Idioma actualizado",
    "helpFaqs": "Ayuda y preguntas",
    "helpFaqsSubtitle": "Respuestas a preguntas frecuentes",
    "sendFeedback": "Enviar comentarios",
    "sendFeedbackSubtitle": "Reporta un error o sugiere una función",
    "logOut": "Cerrar sesión",
    "logOutSubtitle": "Salir de esta sesión",
    "cancel": "Cancelar",
    "save": "Guardar",
    "done": "Listo",
    "appTitle": "BarQody",
    "links": "Enlaces",
    "contacts": "Contactos",
    "explore": "Explorar",
    "welcomeBack": "Bienvenido de nuevo",
    "logIn": "Iniciar sesión",
    "signUp": "Registrarse",
    "email": "Correo",
    "emailAddress": "Correo electrónico",
    "password": "Contraseña",
    "fullName": "Nombre completo",
    "next": "Siguiente",
    "skip": "Omitir",
    "close": "Cerrar",
    "delete": "Eliminar",
    "edit": "Editar",
    "share": "Compartir",
    "scan": "Escanear",
    "accept": "Aceptar",
    "decline": "Rechazar",
    "remove": "Eliminar",
    "create": "Crear",
    "apply": "Aplicar",
    "reset": "Restablecer",
    "tryAgain": "Intentar de nuevo",
    "somethingWentWrong": "Algo salió mal",
    "region": "Región",
    "selectRegion": "Seleccionar región",
    "showLink": "Mostrar enlace",
    "readOnly": "(Solo lectura)",
    "general": "General",
}


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


def translate_one(text: str) -> str:
    protected, phs = protect(text)
    q = urllib.parse.quote(protected[:450])
    url = f"https://api.mymemory.translated.net/get?q={q}&langpair=en|es"
    try:
        with urllib.request.urlopen(url, timeout=12) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        tr = data.get("responseData", {}).get("translatedText") or protected
        # MyMemory sometimes returns FAILED / INVALID
        if "INVALID" in tr.upper() or "MYMEMORY WARNING" in tr.upper():
            return text
        return restore(tr, phs)
    except Exception:
        return text


def main() -> None:
    en = json.loads(EN_PATH.read_text(encoding="utf-8"))
    keys = [
        k
        for k, v in en.items()
        if not k.startswith("@") and k != "@@locale" and isinstance(v, str)
    ]

    out: dict = {"@@locale": "es"}
    pending: list[tuple[str, str]] = []

    for k in keys:
        if k in OVERRIDES:
            out[k] = OVERRIDES[k]
        else:
            pending.append((k, en[k]))

    print(f"overrides={len(out)-1} pending_api={len(pending)}")

    # Threaded MyMemory
    results: dict[str, str] = {}
    with ThreadPoolExecutor(max_workers=8) as pool:
        futs = {pool.submit(translate_one, text): key for key, text in pending}
        done = 0
        for fut in as_completed(futs):
            key = futs[fut]
            results[key] = fut.result()
            done += 1
            if done % 40 == 0:
                print(f"  api {done}/{len(pending)}")
                time.sleep(0.2)

    out.update(results)
    for k in keys:
        meta = en.get("@" + k)
        if isinstance(meta, dict):
            out["@" + k] = meta

    OUT_PATH.write_text(
        json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"wrote {OUT_PATH} total={len(keys)}")


if __name__ == "__main__":
    main()
