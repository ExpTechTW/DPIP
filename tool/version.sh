#!/usr/bin/env bash
# The one place a version is decided. Everything else reads it from here.
#
# Three values, deliberately unrelated to each other:
#
#   label  what a human sees            26.1        26w14a
#   train  what Apple is told           26.1        26.2
#   code   what the stores sort by      8262345     8262530
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

# Codes are decaseconds since this instant. Chosen over the alternatives on
# how each one *fails*:
#
#   * A commit count goes backwards if main is ever rewritten, and a store
#     that has seen a higher code will refuse every build after that — with no
#     recovery but a manual offset.
#   * Whole seconds cannot collide but pass Play's 2,100,000,000 ceiling in
#     2088, and the fix (coarser granularity) *lowers* the number, which is
#     the one thing that is not allowed.
#
# Decaseconds cannot go backwards (git committer dates only move forward),
# reach Play's ceiling in the year 2560 even after the offset below, and
# collide only if two commits land on main within ten seconds of each other.
readonly EPOCH=1704067200 # 2024-01-01T00:00:00Z
# And offset above every code already published, because a store will refuse a
# build whose ordinal is not higher than the last one it accepted. Play has
# seen 300909009 (the old `major×10⁸ + …` scheme); 400000000 clears it with
# room to spare and is a round number to recognise in a log.
readonly BASE=400000000

commit_epoch() { git log -1 --format=%ct "$1"; }

# The tag on HEAD, if this build *is* a release.
exact_tag="$(git describe --tags --exact-match 2>/dev/null || true)"

# The newest release tag anywhere in history, for working out what comes next.
last_tag="$(git tag --list 'v[0-9]*' --sort=-v:refname | head -n 1 || true)"

commit_ts="$(commit_epoch HEAD)"
code=$((BASE + (commit_ts - EPOCH) / 10))

# Two-digit year and ISO week of the commit, so a build is named after when it
# was made rather than when it was published.
year="$(date -u -r "$commit_ts" +%y 2>/dev/null || date -u -d "@$commit_ts" +%y)"
week="$(date -u -r "$commit_ts" +%V 2>/dev/null || date -u -d "@$commit_ts" +%V)"
# %V has a leading zero; the label does not want one.
week=$((10#$week))

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
  n=$(($(git tag --list "${year}w$(printf '%02d' "$week")*" | wc -l | tr -d ' ') + 1))
  letter=""
  i=$((n - 1))
  while :; do
    letter="$(printf "\\$(printf '%03o' $((97 + i % 26)))")$letter"
    i=$((i / 26 - 1))
    [ "$i" -lt 0 ] && break
  done
  label="${year}w$(printf '%02d' "$week")${letter}"

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
