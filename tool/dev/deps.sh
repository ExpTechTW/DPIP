#!/usr/bin/env bash
# Resolves dependencies.
#
#     tool/dev/deps.sh              # normal
#     tool/dev/deps.sh --offline    # from the local pub cache only
#
# The offline form is worth knowing: pub.dev being slow or unreachable stops a
# build that has every package it needs already downloaded.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

pinned flutter pub get "$@"
