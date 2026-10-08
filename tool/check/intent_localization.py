#!/usr/bin/env python3
"""Validate native SiriKit string tables using only the Python standard library.

An intent named Foo.intentdefinition looks up Foo.strings, not
Foo.intentdefinition.strings. A catalog with the latter name compiles cleanly
but leaves the intent's localized metadata unresolved (ITMS-90626).
"""

import collections
import json
from pathlib import Path
import plistlib
import re
import sys


def validate(root):
    """Return actionable violations; locales come from the Xcode project."""
    errors = []
    project = (root / "ios/Runner.xcodeproj/project.pbxproj").read_text()
    regions = re.search(r"knownRegions\s*=\s*\((.*?)\);", project, re.S)
    development = re.search(r"developmentRegion\s*=\s*([^;]+);", project)
    if not regions or not development:
        return ["Xcode project: missing localization metadata"]
    locales = [s.strip().strip('"') for s in regions[1].split(",") if s.strip()]
    locales = [s for s in locales if s != "Base"]
    source = development[1].strip().strip('"')
    if source not in locales or len(locales) != len(set(locales)):
        errors.append("Xcode project: invalid supported locales/developmentRegion")

    definitions = sorted((root / "ios").rglob("*.intentdefinition"))
    if not definitions:
        return ["No native Intent definitions found"]
    for definition in definitions:
        label = str(definition.relative_to(root))
        try:
            model = plistlib.loads(definition.read_bytes())
            # Use the definition's stem, matching Apple's metadata loader.
            catalog_path = definition.with_suffix(".xcstrings")
            catalog = json.loads(catalog_path.read_text())
        except (OSError, ValueError, plistlib.InvalidFileException) as error:
            errors.append(f"{label}: cannot load matching Intent/catalog ({error})")
            continue
        if definition.with_name(definition.name + ".xcstrings").exists():
            errors.append(f"{label}: incorrectly named .intentdefinition.xcstrings table")
        if catalog.get("sourceLanguage") != source or catalog.get("version") != "1.0":
            errors.append(f"{label}: invalid catalog sourceLanguage/version")

        references = {}

        def visit(value):
            if isinstance(value, list):
                for item in value:
                    visit(item)
            elif isinstance(value, dict):
                for key, item in value.items():
                    if key.endswith(("TitleID", "DescriptionID", "DisplayNameID", "FormatStringID")):
                        base = value.get(key[:-2])
                        if not isinstance(item, str) or not item.strip():
                            errors.append(f"{label}: empty localization ID for {key}")
                            continue
                        if not isinstance(base, str) or not base.strip():
                            errors.append(f"{label}: missing/empty base {key[:-2]}")
                        if item in references and references[item] != base:
                            errors.append(f"{label}: conflicting localization ID {item}")
                        references[item] = base
                    visit(item)

        for intent in model.get("INIntents", []):
            for key in ("INIntentTitle", "INIntentDescription"):
                if not intent.get(key) or not intent.get(key + "ID"):
                    errors.append(f"{label}: missing/empty {key} or {key}ID")
        visit(model)
        entries = catalog.get("strings", {})
        for key in sorted(set(entries) - set(references)):
            errors.append(f"{label}: unreferenced catalog ID {key}")
        for key, base in references.items():
            entry = entries.get(key)
            if not isinstance(entry, dict):
                errors.append(f"{label}: missing referenced localization ID {key}")
                continue
            if entry.get("shouldTranslate") is False or entry.get("extractionState") not in (
                None, "manual", "extracted"
            ):
                errors.append(f"{label}: invalid localization metadata for {key}")
            translations = entry.get("localizations", {})
            for locale in locales:
                unit = translations.get(locale, {}).get("stringUnit", {})
                text = unit.get("value")
                if not isinstance(text, str) or not text.strip():
                    errors.append(f"{label}: {key}/{locale}: missing/empty translation")
                    continue
                if unit.get("state") != "translated":
                    errors.append(f"{label}: {key}/{locale}: state must be translated")
                if locale == source and text != base:
                    errors.append(f"{label}: {key}/{locale}: source differs from Intent base")
                placeholders = lambda s: collections.Counter(re.findall(r"\$\{[^}]+\}", s or ""))
                if placeholders(text) != placeholders(base):
                    errors.append(f"{label}: {key}/{locale}: mismatched placeholders")
    return errors


if __name__ == "__main__":
    try:
        violations = validate(Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[2])
    except (OSError, ValueError, TypeError, AttributeError) as error:
        violations = [f"Cannot validate native Intent localization: {error}"]
    for violation in violations:
        print(violation)
    sys.exit(bool(violations))
