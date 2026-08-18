#!/usr/bin/env bash
# Nobody is ever told to type `mise exec`, or a bare `flutter`.
#
#     tool/check/tooling.sh
#
# Every workflow in this repo has a script in tool/, and the scripts are the
# only place the toolchain is named. That is not tidiness: a shell's PATH is
# resolved once and `mise activate` caches it, so a copied-and-pasted `flutter
# test` runs whatever SDK the session happened to start with, and a run against
# the wrong SDK announces nothing. One place to name it is one place to get it
# wrong.
#
# What this checks, and deliberately not more: a *command* in a fenced code
# block, or a CI `run:` step. Prose may say "the scripts run everything through
# `mise exec`" — the documentation has to be able to explain the rule it is
# enforcing, and a rule that cannot be described is one nobody follows.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

fail=0
report() {
  printf '  \033[31m✗\033[0m %s\n' "$*" >&2
  fail=1
}

# Docs: only lines inside a ``` fence count.
#
# `awk` rather than grep, because the whole point is that the same string is
# fine one line earlier. State is a single toggle: fences here are never nested.
for doc in ./*.md .github/*.md; do
  [[ -f $doc ]] || continue
  while IFS= read -r hit; do
    report "$doc:$hit"
  done < <(
    awk '
      # A `/` inside a bracket expression still closes an awk regex literal, so
      # every pattern here is a string compared with `~`.
      /^[[:space:]]*```/ { fenced = !fenced; next }
      !fenced { next }
      $0 ~ "(^|[^[:alnum:]_/-])mise[[:space:]]+exec" {
        print NR ": tells the reader to type `mise exec` — point at a tool/ script instead"
      }
      $0 ~ "(^|[^[:alnum:]_/.-])flutter[[:space:]]+(run|test|analyze|build|pub|clean|gen-l10n)" {
        print NR ": tells the reader to type a bare `flutter` command — point at a tool/ script instead"
      }
      $0 ~ "(^|[^[:alnum:]_/.-])dart[[:space:]]+(format|run|test)" {
        print NR ": tells the reader to type a bare `dart` command — point at a tool/ script instead"
      }
    ' "$doc"
  )
done

# CI: a workflow that names the toolchain itself is a second source of truth,
# and the copy that drifts is always the one nobody runs locally.
for wf in .github/workflows/*.yml; do
  [[ -f $wf ]] || continue
  while IFS= read -r hit; do
    report "$wf:$hit"
  done < <(
    awk '
      /^[[:space:]]*#/ { next }
      $0 ~ "(^|[^[:alnum:]_/-])mise[[:space:]]+exec" {
        print NR ": CI runs the toolchain directly — call the tool/ script a developer calls"
      }
    ' "$wf"
  )
done

# The scripts themselves are where `mise exec` belongs, so they are exempt —
# but only through the one helper, or the exemption is just a bigger hole.
while IFS= read -r script; do
  # The helper is where `mise exec` is supposed to be, and this file has to
  # spell the string out to look for it. Both are exempt by name rather than by
  # a pattern, so a third exemption has to be argued for.
  [[ $script == tool/dev/_lib.sh || $script == tool/check/tooling.sh ]] && continue
  if grep -qE '(^|[^[:alnum:]_/-])mise[[:space:]]+exec' "$script"; then
    report "$script: calls \`mise exec\` directly — use \`pinned\` from tool/dev/_lib.sh"
  fi
done < <(find tool -name '*.sh' -type f | sort)

if ((fail)); then
  cat >&2 <<'EOF'

Every workflow has a script. The full list is in AGENTS.md → Running; the short
version:

  tool/run.sh              start the app
  tool/dev/test.sh         the test suite
  tool/dev/analyze.sh      format + analyzer
  tool/dev/deps.sh         dependencies
  tool/check.sh            every gate CI runs

If a workflow genuinely has no script yet, add one under tool/ rather than
documenting the raw command.
EOF
  exit 1
fi

echo "tooling OK — no bare toolchain command in the docs or CI."
