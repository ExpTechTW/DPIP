#!/usr/bin/env bash
# Applies tool/patches/*.patch to the pinned Flutter SDK.
#
# Called from `require_mise` in tool/dev/_lib.sh, so every script that reaches
# the toolchain has already run it. Nobody runs this by hand.
#
# Patching the SDK is the thing this repo is otherwise most careful *not* to
# do — AGENTS.md → Toolchain exists because a build off the wrong SDK announces
# nothing. A patched SDK is a wrong SDK by that definition, so the same rule
# applies to the patch: it lives in the repo, it is applied by a script every
# entry point calls, and it is never left to a machine to have remembered. The
# alternative is one laptop where the bug is fixed and a CI runner where it is
# not, which is exactly the failure the pin was bought to prevent.
#
# Each patch is one of three states, and only one of them is silent:
#
#   applies cleanly    → apply it, and say so
#   already applied    → nothing to do, say nothing
#   neither            → stop. The SDK moved out from under the patch, which
#                        usually means a Flutter bump. Somebody has to decide
#                        whether upstream fixed it; a skipped patch would let
#                        the bug back in without a word.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
patch_dir="$root/tool/patches"

[[ -d $patch_dir ]] || exit 0
shopt -s nullglob
patches=("$patch_dir"/*.patch)
((${#patches[@]})) || exit 0

# `mise where`, not the resolved binary's parent: this wants the SDK root that
# `packages/flutter/...` hangs off, and require_mise has already established
# that mise owns it.
sdk="$(cd "$root" && mise where flutter 2>/dev/null || true)"
if [[ -z $sdk || ! -d $sdk ]]; then
  printf '\n  Cannot locate the pinned Flutter SDK to patch it.\n' >&2
  printf '  Run `mise install` from %s.\n\n' "$root" >&2
  exit 1
fi

for p in "${patches[@]}"; do
  name="$(basename "$p")"

  # --forward alone is not enough to tell "applies" from "already applied":
  # both refuse, with different messages. A reverse dry-run answers it
  # directly — a patch that can be undone is a patch that is already in.
  if patch -p1 -d "$sdk" --forward --dry-run --silent <"$p" >/dev/null 2>&1; then
    patch -p1 -d "$sdk" --forward --silent <"$p"
    printf '  \033[33m●\033[0m patched SDK: %s\n' "$name" >&2
  elif patch -p1 -d "$sdk" --reverse --dry-run --silent <"$p" >/dev/null 2>&1; then
    : # already applied
  else
    cat >&2 <<PATCHFAIL

  tool/patches/$name no longer applies to the pinned SDK.

      SDK: $sdk

  The patch is pinned to one Flutter version and the pin has moved. Read the
  header of the patch — it names the upstream issue. If that issue is fixed in
  this version, delete the patch; its regression test stays and should pass on
  its own. If it is not fixed, re-cut the patch against the new source.

PATCHFAIL
    exit 1
  fi
done
