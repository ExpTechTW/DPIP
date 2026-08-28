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

# Every script in tool/, checked as a script.
#
# `tool/run.sh` runs this at launch, so these are the things worth catching
# before anything else happens: a script that does not parse, one that is not
# executable, and — the one that matters — one that reaches the toolchain
# without going through the pin.
while IFS= read -r script; do
  bash -n "$script" 2>/dev/null || report "$script: does not parse"

  case "${OSTYPE:-}" in
    msys*|cygwin*)
      # Windows filesystems do not expose Unix executable bits reliably.
      # Git's index is authoritative for the mode that macOS, Linux, and CI
      # receive after checkout.
      mode="$(git ls-files --stage -- "$script" | awk 'NR == 1 { print $1 }')"
      [[ $mode == 100755 ]] ||
        report "$script: is not executable in git (git update-index --chmod=+x)"
      ;;
    *)
      [[ -x $script ]] ||
        report "$script: is not executable (chmod +x)"
      ;;
  esac

  head -1 "$script" | grep -q '^#!/usr/bin/env bash$' ||
    [[ $script == tool/dev/_lib.sh ]] ||
    report "$script: no \`#!/usr/bin/env bash\` shebang"

  # The helper is where `mise exec` is supposed to be, and this file has to
  # spell the string out to look for it. Both are exempt by name rather than by
  # a pattern, so a third exemption has to be argued for.
  if [[ $script != tool/dev/_lib.sh && $script != tool/check/tooling.sh ]]; then
    grep -qE '(^|[^[:alnum:]_/-])mise[[:space:]]+exec' "$script" &&
      report "$script: calls \`mise exec\` directly — use \`pinned\` from tool/dev/_lib.sh"
  fi

  # A bare `flutter` / `dart` as a command. This is the forbidden one: it runs
  # whatever SDK the shell cached, it works, and nothing in its output ever says
  # which SDK produced it. Matched only at the start of a command — after a
  # newline, a pipe, `&&`, `;` or `$(` — so prose in a comment is untouched.
  if grep -nE '(^|[|;&]|\$\()[[:space:]]*(flutter|dart)[[:space:]]+[a-z]' "$script" |
     grep -v '^[0-9]*:[[:space:]]*#' | grep -q .; then
    report "$script: runs a bare flutter/dart — every toolchain call goes through \`pinned\`"
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
