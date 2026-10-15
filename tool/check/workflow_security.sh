#!/usr/bin/env bash
# What a workflow lets somebody else do, not merely whether it parses.
#
#     tool/check/workflow_security.sh
#
# zizmor, at the release tool/internal/pinned_tool.sh pins and verifies, over
# everything under .github/ — the workflows and dependabot.yml. It is what keeps
# them the way they are now: every action pinned to a commit, no job token left
# on disk where nothing pushes, no job holding more permission than it uses, no
# value pasted into a script, and no secret-holding trigger that runs a pull
# request's code. Each of those is a one-line regression nobody would notice in
# review, and the workflows hold the store signing keys.
#
# Every finding at zizmor's default persona and severity fails. A finding that
# is accepted on purpose is marked on its own line — `# zizmor: ignore[<audit>]`
# with the reason beside it — so the exception is read by whoever edits that
# line, rather than kept in a config file nobody opens. To list them:
#
#     grep -rn 'zizmor: ignore' .github
#
# `--offline`, here and in CI alike: the audits that ask GitHub (whether a
# pinned commit really belongs to the action's repository, which releases are
# known to be vulnerable) need a token and can answer differently tomorrow
# about a file that has not changed. A gate has to give one answer per file.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

zizmor="$(tool/internal/pinned_tool.sh zizmor)"

# `--strict-collection` makes a file zizmor cannot parse a failure; by default
# it is a warning, and the file is simply not audited.
if ! "$zizmor" --offline --strict-collection --quiet .github; then
  cat >&2 <<'EOF'

Each finding above names its audit, with a link to what it means and how to
fix it. Fix it; or, when it is accepted on purpose, mark the flagged line
`# zizmor: ignore[<audit>]` and say why beside it.
EOF
  exit 1
fi

echo "workflow security OK — zizmor found nothing."
