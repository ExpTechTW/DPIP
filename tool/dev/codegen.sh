#!/usr/bin/env bash
# Regenerates the build_runner outputs (`*.g.dart`, `*.freezed.dart`).
#
#     tool/dev/codegen.sh
#
# `--delete-conflicting-outputs` always: without it a renamed source leaves its
# old generated file behind, and the build fails on a conflict that describes a
# file nobody is looking at.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

pinned dart run build_runner build --delete-conflicting-outputs
