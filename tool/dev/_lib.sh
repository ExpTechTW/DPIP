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
