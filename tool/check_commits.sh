#!/usr/bin/env bash
# Rejects a commit message that the release notes cannot be built from.
#
# This is a gate rather than a linter because the message *is* the changelog:
# `tool/release_notes.sh` reads these bodies and publishes them, so a commit
# that does not carry both languages leaves a hole in a note that users read.
# There is no second place to fix it — the message is immutable once pushed,
# and the only repair is a rebase. Catching it at the gate is what keeps that
# repair small.
#
# Usage:  tool/check_commits.sh [<range>]
#         tool/check_commits.sh origin/main..HEAD
#
# With no range it checks HEAD alone, which is what a commit-msg hook wants.
set -uo pipefail

range="${1:-HEAD~1..HEAD}"

# Types that end up in front of a user, and therefore must be bilingual. The
# rest (chore, ci, docs, style, test, build) may be one line: nobody reads a
# release note to find out that the lockfile moved.
readonly USER_FACING='feat|fix|perf'
readonly ALL_TYPES='feat|fix|perf|refactor|docs|test|chore|build|ci|style|revert'

# The line that separates the two languages. Deliberately unmistakable — a
# bare `---` shows up in prose and in diffs pasted into a message — and
# deliberately not starting with a dash, which every tool that takes options
# would mistake for one.
readonly MARKER='=== 中文 ==='

readonly SUMMARY_MAX=72

fail=0
note() {
  printf '  %s\n' "$1" >&2
}

commits="$(git rev-list --no-merges "$range" 2>/dev/null || true)"
if [ -z "$commits" ]; then
  echo "commit gate: no commits in $range"
  exit 0
fi

for sha in $commits; do
  subject="$(git log -1 --format=%s "$sha")"
  body="$(git log -1 --format=%b "$sha")"
  short="$(git log -1 --format=%h "$sha")"
  bad=0

  # 1. The summary line.
  if ! printf '%s' "$subject" | grep -Eq "^($ALL_TYPES)(\([a-z0-9._-]+\))?: .+"; then
    note "summary must be '<type>(<scope>): <summary>' with type one of: ${ALL_TYPES//|/, }"
    bad=1
  fi
  if [ "${#subject}" -gt "$SUMMARY_MAX" ]; then
    note "summary is ${#subject} characters; the limit is $SUMMARY_MAX"
    bad=1
  fi
  case "$subject" in
  *.) note "summary must not end with a period"; bad=1 ;;
  esac
  # The summary is English so a release note reads in one voice. Testing for
  # ASCII rather than for CJK ranges: it is one portable expression instead of
  # a `grep -P` that BSD grep does not have (and would silently pass on a Mac),
  # and it catches kana, Hangul and emoji in the same breath.
  if printf '%s' "$subject" | LC_ALL=C grep -q '[^ -~]'; then
    note "summary must be plain-ASCII English — 中文 belongs under '$MARKER'"
    bad=1
  fi

  # 2. Nothing that credits a tool. A commit is authored by a person; an agent
  #    that adds itself to the record makes the history lie about who is
  #    accountable for the change.
  if printf '%s' "$body" | grep -Eqi '^(Co-Authored-By|Signed-off-by: .*(claude|copilot|cursor|gpt))'; then
    note "no Co-Authored-By trailer"
    bad=1
  fi
  if printf '%s' "$body" | grep -Eqi 'generated with|🤖|co-?authored|claude\.com|openai\.com'; then
    note "no tool attribution in the message"
    bad=1
  fi

  # 3. A user-facing change carries both languages, because both are published.
  if printf '%s' "$subject" | grep -Eq "^($USER_FACING)(\(|:)"; then
    if [ -z "$(printf '%s' "$body" | tr -d '[:space:]')" ]; then
      note "a $USER_FACING commit needs a body — it is the release note"
      bad=1
    elif ! printf '%s\n' "$body" | grep -Fxq -- "$MARKER"; then
      note "body needs a '$MARKER' line separating English from 中文"
      bad=1
    else
      english="$(printf '%s\n' "$body" | sed -n "1,/^$(printf '%s' "$MARKER" | sed 's/[]\/$*.^[]/\\&/g')\$/p" | sed '$d')"
      chinese="$(printf '%s\n' "$body" | sed -n "/^$(printf '%s' "$MARKER" | sed 's/[]\/$*.^[]/\\&/g')\$/,\$p" | sed '1d')"
      if [ -z "$(printf '%s' "$english" | tr -d '[:space:]')" ]; then
        note "the English half is empty"
        bad=1
      fi
      if [ -z "$(printf '%s' "$chinese" | tr -d '[:space:]')" ]; then
        note "the 中文 half is empty"
        bad=1
      fi
    fi
  fi

  # 4. `Platform:` is optional, but a typo in it silently drops the tag from
  #    the release note rather than failing anywhere.
  platform="$(printf '%s\n' "$body" | sed -n 's/^[Pp]latform: *//p' | head -n 1)"
  if [ -n "$platform" ]; then
    case "$(printf '%s' "$platform" | tr '[:upper:]' '[:lower:]')" in
    android | ios) ;;
    *)
      note "Platform: must be 'android' or 'ios' (omit it when a change affects both) — got '$platform'"
      bad=1
      ;;
    esac
  fi

  if [ "$bad" -ne 0 ]; then
    printf '\n✗ %s  %s\n' "$short" "$subject" >&2
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  cat >&2 <<'EOF'

A commit message cannot be edited after the fact, so this has to be fixed by
rewriting the commits and force-pushing the branch:

    git rebase -i <base>          # mark the offenders as `reword`
    git push --force-with-lease

`--force-with-lease` rather than `--force`: it refuses if someone else has
pushed in the meantime, which is the case where a plain force-push silently
destroys their work.

The format is in commit.md.
EOF
  exit 1
fi

echo "commit gate: $(printf '%s\n' "$commits" | wc -l | tr -d ' ') commit(s) OK"
