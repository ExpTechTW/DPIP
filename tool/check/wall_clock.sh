#!/usr/bin/env bash
# Every read of the device clock in lib/ says why the device clock is right.
#
#     tool/check/wall_clock.sh
#
# The device clock is wrong by an unknown amount — set by hand, drifted, or a
# timezone away — and the app measures every server and radio timestamp
# against the SNTP-calibrated `AppTime` instead (ARCHITECTURE.md → Calibrated
# time). A `DateTime.now()` beside one of those timestamps compiles, runs and
# passes its tests on a phone whose clock is right; on one that is not,
# subtracting the two gives the offset between the clocks, not an age. That is
# how a retention window deletes data that is not old, and how an alert's
# countdown is off by however far the phone has drifted. Nothing fails, so
# nothing would ever say so.
#
# Plenty of reads are right, though: a store that both writes and compares its
# own stamps, an OS stamp aged against the clock that made it, the clock being
# calibrated itself. So this does not forbid the call. It requires each one to
# carry its justification, on the same line or in the comment directly above
# (annotations in between are fine):
#
#     // wall-clock: LRU sequence key, only ever compared with other rows'
#     final now = DateTime.now().millisecondsSinceEpoch;
#
# A reason, not a bare marker — `// wall-clock:` alone does not count. The
# point is that whoever writes the call has to decide which clock it is
# against, and whoever reviews it can check the answer.
#
# `DateTime.timestamp()` is the same read and is held to the same rule.
# Comments are not code, so a `DateTime.now()` mentioned in one is ignored.
# Generated files are skipped.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

# python3 owns the scan, as in check/l10n.sh: telling a call from a comment
# needs to know whether a `//` sits inside a string, which a grep cannot.
# Captured, then reported, so the ✗ style matches the other gates.
violations="$(python3 - <<'PY'
import os
import re

CALL = re.compile(r"\bDateTime\s*\.\s*(now|timestamp)\b")
MARK = re.compile(r"//.*\bwall-clock:\s*\S")
COMMENT_LINE = re.compile(r"^\s*//")
ANNOTATION_LINE = re.compile(r"^\s*@\w")


def code_part(line, in_block):
    """The line with comments removed, and whether a /* */ is still open.

    Strings are tracked only to know that a `//` or `/*` inside one does not
    start a comment; their contents stay, so a call interpolated into a string
    is still a call. Escapes and raw strings are close enough for this: a
    false start can only hide text after it on the same line, and only inside a
    literal that already contains a quote character.
    """
    out = []
    i, n = 0, len(line)
    quote = None
    while i < n:
        c = line[i]
        if in_block:
            if line.startswith("*/", i):
                in_block = False
                i += 2
            else:
                i += 1
            continue
        if quote:
            out.append(c)
            if c == "\\":
                if i + 1 < n:
                    out.append(line[i + 1])
                i += 2
                continue
            if line.startswith(quote, i):
                out.append(line[i + 1 : i + len(quote)])
                i += len(quote)
                quote = None
                continue
            i += 1
            continue
        if line.startswith("//", i):
            break
        if line.startswith("/*", i):
            in_block = True
            i += 2
            continue
        for q in ("'''", '"""', "'", '"'):
            if line.startswith(q, i):
                quote = q
                out.append(q)
                i += len(q)
                break
        else:
            out.append(c)
            i += 1
    return "".join(out), in_block


def justified(lines, index):
    if MARK.search(lines[index]):
        return True
    # Up through the comment above, stepping over annotations: a comment sits
    # above `@override`, not between it and the declaration.
    j = index - 1
    while j >= 0 and (COMMENT_LINE.match(lines[j]) or ANNOTATION_LINE.match(lines[j])):
        if MARK.search(lines[j]):
            return True
        j -= 1
    return False


for root, dirs, files in os.walk("lib"):
    dirs.sort()
    for name in sorted(files):
        path = os.path.join(root, name)
        if not name.endswith(".dart") or name.endswith((".g.dart", ".freezed.dart")):
            continue
        if path.startswith(os.path.join("lib", "l10n", "gen") + os.sep):
            continue
        with open(path, encoding="utf-8") as f:
            lines = f.read().split("\n")
        in_block = False
        for index, line in enumerate(lines):
            code, in_block = code_part(line, in_block)
            if CALL.search(code) and not justified(lines, index):
                print(f"{path}:{index + 1}: {line.strip()}")
PY
)"

if [[ -n $violations ]]; then
  while IFS= read -r v; do
    printf '  \033[31m✗\033[0m %s\n' "$v" >&2
  done <<<"$violations"
  cat >&2 <<'EOF'

Each of these reads the device clock without saying why that is the right
clock. If the value is compared with anything a server or a radio stamped,
use AppTime instead — see ARCHITECTURE.md → Calibrated time. If the device
clock really is the right one, say why, on the line or in the comment above:

    // wall-clock: <why device time is correct here>
EOF
  exit 1
fi

echo "wall clock OK — every DateTime.now() in lib/ says why."
