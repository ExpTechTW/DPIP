#!/usr/bin/env bash
# Reformats in place. `tool/dev/analyze.sh` is the one that only reports.
#
#     tool/dev/format.sh
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

pinned dart format lib test tool
