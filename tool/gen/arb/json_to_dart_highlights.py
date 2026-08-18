#!/usr/bin/env python3
"""Convert a version's authored cards.json decks into Dart source files.

The version-highlight cards are authored in JSON at
`release_highlights/assets/<version>/{normal,advanced}/cards.json` — the
archival, human-writable format — and compiled into Dart source at
`release_highlights/lib/<version>/{normal,advanced}.dart`, which is what the app
imports (`package:dpip_release_highlights/<version>/...`). Each version keeps
its own Dart; the app imports only the current one.

Usage:  python3 tool/json_to_dart_highlights.py [VERSION ...]
        (default: every version directory under release_highlights/assets/)
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT = ROOT / "release_highlights"
ASSETS = CONTENT / "assets"
KINDS = ("normal", "advanced")

HEADER = """// Version-highlight card content for DPIP {version} ({kind}).
//
// GENERATED from `{archived}` by `tool/json_to_dart_highlights.py` — edit the
// JSON, not this file. Rendering lives in `lib/features/release_highlights`;
// this package carries only data.
library;

const title = {title};
const subtitle = {subtitle};
const cards = <Map<String, dynamic>>[
{cards}
];
"""


def dstr(s: str) -> str:
    return json.dumps(s, ensure_ascii=False)


def string_map(m) -> str:
    if not m:
        return "{}"
    return "{" + ", ".join(
        f"{dstr(k)}: {dstr(v)}" for k, v in m.items()
    ) + "}"


def optional_map(m) -> str:
    return "null" if m is None else string_map(m)


def render_card(c) -> str:
    details = "".join(
        f"{{'key': {string_map(d['key'])}, 'value': {string_map(d['value'])}}},\n"
        for d in c.get("details", [])
    )
    stats = "".join(
        f"{{'value': {string_map(s['value'])}, 'label': {string_map(s['label'])}}},\n"
        for s in c.get("stats", [])
    )
    highlights = "".join(f"{string_map(h)},\n" for h in c.get("highlights", []))

    return f"""  {{
    'id': {dstr(c['id'])},
    'icon': {dstr(c['icon'])},
    'title': {string_map(c['title'])},
    'headline': {optional_map(c.get('headline'))},
    'body': {optional_map(c.get('body'))},
    'stat': {optional_map(c.get('stat'))},
    'statLabel': {optional_map(c.get('statLabel'))},
    'highlights': <Map<String, String>>[
      {highlights.strip()}
    ],
    'details': <Map<String, dynamic>>[
      {details.strip()}
    ],
    'stats': <Map<String, dynamic>>[
      {stats.strip()}
    ],
  }}"""


def convert(version: str, kind: str) -> None:
    archived = ASSETS / version / kind / "cards.json"
    if not archived.is_file():
        raise SystemExit(f"missing {archived}")

    with archived.open(encoding="utf-8") as f:
        data = json.load(f)

    if data.get("version") != version:
        raise SystemExit(
            f"{archived} declares version {data.get('version')!r}, expected {version!r}"
        )

    body = HEADER.format(
        version=version,
        kind=kind,
        title=string_map(data["title"]),
        subtitle=string_map(data["subtitle"]),
        cards=",\n".join(render_card(c) for c in data["cards"]),
        archived=str(archived.relative_to(ROOT)),
    )

    out_dir = CONTENT / "lib" / version
    out_dir.mkdir(parents=True, exist_ok=True)
    target = out_dir / f"{kind}.dart"
    target.write_text(body, encoding="utf-8")
    print(f"wrote {target.relative_to(ROOT)}")


def main() -> None:
    versions = sys.argv[1:] or sorted(
        p.name for p in ASSETS.iterdir() if p.is_dir() and p.name[0].isdigit()
    )
    if not versions:
        raise SystemExit("no version directories found under release_highlights/assets/")
    for version in versions:
        for kind in KINDS:
            convert(version, kind)


if __name__ == "__main__":
    main()