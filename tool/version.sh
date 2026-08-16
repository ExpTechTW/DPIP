#!/usr/bin/env bash
# The one place a version is decided. Everything else reads it from here.
#
# Three values, deliberately unrelated to each other:
#
#   label  what a human sees            26.1        26w14a
#   train  what Apple is told           26.1        26.1
#   code   what both stores sort by     426000298   426000299
#
# One code, not one per store. They can be aligned because the two floors do
# not both apply at once — see FLOOR and BURNED_TRAINS below.
#
# They are separated because they answer different questions and obey
# different rules:
#
#   * `label` is the name. Minecraft-style: `<yy>.<n>` for a release, and
#     `<yy>w<week><letter>` for a snapshot. Free text; it goes in the app, in
#     the GitHub release, and in Play's `versionName`.
#
#   * `train` is the release being worked toward, and exists only because
#     Apple rejects anything else. `CFBundleShortVersionString` must be "a
#     period-separated list of at most three non-negative integers"
#     (ERROR ITMS-90060), enforced at *upload* — so TestFlight is no escape,
#     internal testing included. A snapshot therefore uploads under the number
#     of the release it precedes, which is also what Apple means by the field.
#
#   * `code` is the only thing that decides which build is newer. Monotonic,
#     integer, meaningless to read. Both stores order by it and nothing else.
#
# Because they are separate, the label can be reordered, restyled or renamed
# without a store ever noticing, and a snapshot named `26w14a` can precede a
# release named `26.1` without the number going backwards.
#
# Usage:  eval "$(tool/version.sh)"   → DPIP_LABEL, DPIP_TRAIN, DPIP_CODE
#         tool/version.sh --json      → one JSON object
#
# Needs full history: run actions/checkout with `fetch-depth: 0`.
set -euo pipefail

# The code is a floor plus the commit count. Nothing more: it only has to go
# up, and one per commit is the smallest step that always does.
#
# A timestamp works too and was the first draft, but it makes a nine-digit
# number whose digits mean nothing and which moves by thousands between two
# builds an hour apart. The commit count is legible — 2118 is the 2118th
# commit — and it moves by exactly as much as the work did.
#
# What it costs: a rewritten history can lower it, where a clock cannot. That
# is why the release workflow refuses to build when the code is not above
# every one already published — a rewrite then stops the run instead of
# poisoning a store, and the fix is to raise FLOOR by a line.
#
# The code is `4 | yy | commits-this-year`, read straight off the digits:
#
#   426000298  =  generation 4, year 2026, the 298th commit of 2026
#
# Each part earns its place. The generation says which numbering era a build
# belongs to; the year is what a support conversation starts with; the count is
# the only value anywhere that maps back to an exact revision
# (`git rev-list HEAD --since=<year start>`), which the label cannot do because
# a label names a *week*.
#
# **This year's count, not the total.** It keeps the digits comparable between
# years — 298 so far in 2026 against whatever 2025 finished at — and it cannot
# drift toward the million ceiling as the repo ages. Monotonic all the same: it
# only rises within a year, and a new year adds 1,000,000 while the count
# restarts near zero, so 427,000,001 clears every value 2026 could reach.
#
# Ceilings: 999,999 commits in one year, and year 99 lands at 499,999,999 —
# comfortably under Android lint's 2,000,000,000.
#
# **The leading 4 is load-bearing.** It is what clears both stores' history at
# once, which is what lets them share one number:
#
#   300909022  published on Play — 3.9.9 build 22 under the layout the app
#              shipped with (`major×10⁸ + minor×10⁵ + patch×10³ + build`, which
#              reproduces the number exactly). A `versionCode` is unique and
#              increasing app-wide and forever.
#   408283049  sitting in TestFlight under train 26.1, from an earlier draft of
#              this script that derived the code from a timestamp. Within a
#              train a build number may only increase (TN2420 scopes that to
#              the train, not the app — macOS is the one that needs global
#              monotonicity).
#
# The smallest value this scheme can emit is 426,000,001, which clears both.
# That is why there is no burned-train rule any more: 26.1 is usable, and the
# year's first release can simply be called 26.1.
#
# Lower the generation digit and that stops being true — 3 would put the code
# under the TestFlight build and lock train 26.1 again. `version_script_test`
# pins it.
readonly SCHEME=4


commit_epoch() { git log -1 --format=%ct "$1"; }

# The RELEASE tag on HEAD, if this build is one.
#
# `v[0-9]*` and not `git describe --tags --exact-match`. Every published
# snapshot is tagged too (`26w33c`), and describe answers with whichever tag it
# likes — so the run after the first snapshot would take the release branch and
# set `train=26w33c`. That is not a number, and Flutter does not reject it: it
# strips the letters and ships `2633.0.0` to Apple, where a marketing version
# can never go down again. The whole `26.x` range would be gone.
#
# The `v` prefix is therefore the only thing that makes a build a release, and
# it is the one part a human types.
exact_tag="$(git tag --points-at HEAD --list 'v[0-9]*' --sort=-v:refname | head -n 1 || true)"

# The newest release tag anywhere in history, for working out what comes next.
last_tag="$(git tag --list 'v[0-9]*' --sort=-v:refname | head -n 1 || true)"

commit_ts="$(commit_epoch HEAD)"

# Two-digit year and ISO week of the commit, so a build is named after when it
# was made rather than when it was published.
year="$(date -u -r "$commit_ts" +%y 2>/dev/null || date -u -d "@$commit_ts" +%y)"
week="$(date -u -r "$commit_ts" +%V 2>/dev/null || date -u -d "@$commit_ts" +%V)"
# %V has a leading zero; the label does not want one.
week=$((10#$week))

# Commits since this year began, on the same clock the year came from. Needs
# the full history — a shallow clone counts only what it fetched.
year_start="$(date -u -r "$commit_ts" +%Y 2>/dev/null || date -u -d "@$commit_ts" +%Y)-01-01T00:00:00Z"
commits="$(git rev-list --count HEAD --since="$year_start")"
code=$((SCHEME * 100000000 + 10#$year * 1000000 + commits))

if [ -n "$exact_tag" ]; then
  # A release: the tag is the label, and the label is the train.
  label="${exact_tag#v}"
  train="$label"
else
  # A snapshot. The letter counts the snapshots already *published* this week,
  # so this build is the next one: the first is `a`, the second `b`.
  #
  # Published, not committed. Counting commits looked equivalent and is not —
  # a push carries several commits but produces one build, and any build that
  # is filtered out or fails leaves a hole. This repo saw 143 commits in one
  # week; the letters would have run to `ej` while a tester could download
  # perhaps five things, none of them named consecutively.
  prefix="${year}w$(printf '%02d' "$week")"
  n=$(($(git tag --list "${prefix}*" | wc -l | tr -d ' ') + 1))
  letter=""
  i=$((n - 1))
  while :; do
    letter="$(printf "\\$(printf '%03o' $((97 + i % 26)))")$letter"
    i=$((i / 26 - 1))
    [ "$i" -lt 0 ] && break
  done
  label="${prefix}${letter}"

  # Count and tag can disagree — a run whose publish step failed after tagging,
  # a tag deleted by hand. Walking forward past whatever exists costs nothing
  # and keeps the name unique, which is what actually matters: a duplicate tag
  # fails the release at the last step, after both platforms have been built.
  while git rev-parse -q --verify "refs/tags/$label" >/dev/null; do
    n=$((n + 1))
    letter=""
    i=$((n - 1))
    while :; do
      letter="$(printf "\\$(printf '%03o' $((97 + i % 26)))")$letter"
      i=$((i / 26 - 1))
      [ "$i" -lt 0 ] && break
    done
    label="${prefix}${letter}"
  done

  # The train is the release this snapshot precedes: the next number after the
  # newest tag, or the year's first release if there is not one yet.
  if [ -n "$last_tag" ]; then
    tag_year="${last_tag#v}"
    tag_year="${tag_year%%.*}"
    tag_seq="${last_tag##*.}"
    if [ "$tag_year" = "$year" ]; then
      train="${year}.$((tag_seq + 1))"
    else
      train="${year}.1"
    fi
  else
    train="${year}.1"
  fi
fi

if [ "${1:-}" = "--json" ]; then
  printf '{"label":"%s","train":"%s","code":%s}\n' "$label" "$train" "$code"
else
  printf 'DPIP_LABEL=%s\nDPIP_TRAIN=%s\nDPIP_CODE=%s\n' "$label" "$train" "$code"
fi
