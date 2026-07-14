#!/usr/bin/env bash
#
# Localization gate — enforces the i18n contract from CLAUDE.md without needing a
# build or `pub get`, so it fails fast in CI and can be run locally any time.
# Sibling to tool/check_layering.sh; same output style, zero new packages
# (bash + python3, both already in CI).
#
# Rules (see CLAUDE.md → Conventions → Localization):
#   1. ARB parity: every non-template lib/l10n/app_*.arb self-describes with
#      @@locale + languageName (the picker is derived from languageName, never a
#      hardcoded list) and its message-key SET exactly matches the template —
#      a MISSING key silently falls back to English; an EXTRA key is dead weight.
#   2. No hardcoded user-facing strings: a string LITERAL containing CJK / kana /
#      Hangul / Thai text must not appear in a feature's presentation layer or in
#      shared/widgets — those go through AppLocalizations/ARB. Comments are
#      exempt (that's where the design notes live); the '・' (U+30FB) data
#      separator is exempt. Two grep-auditable escape hatches:
#        • `l10n-ignore`      — one line (its own or the line above): a single
#                               non-display literal, or an intentional one-off.
#        • `l10n-ignore-file` — anywhere in the file (put it in the header doc
#                               comment): exempts the WHOLE file. For files that
#                               are entirely throwaway placeholder/mock data and
#                               will be deleted when the real feature is ported —
#                               localizing them is wasted effort. Audit both with
#                               `grep -rn l10n-ignore lib`.
#
# Usage:  tool/check_l10n.sh   (run from anywhere; cd's to the repo root)
set -euo pipefail

cd "$(dirname "$0")/.."

fail=0
report() {
  echo "  ✗ $1"
  fail=1
}

# ARB layout comes from l10n.yaml so this stays in lock-step with gen-l10n
# (don't hardcode the template name — derive it, same principle as the picker).
arb_dir=$(grep -E '^arb-dir:' l10n.yaml | sed -E 's/.*:[[:space:]]*//')
template=$(grep -E '^template-arb-file:' l10n.yaml | sed -E 's/.*:[[:space:]]*//')
: "${arb_dir:=lib/l10n}"
: "${template:=app_en.arb}"

# ── Rule 1: ARB parity ──────────────────────────────────────────────────────
# python3 owns JSON parsing (never hand-parse JSON in bash). It prints one
# violation per line; bash turns each into a report() so the ✗/exit style
# matches check_layering.sh. (Captured via $(…) then fed with <<< — a heredoc
# inside <(…) process substitution mis-parses on bash 3.2.)
arb_violations=$(python3 - "$arb_dir" "$template" <<'PY'
import json, glob, os, sys

arb_dir, template = sys.argv[1], sys.argv[2]
tpl_path = os.path.join(arb_dir, template)

def load(path):
    # A decode error is itself a violation — report it instead of crashing.
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f), None
    except (OSError, ValueError) as e:
        return None, str(e)

def message_keys(obj):
    # ARB metadata keys start with '@' (@key descriptions) or '@@' (@@locale).
    # Translatable messages are everything else — that's what must be in parity.
    return {k for k in obj if not k.startswith("@")}

tpl, err = load(tpl_path)
if err:
    print(f"{tpl_path} → cannot parse template ARB ({err})")
    sys.exit(0)
if "@@locale" not in tpl:
    print(f"{tpl_path} → template is missing @@locale")
if "languageName" not in tpl:
    print(f"{tpl_path} → template is missing languageName (picker source)")

tpl_keys = message_keys(tpl)

for path in sorted(glob.glob(os.path.join(arb_dir, "app_*.arb"))):
    if os.path.abspath(path) == os.path.abspath(tpl_path):
        continue
    obj, err = load(path)
    if err:
        print(f"{path} → invalid JSON ({err})")
        continue
    if "@@locale" not in obj:
        print(f"{path} → missing @@locale")
    if not obj.get("languageName"):
        print(f"{path} → missing languageName "
              f"(the language picker is built from this — add the locale's own name)")
    keys = message_keys(obj)
    missing = sorted(tpl_keys - keys)
    extra = sorted(keys - tpl_keys)
    if missing:
        shown = ", ".join(missing[:12]) + (" …" if len(missing) > 12 else "")
        print(f"{path} → missing {len(missing)} key(s) "
              f"(would silently fall back to English): {shown}")
    if extra:
        shown = ", ".join(extra[:12]) + (" …" if len(extra) > 12 else "")
        print(f"{path} → {len(extra)} unknown key(s) not in the template: {shown}")
PY
)
if [ -n "$arb_violations" ]; then
  while IFS= read -r v; do
    [ -z "$v" ] && continue
    report "$v"
  done <<< "$arb_violations"
fi

# ── Rule 2: no hardcoded user-facing strings ────────────────────────────────
# Scope: every feature's presentation layer + shared/widgets (the UI surface).
# Generated code is excluded. Build the file list in bash, hand it to python for
# a proper comment/string-aware scan (grep can't tell a literal from a comment).
files=""
while IFS= read -r f; do
  files="$files $f"
done < <(
  { find lib/features -path '*/presentation/*' -name '*.dart' 2>/dev/null || true
    find lib/shared/widgets -name '*.dart' 2>/dev/null || true
  } | grep -vE '\.(g|freezed)\.dart$' | sort
)

if [ -n "$files" ]; then
  # shellcheck disable=SC2086  # word-splitting the file list into argv is intended
  str_violations=$(python3 - $files <<'PY'
import sys

# Characters that make a string literal "user-facing text" rather than data.
# The '・' KATAKANA MIDDLE DOT (U+30FB) is deliberately EXCLUDED: it's used as a
# coordinate/data separator (see region_city_page.dart), not display prose.
def is_display_char(ch):
    o = ord(ch)
    if o == 0x30FB:                       # ・ data separator — allowed
        return False
    return (
        0x3000 <= o <= 0x303F or          # CJK Symbols & Punctuation 「」『』、。
        0x3040 <= o <= 0x309F or          # Hiragana
        0x30A0 <= o <= 0x30FF or          # Katakana (minus U+30FB above)
        0x3100 <= o <= 0x312F or          # Bopomofo (Taiwan zhuyin)
        0x31A0 <= o <= 0x31BF or          # Bopomofo Extended
        0x3400 <= o <= 0x4DBF or          # CJK Extension A
        0x4E00 <= o <= 0x9FFF or          # CJK Unified Ideographs
        0xAC00 <= o <= 0xD7A3 or          # Hangul syllables
        0x1100 <= o <= 0x11FF or          # Hangul Jamo
        0x0E00 <= o <= 0x0E7F or          # Thai
        0xF900 <= o <= 0xFAFF or          # CJK Compatibility Ideographs (name glyphs)
        0xFF00 <= o <= 0xFFEF or          # Halfwidth/Fullwidth Forms （）！？ ｶﾅ
        0x20000 <= o <= 0x2FA1F           # CJK Ext B–F + Compatibility Supplement
    )

def scan(src, base_line=1):
    """Single pass that knows the difference between code, comments and string
    literals, so CJK inside a `///` note or a `/* */` block is never flagged —
    only CJK inside an actual string literal is. Recurses into `${…}`
    interpolation so a nested display literal (e.g. a ternary) is still caught,
    while identifiers stay code. Returns (line, snippet) hits; the caller applies
    the l10n-ignore hatch against the real file lines (so it works for recursed
    hits too)."""
    n = len(src)
    i = 0
    line = base_line
    hits = []
    while i < n:
        c = src[i]
        # line comment (covers // and ///) — skip to end of line
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            while i < n and src[i] != "\n":
                i += 1
            continue
        # block comment (Dart allows nesting) — skip, tracking newlines
        if c == "/" and i + 1 < n and src[i + 1] == "*":
            depth, i = 1, i + 2
            while i < n and depth > 0:
                if src[i] == "\n":
                    line += 1; i += 1
                elif src[i] == "/" and i + 1 < n and src[i + 1] == "*":
                    depth += 1; i += 2
                elif src[i] == "*" and i + 1 < n and src[i + 1] == "/":
                    depth -= 1; i += 2
                else:
                    i += 1
            continue
        # optional raw-string prefix
        raw = False
        if c == "r" and i + 1 < n and src[i + 1] in "'\"":
            raw = True; i += 1; c = src[i]
        # string literal (single/double, optionally triple-quoted)
        if c == "'" or c == '"':
            quote = c
            start_line = line
            triple = src[i:i + 3] == quote * 3
            i += 3 if triple else 1
            buf = []
            while i < n:
                d = src[i]
                if d == "\n":
                    line += 1
                    if not triple:            # unterminated single-line string
                        break
                    buf.append(d); i += 1; continue
                if not raw and d == "\\":      # escape — skip the escaped char
                    if i + 1 < n and src[i + 1] == "\n":
                        line += 1
                    i += 2; continue
                if not raw and d == "$" and i + 1 < n and src[i + 1] == "{":
                    # ${…} interpolation is CODE — recurse so a nested display
                    # literal is caught, but bare identifiers stay code.
                    i += 2; bdepth = 1; interior = []; interp_line = line
                    while i < n and bdepth > 0:
                        e = src[i]
                        if e == "{":
                            bdepth += 1
                        elif e == "}":
                            bdepth -= 1
                            if bdepth == 0:
                                i += 1; break
                        if e == "\n": line += 1
                        interior.append(e); i += 1
                    hits.extend(scan("".join(interior), interp_line))
                    continue
                if triple and src[i:i + 3] == quote * 3:
                    i += 3; break
                if not triple and d == quote:
                    i += 1; break
                buf.append(d); i += 1
            text = "".join(buf)
            if any(is_display_char(ch) for ch in text):
                snip = text.strip().replace("\n", " ")
                if len(snip) > 40:
                    snip = snip[:40] + "…"
                hits.append((start_line, snip))
            continue
        if c == "\n":
            line += 1
        i += 1
    return hits

for path in sys.argv[1:]:
    try:
        with open(path, encoding="utf-8") as f:
            src = f.read()
    except OSError:
        continue
    if "l10n-ignore-file" in src:   # whole-file exemption (mock/placeholder)
        continue
    file_lines = src.split("\n")
    for ln, snip in scan(src):
        # inline escape hatch: `l10n-ignore` on the hit's line or the one above.
        here = file_lines[ln - 1] if 0 <= ln - 1 < len(file_lines) else ""
        prev = file_lines[ln - 2] if 0 <= ln - 2 < len(file_lines) else ""
        if "l10n-ignore" in here or "l10n-ignore" in prev:
            continue
        print(f'{path}:{ln} → "{snip}" '
              f"(hardcoded user-facing string — route through AppLocalizations/ARB, "
              f"or mark the line `// l10n-ignore: <reason>` if it is not display text)")
PY
)
  if [ -n "$str_violations" ]; then
    while IFS= read -r v; do
      [ -z "$v" ] && continue
      report "$v"
    done <<< "$str_violations"
  fi
fi

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "Localization violations found — see CLAUDE.md → Conventions → Localization."
  exit 1
fi

echo "l10n OK — ARB locales in parity; no hardcoded UI strings."
