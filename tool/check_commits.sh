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
#         tool/check_commits.sh --message <file>   # a literal message
#
# With no range it checks HEAD alone, which is what a commit-msg hook wants.
#
# `--message` exists for the squash-merge case. When a PR is squashed, the
# commit that lands on `main` is built from the **PR title and description**,
# not from the branch's commits — so a branch whose every commit passes this
# gate can still put a malformed message on `main`, and did: `Fix report (#529)`
# is on `main` now, was never a commit anybody wrote, and cannot be repaired.
# CI feeds the PR title and body through this mode, so the message that will
# actually be committed is the one that gets checked.
set -uo pipefail

mode=range
range="${1:-HEAD~1..HEAD}"
if [ "${1:-}" = "--message" ]; then
  mode=message
  msg_file="${2:?--message needs a file}"
fi

# Types that end up in front of a user, and therefore must be bilingual. The
# rest (chore, ci, docs, style, test, build) may be one line: nobody reads a
# release note to find out that the lockfile moved.
readonly USER_FACING='feat|fix|perf'
readonly ALL_TYPES='feat|fix|perf|refactor|docs|test|chore|build|ci|style|revert'

# A changelog entry, in one expression:  Category(locale): text
#
# One line per entry, so the note is extracted rather than parsed out of prose.
# The old scheme split a prose body on a `=== 中文 ===` marker, which a
# squash-merge destroyed by concatenating four bodies into one — and which
# could never carry more than the two languages the marker separated.
readonly LINE_RE='^(New|Optimization|Fix)\(([A-Za-z]{2,3}(-[A-Za-z0-9]+)*)\):[[:space:]]*(.+)$'

# The two every user-facing change must carry: the app's own language, and the
# one everyone else falls back to. The rest are optional and arrive whenever
# somebody writes them.
readonly REQUIRED_LOCALES='zh-Hant en-US'

# Kept in step with lib/l10n/*.arb — a typo'd locale is worse than a missing
# one, because it publishes a language block no reader is ever served.
readonly KNOWN_LOCALES='zh-Hant zh-Hans zh-Hant-HK en-US ja-JP ko-KR th-TH vi-VN id-ID fil-PH'

readonly SUMMARY_MAX=72

fail=0
note() {
  printf '  %s\n' "$1" >&2
}

check_one() { # <subject> <body> <label>
  local subject body short bad
  subject="$1"
  body="$2"
  short="$3"
  bad=0

  # GitHub appends ` (#123)` to the summary when a PR is squash-merged. The
  # author did not write it and cannot prevent it, so counting it against the
  # limit fails a commit that passed this very gate while the PR was open — and
  # fails it on `main`, where the prescribed repair (rebase, force-push) is not
  # available. Judge the summary the author actually wrote.
  subject="$(printf '%s' "$subject" | sed -E 's/ \(#[0-9]+\)$//')"

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
    note "summary must be plain-ASCII English — 中文 belongs in the entry lines"
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

  # 3. Changelog lines. These are what tool/release_notes.sh publishes, so a
  #    mistake here is a hole in something users read, and the message cannot
  #    be edited after it is pushed.
  # Whole-line match: the marker is only a mistake when it is being *used* as
  # a separator. Quoting it inline while explaining why it went away is not.
  if printf '%s\n' "$body" | grep -Fxq -- '=== 中文 ==='; then
    note "'=== 中文 ===' is gone — declare entries as 'New(zh-Hant): ...' lines"
    bad=1
  fi

  entries="$(printf '%s\n' "$body" | grep -E "$LINE_RE" || true)"

  # A line that starts like an entry but does not match is the failure mode
  # worth naming: it is silently not an entry, and the only symptom is a
  # shorter published list. `en_US` for `en-US` is the one that will happen.
  while IFS= read -r cand; do
    [ -n "$cand" ] || continue
    printf '%s' "$cand" | grep -Eq "$LINE_RE" || {
      note "malformed entry: $cand"
      note "  expected  Category(locale): text  e.g. New(en-US): the map …"
      bad=1
    }
  done <<EOF
$(printf '%s\n' "$body" | grep -E '^(New|Optimization|Fix)[ (]' || true)
EOF

  # Every declared locale must be one the app actually ships.
  for loc in $(printf '%s\n' "$entries" | sed -E "s/$LINE_RE/\\2/" | sort -u); do
    [ -n "$loc" ] || continue
    case " $KNOWN_LOCALES " in
    *" $loc "*) ;;
    *)
      note "unknown locale '$loc' — one of: ${KNOWN_LOCALES// /, }"
      bad=1
      ;;
    esac
  done

  # A user-facing type must say what to publish; nothing else has to.
  if printf '%s' "$subject" | grep -Eq "^($USER_FACING)(\(|:)"; then
    if [ -z "$entries" ]; then
      note "a $USER_FACING commit needs at least one 'New|Optimization|Fix(<locale>): ...' line"
      bad=1
    else
      for loc in $REQUIRED_LOCALES; do
        printf '%s\n' "$entries" | grep -Eq "^[A-Za-z]+\($loc\):" || {
          note "missing $loc entries — every published entry needs one"
          bad=1
        }
      done
      # The languages are published as parallel lists, so an entry written in
      # one language and forgotten in another silently ships a shorter list to
      # those readers. Counting per category catches it.
      for cat in New Optimization Fix; do
        base="$(printf '%s\n' "$entries" | grep -Ec "^$cat\(zh-Hant\):" || true)"
        for loc in $(printf '%s\n' "$entries" | sed -E "s/$LINE_RE/\\2/" | sort -u); do
          [ -n "$loc" ] && [ "$loc" != zh-Hant ] || continue
          n="$(printf '%s\n' "$entries" | grep -Ec "^$cat\($loc\):" || true)"
          [ "$n" -eq 0 ] || [ "$n" -eq "$base" ] || {
            note "$cat has $base zh-Hant entries but $n for $loc — they must pair up"
            bad=1
          }
        done
      done
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
}

if [ "$mode" = message ]; then
  check_one "$(head -n 1 "$msg_file")" "$(tail -n +2 "$msg_file")" "PR title"
else
  commits="$(git rev-list --no-merges "$range" 2>/dev/null || true)"
  if [ -z "$commits" ]; then
    echo "commit gate: no commits in $range"
    exit 0
  fi
  for sha in $commits; do
    check_one "$(git log -1 --format=%s "$sha")" \
      "$(git log -1 --format=%b "$sha")" "$(git log -1 --format=%h "$sha")"
  done
fi

if [ "$fail" -ne 0 ]; then
  if [ "$mode" = message ]; then
    # No rebase involved: nothing is committed yet. Editing the PR's title and
    # description on GitHub is the whole fix, and it re-runs this check.
    cat >&2 <<'EOF'

This PR will be squash-merged, so the message above — built from the PR's
**title and description** — is what gets committed to main, not the commits on
the branch. Edit the title and description on GitHub and this re-runs.

The format is in commit.md.
EOF
  else
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
  fi
  exit 1
fi

if [ "$mode" = message ]; then
  echo "commit gate: the squashed message is OK"
else
  echo "commit gate: $(printf '%s\n' "$commits" | wc -l | tr -d ' ') commit(s) OK"
fi
