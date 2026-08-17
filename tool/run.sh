#!/usr/bin/env bash
# `flutter run`, on the pinned toolchain, with the log coloured.
#
#     tool/run.sh -d "iPhone 17 Pro"
#
# Every argument is passed through untouched.
#
# **Hot reload still works.** The tool decides those two things from different
# places — `supportsColor` reads *stdout*, `singleCharMode` reads *stdin* — and
# a pipe only touches the first. `r`, `R` and `q` go to stdin, which is still
# the terminal. What is lost is flutter's own colour and its progress spinner,
# which are redraw sequences that a pipe turns into litter anyway.
#
# `mise exec --` and not a bare `flutter`, because a shell's PATH is resolved
# once and goes stale: `mise activate` caches it, so a toolchain bump leaves
# the old version on PATH until the session is replaced. `mise exec` re-reads
# mise.toml every time. See AGENTS.md → Toolchain.
#
# `pipefail` is the part a wrapper like this usually gets wrong: without it the
# pipeline reports the *colouriser's* status, so a build that failed would exit
# 0 and the wrapper would hide the thing it wraps.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Worth passing `-d`: piped, the tool cannot draw its interactive device picker
# (target_devices.dart gates that on the logger's colour), so an ambiguous
# device list falls back to a plain prompt.
# `DPIP_RUN_SH` is how the app knows it was started properly. A launch that
# skips this script gets the wrong toolchain and an uncoloured log, and neither
# announces itself — so bootstrap says so instead, in debug only.
mise exec -- flutter run --dart-define=DPIP_RUN_SH=1 "$@" \
  | "$here/colorize_logs.sh"
