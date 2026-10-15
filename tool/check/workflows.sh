#!/usr/bin/env bash
# The workflows themselves, because a broken one does not fail — it is refused.
#
#     tool/check/workflows.sh
#
# GitHub interpolates a `run` block whole before bash sees it, so an expression
# error anywhere in it, comment included, kills the run before a job exists:
# no failing step, and the file path where the name should be. Nothing else in
# this repository could have caught that, and it took CI down on main for a
# day.
#
# actionlint, at the release tool/internal/pinned_tool.sh pins and verifies.
# Its shellcheck and pyflakes passes are off, as they have always been in CI:
# actionlint runs them only when it finds them on PATH, so leaving them on would
# make the answer depend on what the machine running it happens to have.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

actionlint="$(tool/internal/pinned_tool.sh actionlint)"
"$actionlint" -shellcheck= -pyflakes= .github/workflows/*.yml

echo "workflows OK — actionlint found nothing."
