#!/usr/bin/env bash
# Throws away the build output and resolves dependencies again.
#
#     tool/dev/clean.sh
#
# The two always go together. `flutter clean` deletes .dart_tool/, which is
# where the package resolution lives — so a bare clean leaves the checkout in a
# state where nothing builds and the error names a missing package rather than
# the clean that removed it.
#
# This is not a routine step. It costs a full rebuild, and the reasons to reach
# for it are narrow: a plugin's native side changed, or the generated code and
# the sources have disagreed in a way nothing else explains.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

step 'flutter clean'
pinned flutter clean

step 'flutter pub get'
pinned flutter pub get
