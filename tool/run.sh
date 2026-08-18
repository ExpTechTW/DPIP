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
# The toolchain comes from `pinned` in tool/dev/_lib.sh, which is the only
# place in the repo that names it. A shell's PATH is resolved once and goes
# stale — `mise activate` caches it, so a toolchain bump leaves the old version
# on PATH until the session is replaced. See AGENTS.md → Toolchain.
#
# `pipefail` is the part a wrapper like this usually gets wrong: without it the
# pipeline reports the *colouriser's* status, so a build that failed would exit
# 0 and the wrapper would hide the thing it wraps.
source "$(dirname "${BASH_SOURCE[0]}")/dev/_lib.sh"
here="$(repo_root)"
cd "$here"

# Nothing starts until mise owns the toolchain, and until every script in tool/
# still parses and still goes through it. Both are cheap (0.02 s and 0.11 s) and
# both fail in the same silent way if left unchecked: the app builds, runs, and
# behaves — off the wrong SDK, or through a script somebody edited into calling
# a bare `flutter`. The launch is the one moment everybody passes through, so it
# is where the check belongs.
require_mise
"$here/tool/check/tooling.sh" >/dev/null || {
  "$here/tool/check/tooling.sh"
  exit 1
}

# A fresh clone that goes straight to running the app still gets the git hooks.
#
# Setup used to be a step you were told about in the README and therefore a step
# people skipped, and skipping it is silent: build_info.g.dart keeps whatever
# commit it was committed with, so the Debug-info page names a build that is not
# the one running. Checked rather than run every time — `git config` on every
# launch would be a write nobody asked for.
if [[ "$(git config --get core.hooksPath || true)" != '.githooks' ]]; then
  "$here/tool/dev/setup.sh"
fi

# Deletes the kernel snapshots earlier runs left inside the simulator.
#
# Every `flutter run` builds its DevFS root inside the app's own sandbox as
# `tmp/DPIP<6 random>/DPIP/`, and three separate things stop it being cleaned
# up. The VM hands the tool back the *inner* path, so even a clean `q` orphans
# the outer directory. `cleanupAfterSignal()` never calls `_cleanupDevFS()`, so
# Ctrl-C orphans the ~190 MB of dills inside it. And SIGHUP is not handled at
# all, so closing the terminal window orphans everything. Nothing in the tool
# or in Xcode ever sweeps them: this checkout had 116 directories and 6.84 GB
# of them, the oldest 37 days old, before anyone looked.
#
# `DPIP` is the checkout folder's name, not the bundle id — the DevFS is named
# `basename(projectRootPath)`. Rename the directory and this stops matching,
# which is a sweep that quietly does nothing rather than one that deletes the
# wrong thing.
#
# From the launcher and not from inside the app, because only the launcher can
# be sure no DevFS is live. `main()` re-runs on every hot restart, by which
# point this run's directory exists and the process has it mapped.
sweep_leaked_devfs() {
  local devices="$HOME/Library/Developer/CoreSimulator/Devices"
  [[ -d $devices ]] || return 0

  # A run in another terminal owns a DevFS right now. Skipping costs a sweep
  # later; not skipping costs them a hot restart — and worse, silently reverts
  # any asset or shader edit, because the tool decides what to resend from
  # *host* state and never learns the device copy went away.
  #
  # A process check and deliberately not a timestamp: the outer directory's
  # mtime is frozen at its birth while the dills inside it keep being
  # rewritten, so any "older than" rule deletes the live one.
  pgrep -qf 'flutter_tools\.snapshot run' && return 0
  pgrep -qf '/Runner\.app/Runner' && return 0

  # Every component up to the leaf is literal, and the leaf is `DPIP` plus
  # exactly six characters directly under a container's own `tmp/` — there is
  # no path this can reach outside a simulator's app data. `nullglob` is what
  # keeps "nothing leaked" from handing the pattern itself to `rm`.
  local -a leaked=()
  shopt -s nullglob
  leaked=("$devices"/*/data/Containers/Data/Application/*/tmp/DPIP??????)
  shopt -u nullglob
  ((${#leaked[@]})) || return 0

  local freed
  freed="$(du -x -s -k "${leaked[@]}" | awk '{s+=$1} END {printf "%.1f", s/1048576}')"
  rm -rf -- "${leaked[@]}"
  # stderr, so it survives the pipe into the colouriser as its own line.
  printf 'run.sh: swept %d leaked DevFS dirs (%s GB)\n' "${#leaked[@]}" "$freed" >&2
}

sweep_leaked_devfs

# Worth passing `-d`: piped, the tool cannot draw its interactive device picker
# (target_devices.dart gates that on the logger's colour), so an ambiguous
# device list falls back to a plain prompt.
# `DPIP_RUN_SH` is how the app knows it was started properly. A launch that
# skips this script gets the wrong toolchain and an uncoloured log, and neither
# announces itself — so bootstrap says so instead, in debug only.
pinned flutter run --dart-define=DPIP_RUN_SH=true "$@" \
  | "$here/tool/internal/colorize_logs.sh"
