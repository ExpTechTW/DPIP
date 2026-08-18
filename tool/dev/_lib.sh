# Shared by every script in tool/. Not runnable on its own.
#
# The one thing every script here has in common: it runs the toolchain through
# `mise exec --`, and nobody typing a command has to remember to. A shell's PATH
# is resolved once and `mise activate` caches it, so a toolchain bump leaves the
# old SDK on PATH until the session is replaced — and a build against the wrong
# SDK announces nothing. See AGENTS.md → Toolchain.
set -euo pipefail

# The repo root, whatever directory the script was invoked from.
repo_root() { cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd; }

# `flutter`/`dart`/anything else, on the pinned toolchain.
#
# `mise exec` re-reads mise.toml every time, which is the whole point: this is
# the only place in the repo that names the toolchain, so there is one line to
# get wrong instead of one per script.
pinned() { mise exec -- "$@"; }

# A step banner, so a script that runs four commands says which one failed.
step() { printf '\n\033[1m▸ %s\033[0m\n' "$*" >&2; }

# ── Content-hash cache ──────────────────────────────────────────────────────
#
# Frequent commits re-run the same analyze and the same 1400 tests over an
# unchanged tree. The answer only depends on the files the check reads, so it
# is keyed on their contents: change one byte anywhere in the input set and the
# key changes and the check runs; change nothing and the previous answer stands.
#
# Deliberately content, not mtime. A `dart format` pass, a branch switch, or a
# checkout all bump mtimes without changing what the code says, and a cache
# that re-runs the whole suite after `git switch` is a cache nobody trusts.
#
# Only successes are stored. Repeating a failure is cheap; hiding one is not.

# Where stamps live: inside .git, so nothing has to gitignore it, `flutter
# clean` cannot reach it, and it is per-clone.
cache_dir() { printf '%s/dpip-checks' "$(git rev-parse --git-dir)"; }

# A hash of every tracked and every untracked-but-not-ignored file under the
# given paths — contents *and* names, so a rename or a deletion also invalidates.
# Measured at 0.09 s over 793 files.
cache_key() {
  local files
  files="$(git ls-files -co --exclude-standard -- "$@" | LC_ALL=C sort)"
  [[ -z $files ]] && { printf 'empty'; return; }
  printf '%s' "$files" | tr '\n' '\0' | xargs -0 shasum -a 256 |
    shasum -a 256 | cut -d' ' -f1
}

# cached <name> <key> <command...>
#
# `DPIP_NO_CACHE=1` forces a run — for when you suspect the cache itself, which
# is the one thing a cache can never tell you.
cached() {
  local name="$1" key="$2"
  shift 2
  local dir stamp
  dir="$(cache_dir)"
  stamp="$dir/$name-$key"

  if [[ -z ${DPIP_NO_CACHE:-} && -f $stamp ]]; then
    printf '  cached — unchanged since %s\n' "$(cat "$stamp")" >&2
    return 0
  fi

  "$@" || return $?

  mkdir -p "$dir"
  date '+%Y-%m-%d %H:%M' >"$stamp"

  # Keep the last few keys per check, not just the newest. Editing a file and
  # reverting it — a rebase, a stash pop, `git checkout -- .`, or simply trying
  # something and undoing it — lands back on a state that was already proven,
  # and with one stamp per check that costs a full re-run every time.
  # Stamps are empty-ish files, so the ceiling is arbitrary and generous.
  local -a old_stamps=()
  while IFS= read -r f; do old_stamps+=("$f"); done < <(
    ls -t "$dir/$name-"* 2>/dev/null | tail -n +9
  )
  ((${#old_stamps[@]} > 0)) && rm -f "${old_stamps[@]}"
  return 0
}
