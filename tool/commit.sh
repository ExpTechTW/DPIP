#!/usr/bin/env bash
# Everything you need to know before writing a commit message here.
#
#     tool/commit.sh                    # the briefing, and every CI gate
#     tool/commit.sh --message <file>   # also validate a draft message
#     tool/commit.sh --no-check         # briefing only, skip the gates
#     tool/commit.sh --push             # the stricter set, run before pushing
#     DPIP_NO_CACHE=1 tool/commit.sh    # re-run the gates, trusting no cache
#
# `.githooks/pre-commit` and `.githooks/pre-push` run it for you. Printing a
# blocker and being ignored is what this script did for its first day alive —
# a check nothing enforces is a check, and then a habit, and then neither.
#
# **Run this before every commit.** Not as ceremony — commit messages in this
# repo are the changelog (`tool/release/notes.sh` reads them and publishes
# them), and a pushed message cannot be edited. The only fix is a rebase and a
# force-push, which is expensive when it is your own branch and rude when it is
# not. Everything this prints is something that is cheap to know now and
# expensive to find out later.
#
# It reads and prints. It never commits, never stages, never fetches, and never
# changes a single file. Read the output, then write the commit yourself.
#
# The format itself is commit.md. This script does not restate it; it tells you
# which parts of it your particular change is about to run into.
source "$(dirname "${BASH_SOURCE[0]}")/dev/_lib.sh"
cd "$(repo_root)"

# Off when the output is not a terminal. An agent reading this through a pipe
# gets the words; escape sequences would be exactly the litter that makes a
# briefing unreadable.
if [ -t 1 ]; then
  readonly BOLD=$'\033[1m' DIM=$'\033[2m' RESET=$'\033[0m'
  readonly RED=$'\033[31m' GREEN=$'\033[32m' YELLOW=$'\033[33m' BLUE=$'\033[34m'
else
  readonly BOLD='' DIM='' RESET='' RED='' GREEN='' YELLOW='' BLUE=''
fi

blockers=0
warnings=0

heading() { printf '\n%s── %s ──%s\n' "$BOLD" "$*" "$RESET"; }
ok()      { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
note()    { printf '    %s%s%s\n' "$DIM" "$*" "$RESET"; }
warn()    { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$*"; warnings=$((warnings + 1)); }
block()   { printf '  %s✗%s %s\n' "$RED" "$RESET" "$*"; blockers=$((blockers + 1)); }

# The gates run by default. Finding out from CI what a local script could have
# told you in nine seconds costs a push, a wait, and usually a rebase — and the
# reason it was ever optional was that it took a minute, which the content-hash
# cache in dev/_lib.sh has now taken away.
run_gates=1
msg_file=''
# Commit time or push time. They are not the same question, and conflating them
# was the first version's mistake: being behind the base blocks a *merge*, not a
# commit. Demanding a rebase before every commit would mean rebasing five times
# an afternoon to record work that is not going anywhere yet — so at commit time
# it is worth saying and not worth stopping for, and at push time it stops you.
profile=commit
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-check) run_gates=0; shift ;;
    --check) shift ;;  # kept: it was the old opt-in, and is now the default
    --push) profile=push; shift ;;
    --message) msg_file="${2:?--message needs a file}"; shift 2 ;;
    *)
      printf 'usage: tool/commit.sh [--push] [--no-check] [--message <file>]\n' >&2
      exit 2
      ;;
  esac
done

# Raises a blocker at push time and a warning at commit time.
merge_time() { if [[ $profile == push ]]; then block "$@"; else warn "$@"; fi; }

# ── Where you are ───────────────────────────────────────────────────────────
heading 'Where you are'

branch="$(git rev-parse --abbrev-ref HEAD)"
base='origin/main'
git rev-parse --verify --quiet "$base" >/dev/null || base='main'

printf '  branch   %s%s%s\n' "$BLUE" "$branch" "$RESET"
printf '  HEAD     %s %s\n' "$(git rev-parse --short HEAD)" "$(git log -1 --format=%s)"
printf '  base     %s (%s)\n' "$base" "$(git rev-parse --short "$base" 2>/dev/null || echo '?')"

if [[ $branch == main || $branch == master ]]; then
  block "you are on $branch — branch first, this repo never commits to it directly"
  note 'git switch -c <type>/<what>'
fi

# The base ref is a local copy. Nothing here fetches — a script that reaches the
# network on every run gets skipped — but a base from last week makes the
# ahead/behind counts below describe a repository nobody else has.
if base_age="$(git log -1 --format=%cr "$base" 2>/dev/null)"; then
  base_epoch="$(git log -1 --format=%ct "$base" 2>/dev/null || echo 0)"
  if (($(date +%s) - base_epoch > 86400)); then
    warn "$base is $base_age — run \`git fetch origin\` before trusting the counts below"
  else
    note "$base last moved $base_age"
  fi
fi

# ── Rebase ──────────────────────────────────────────────────────────────────
heading 'Rebase'

if counts="$(git rev-list --left-right --count "$base...HEAD" 2>/dev/null)"; then
  behind="${counts%%	*}"
  ahead="${counts##*	}"
  printf '  %s commit(s) ahead, %s behind\n' "$ahead" "$behind"

  if ((behind > 0)); then
    merge_time "behind $base — CI refuses to merge a branch that is not rebased"
    note 'Everything green on this branch was tested against a main that no'
    note 'longer exists, so the gates describe a tree nobody will get.'
    note ''
    note 'git fetch origin && git rebase origin/main && git push --force-with-lease'

    # The rebase above refuses to start if a skip-worktree file has local
    # changes, and the error names the file without saying why it cannot be
    # stashed — `git stash -u` skips it too, because skip-worktree is exactly
    # a promise that git will not look at it.
    skipped=()
    while IFS= read -r line; do
      [[ $line == S* ]] && skipped+=("${line#S }")
    done < <(git ls-files -v | grep '^S' || true)
    if ((${#skipped[@]} > 0)); then
      note ''
      note "If that rebase refuses to start over ${skipped[0]}:"
      note "  git update-index --no-skip-worktree ${skipped[*]}"
      note "  git checkout -- ${skipped[*]}"
      note '  … rebase …'
      note "  git update-index --skip-worktree ${skipped[*]}"
    fi
  else
    ok "up to date with $base"
  fi

  merges="$(git rev-list --merges "$base..HEAD" | wc -l | tr -d ' ')"
  if ((merges > 0)); then
    block "$merges merge commit(s) on this branch"
    note 'check/commits.sh walks with --no-merges, so anything that arrived'
    note 'through a merge is never checked at all. Merging bypasses the gate.'
  else
    ok 'no merge commits'
  fi
else
  warn "no $base to compare against — cannot say whether a rebase is needed"
fi

# ── Working tree ────────────────────────────────────────────────────────────
heading 'Working tree'

staged=()
while IFS= read -r f; do [[ -n $f ]] && staged+=("$f"); done < <(git diff --cached --name-only)
unstaged=()
while IFS= read -r f; do [[ -n $f ]] && unstaged+=("$f"); done < <(git diff --name-only)
untracked=()
while IFS= read -r f; do [[ -n $f ]] && untracked+=("$f"); done < <(git ls-files --others --exclude-standard)

if ((${#staged[@]} == 0)); then
  warn 'nothing staged — the sections below describe an empty commit'
else
  ok "${#staged[@]} file(s) staged"
  git diff --cached --stat | sed 's/^/    /'
fi

if ((${#unstaged[@]} > 0)); then
  printf '  %s%d file(s) modified but not staged%s\n' "$DIM" "${#unstaged[@]}" "$RESET"
  printf '    %s\n' "${unstaged[@]:0:12}"
  ((${#unstaged[@]} > 12)) && note "… and $(( ${#unstaged[@]} - 12 )) more"
fi
if ((${#untracked[@]} > 0)); then
  printf '  %s%d untracked file(s)%s\n' "$DIM" "${#untracked[@]}" "$RESET"
  printf '    %s\n' "${untracked[@]:0:12}"
  ((${#untracked[@]} > 12)) && note "… and $(( ${#untracked[@]} - 12 )) more"
  note 'Untracked files are invisible to CI. A new file the change needs but'
  note 'nobody staged fails on the runner and nowhere else.'
fi

# Things that are staged and probably should not be.
for f in ${staged[@]+"${staged[@]}"}; do
  case "$f" in
    build/*|.dart_tool/*|*.iml|*/Pods/*|ios/Flutter/Generated.xcconfig|*/DerivedData/*)
      block "$f is build output — it does not belong in a commit" ;;
    lib/core/build_info.g.dart)
      # skip-worktree, and it holds the hash of the commit it is committed in,
      # so a local copy is always "wrong" and staging it is always churn.
      block "$f is generated per-commit and marked skip-worktree — unstage it" ;;
    *.freezed.dart|*.g.dart)
      note "$f is generated — fine to commit, but it must match a fresh codegen run" ;;
  esac
done

# ── What the change touches ─────────────────────────────────────────────────
heading 'What the change touches'

if ((${#staged[@]} > 0)); then
  features=()
  while IFS= read -r feat; do [[ -n $feat ]] && features+=("$feat"); done < <(
    printf '%s\n' "${staged[@]}" |
      sed -n 's|^lib/features/\([^/]*\)/.*|\1|p' | sort -u
  )
  ((${#features[@]} > 0)) && printf '  features: %s\n' "${features[*]}"

  areas=()
  printf '%s\n' "${staged[@]}" | grep -q '^lib/' && areas+=('app code')
  printf '%s\n' "${staged[@]}" | grep -q '^test/' && areas+=('tests')
  printf '%s\n' "${staged[@]}" | grep -q '^tool/' && areas+=('tooling')
  printf '%s\n' "${staged[@]}" | grep -q '^\.github/' && areas+=('CI')
  printf '%s\n' "${staged[@]}" | grep -qE '^[A-Za-z]+\.md$' && areas+=('docs')
  printf '%s\n' "${staged[@]}" | grep -qE '^(android|ios)/' && areas+=('native')
  printf '%s\n' "${staged[@]}" | grep -q '^lib/l10n/' && areas+=('l10n')
  ((${#areas[@]} > 0)) && printf '  areas:    %s\n' "${areas[*]}"

  # commit.md's "one commit, one thing" cannot be checked — nothing can decide
  # whether two changes are the same thing. These are the two shapes worth a
  # second look, and they are stated as questions on purpose.
  if ((${#features[@]} > 2)); then
    warn "${#features[@]} features in one commit — is this one thing? (commit.md → 一個 commit 一件事)"
  fi
  if printf '%s\n' "${areas[*]}" | grep -q 'docs' && printf '%s\n' "${areas[*]}" | grep -q 'app code'; then
    warn 'documentation and app code together — often two commits (commit.md lists this as a smell)'
  fi

  # Platform trailer. Only staged native paths can suggest it; a Dart-only
  # change can still be platform-specific, which is why this is a question.
  has_android=0; has_ios=0
  printf '%s\n' "${staged[@]}" | grep -q '^android/' && has_android=1
  printf '%s\n' "${staged[@]}" | grep -q '^ios/' && has_ios=1
  if ((has_android && !has_ios)); then
    note 'Android only? then the message needs a `Platform: android` trailer'
  elif ((has_ios && !has_android)); then
    note 'iOS only? then the message needs a `Platform: ios` trailer'
  fi

  # An ARB touched without its siblings is the failure the l10n gate exists
  # for, and it is worth saying here because it changes the commit, not just
  # the code.
  arb_count="$(printf '%s\n' "${staged[@]}" | grep -c '^lib/l10n/app_.*\.arb$' || true)"
  total_arb="$(git ls-files 'lib/l10n/app_*.arb' | wc -l | tr -d ' ')"
  if ((arb_count > 0 && arb_count < total_arb)); then
    warn "$arb_count of $total_arb ARB files staged — a key missing from one locale falls back to English silently"
  fi
fi

# ── The message you are about to write ──────────────────────────────────────
heading 'The message you are about to write'

cat <<'SHAPE'
    <type>(<scope>): <english summary, imperative, ≤72, no full stop>

    Platform: android|ios          ← only when it affects one platform

    <Category>(zh-Hant): <一行，講使用者感覺得到的結果>
    <Category>(en-US): <the same line, in English>

  type      feat fix perf refactor docs test build ci style chore revert
  Category  New (🌟) · Optimization (🔌) · Fix (🐞) — declared, not derived
            from <type>; a chore: that fixes something visible says Fix(...)
  locales   zh-Hant and en-US are required; the rest are optional
SHAPE

printf '\n  %sThe three that fail quietly%s\n' "$BOLD" "$RESET"
note 'feat / fix / perf with no Category line never reaches a changelog'
note 'entry counts must match across locales, or one language silently'
note '  ships a shorter list than the others'
note 'no Co-Authored-By, no tool or model attribution, in any form'
note ''
note 'The summary is for `git log`. The Category lines are read by users, so'
note 'they say what changed for them — not what the diff did. Reasons belong'
note 'in code comments, where the next person to touch it will be looking.'

# ── Gates ───────────────────────────────────────────────────────────────────
heading 'Gates'

if [[ -n $msg_file ]]; then
  if tool/check/commits.sh --message "$msg_file" 2>&1 | sed 's/^/  /'; then
    ok "draft message in $msg_file is valid"
  else
    block "draft message in $msg_file is not valid"
  fi
fi

if git rev-parse --verify --quiet "$base" >/dev/null && [[ -z $(git rev-list "$base..HEAD" 2>/dev/null) ]]; then
  note "no commits on this branch yet — nothing for check/commits.sh to walk"
elif git rev-parse --verify --quiet "$base" >/dev/null; then
  if out="$(tool/check/commits.sh "$base..HEAD" 2>&1)"; then
    ok "${out#commit gate: }"
  else
    block 'existing commits on this branch do not pass the gate'
    printf '%s\n' "$out" | sed 's/^/    /'
    note 'A message cannot be edited after the fact:'
    note '  git rebase -i '"$base"'   # mark the offenders as reword'
  fi
fi

if ((run_gates)); then
  heading 'CI gates'
  note 'Everything ci.yml runs. Each step is cached on a content hash of its'
  note 'inputs, so an unchanged tree costs seconds instead of a minute.'
  printf '\n'
  if tool/check.sh; then
    ok 'every gate passed — this is what CI will do'
  else
    block 'a gate failed — CI will fail the same way'
  fi
else
  warn 'gates skipped (--no-check) — CI has not been reproduced'
fi

# ── Verdict ─────────────────────────────────────────────────────────────────
heading 'Verdict'

if ((blockers > 0)); then
  printf '  %s%d blocker(s)%s, %d warning(s). Fix the blockers first.\n' \
    "$RED" "$blockers" "$RESET" "$warnings"
  exit 1
fi

if ((warnings > 0)); then
  printf '  %s%d warning(s)%s, no blockers. Read them, then:\n' "$YELLOW" "$warnings" "$RESET"
else
  printf '  %sclear%s. Then:\n' "$GREEN" "$RESET"
fi
cat <<'NEXT'

    git commit -F <(cat <<'EOF'
    <your message>
    EOF
    )
    tool/commit.sh          # re-run: it now checks the commit you just wrote
    git push --force-with-lease

  The full format, with examples and the reasoning, is commit.md.
NEXT
