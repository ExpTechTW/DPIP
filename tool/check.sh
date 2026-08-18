#!/usr/bin/env bash
# Every gate CI runs, in one command.
#
#     tool/check.sh
#
# The point is that a green run here means a green CI. The list below is the
# authority for that claim — when a gate is added to .github/workflows/ci.yml it
# has to be added here too, or this script starts lying and the next person
# finds out from a red PR.
#
# Format and analyze come first because they fail on files you did not touch,
# and the shell gates are cheap next to the test suite.
source "$(dirname "${BASH_SOURCE[0]}")/dev/_lib.sh"
cd "$(repo_root)"

step 'format + analyze'
tool/dev/analyze.sh

for gate in tooling l10n layering storage pubspec_lock notification_sounds build_info; do
  step "check/$gate"
  "tool/check/$gate.sh"
done

step 'commits'
tool/check/commits.sh

step 'test'
tool/dev/test.sh
