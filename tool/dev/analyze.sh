#!/usr/bin/env bash
# The two checks that gate every commit: formatting, then the analyzer.
#
#     tool/dev/analyze.sh
#
# Formatting first and with `--set-exit-if-changed`, because it is the one that
# fails on files you did not touch — finding that out after a clean analyze
# means running the analyzer twice.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

step 'dart format --set-exit-if-changed'
pinned dart format --set-exit-if-changed lib test tool

step 'flutter analyze'
pinned flutter analyze
