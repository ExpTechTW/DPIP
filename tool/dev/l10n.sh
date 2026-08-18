#!/usr/bin/env bash
# Regenerates lib/l10n/gen/ from the ARB files.
#
#     tool/dev/l10n.sh
#
# `generate: true` in pubspec means a build does this anyway; running it by hand
# is for when you have just edited an ARB and want the getter to exist before
# the analyzer sees the call site.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

pinned flutter gen-l10n
