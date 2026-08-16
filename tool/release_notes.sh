#!/usr/bin/env bash
# Builds a release note out of the commits it covers, in both languages.
#
# The commit message *is* the note. Writing one twice — once in the commit and
# once in a changelog file — is how the two drift, and the version people read
# is always the one nobody checked. `tool/check_commits.sh` is the other half
# of that bargain: it refuses a user-facing commit that does not carry both
# languages, so this can assume they are there.
#
# **What a note covers depends on which kind it is**, and the difference is not
# cosmetic:
#
#   snapshot   commits since the previous tag of any kind — a delta, because
#              whoever is reading it already has the one before.
#   release    commits since the previous *release* tag — cumulative, because
#              someone upgrading 26.1 → 26.2 never saw a single snapshot in
#              between, and a delta would tell them about a fraction of what
#              changed under them.
#
# Usage:  tool/release_notes.sh <label> <code> [--release]
set -euo pipefail

label="${1:?label required}"
code="${2:?build code required}"
kind="${3:-}"

readonly MARKER='=== 中文 ==='

# Platform tags are 14 px SVGs kept in this repository.
#
# Markdown image syntax rather than an `<img>` tag, and a repo-hosted file
# rather than a badge service, because the same Markdown is rendered twice:
#
#   * On GitHub, `raw.githubusercontent.com` serves `.svg` as `image/svg+xml`
#     (verified — a plain raw URL for most file types comes back as
#     `text/plain`, which would not render), and the intrinsic 14 px size in
#     the file is what keeps it inline with the text.
#   * In the app, `MarkdownBody` would fetch it — and this app is read offline,
#     which is the whole premise of a disaster app. The changelog page's
#     `imageBuilder` recognises these two names and draws a local Material icon
#     instead, so nothing is requested and nothing can break.
#
# The colours are chosen to hold on both a light and a dark backdrop, since an
# `<img>` inherits no theme.
readonly ASSETS='https://raw.githubusercontent.com/ExpTechTW/DPIP/main/.github/assets'
readonly TAG_ANDROID="![Android]($ASSETS/android.svg)"
readonly TAG_IOS="![iOS]($ASSETS/ios.svg)"

if [ "$kind" = "--release" ]; then
  # The previous release, not the previous tag.
  since="$(git tag --list 'v[0-9]*' --sort=-v:refname |
    grep -v "^v${label}\$" | head -n 1 || true)"
else
  since="$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || true)"
fi
range="${since:+$since..}HEAD"

# A plain string rather than an array: macOS still ships bash 3.2, which has
# neither `mapfile` nor `readarray`, and this has to run the same on a laptop
# as on the runner.
commits_of() { # <type-pattern>
  local out="" sha
  for sha in $(git rev-list --no-merges --reverse "$range" 2>/dev/null); do
    if git log -1 --format=%s "$sha" | grep -Eq "^($1)(\(|:)"; then
      out="$out $sha"
    fi
  done
  printf '%s' "$out"
}

scope_of() { git log -1 --format=%s "$1" | sed -n 's/^[a-z]*(\([^)]*\)).*/\1/p'; }
summary_of() { git log -1 --format=%s "$1" | sed 's/^[^:]*: //'; }

# `Platform: android` / `Platform: ios`, or nothing when a change affects both.
platform_of() {
  git log -1 --format=%b "$1" |
    sed -n 's/^[Pp]latform: *\([a-zA-Z]*\).*/\1/p' | head -n 1 |
    tr '[:upper:]' '[:lower:]'
}

platform_tag() {
  case "$(platform_of "$1")" in
  android) printf '%s ' "$TAG_ANDROID" ;;
  ios) printf '%s ' "$TAG_IOS" ;;
  esac
}

# Who to credit. The GitHub login where it can be resolved (CI has `gh` and a
# token), so the note @-mentions a real account; the commit author's name
# otherwise, which is all a laptop can know.
author_of() {
  local login=""
  if command -v gh >/dev/null 2>&1 && [ -n "${GITHUB_REPOSITORY:-}" ]; then
    login="$(gh api "repos/$GITHUB_REPOSITORY/commits/$1" \
      --jq '.author.login // empty' 2>/dev/null || true)"
  fi
  if [ -n "$login" ]; then
    printf '@%s' "$login"
  else
    git log -1 --format=%an "$1"
  fi
}

trim() { sed -e '/./,$!d' -e ':a' -e '/^\n*$/{$d;N;ba' -e '}'; }

# One side of the message, with the blank lines around it trimmed — the marker
# is surrounded by them, and they would otherwise open every entry with a gap.
half() { # <sha> <english|chinese>
  local body escaped
  body="$(git log -1 --format=%b "$1")"
  # Trailers are metadata, not prose.
  body="$(printf '%s\n' "$body" | grep -v '^[Pp]latform:' || true)"
  if ! printf '%s\n' "$body" | grep -Fxq -- "$MARKER"; then
    [ "$2" = english ] && printf '%s' "$body" | trim
    return
  fi
  escaped="$(printf '%s' "$MARKER" | sed 's/[]\/$*.^[]/\\&/g')"
  if [ "$2" = english ]; then
    printf '%s\n' "$body" | sed -n "1,/^$escaped\$/p" | sed '$d' | trim
  else
    printf '%s\n' "$body" | sed -n "/^$escaped\$/,\$p" | sed '1d' | trim
  fi
}

# The 中文 block's first line is its heading, so the Chinese section reads as
# Chinese rather than as English headings with Chinese underneath.
zh_summary() { half "$1" chinese | sed -n '1p'; }
zh_body() { half "$1" chinese | sed '1d' | trim; }

# The snapshot a change first shipped in — the nearest snapshot tag at or after
# the commit. Only meaningful in a release note; a snapshot's own entries all
# came from itself.
#
# Almost no project does this. GitHub's generated notes, Keep a Changelog and
# Flutter all publish a flat list and answer "what changed between these two"
# with a compare link instead — which is also at the foot of this note. It is
# here because DPIP publishes every snapshot, so a tester who has been running
# them can see at a glance which entries they already have. For everyone
# upgrading release-to-release it is noise, which is why it sits at the end of
# the line in a dimmer form rather than in front of the text.
first_seen_in() {
  [ "$kind" = "--release" ] || return 0
  git tag --list '[0-9][0-9]w[0-9][0-9]*' --contains "$1" 2>/dev/null |
    sort | head -n 1
}

entries() { # <shas> <english|chinese>
  local sha scope heading text snapshot
  for sha in $1; do
    scope="$(scope_of "$sha")"
    snapshot="$(first_seen_in "$sha")"
    if [ "$2" = english ]; then
      heading="$(summary_of "$sha")"
      text="$(half "$sha" english)"
    else
      heading="$(zh_summary "$sha")"
      text="$(zh_body "$sha")"
    fi
    printf -- '- %s%s%s — %s%s\n' \
      "$(platform_tag "$sha")" "$heading" \
      "${scope:+ \`$scope\`}" "$(author_of "$sha")" \
      "${snapshot:+ · \`$snapshot\`}"
    if [ -n "$(printf '%s' "$text" | tr -d '[:space:]')" ]; then
      # Indented so it belongs to the bullet above rather than ending the list.
      printf '\n%s\n\n' "$(printf '%s\n' "$text" | sed 's/^/  /')"
    fi
  done
}

group() { # <shas> <english|chinese> <heading>
  [ -z "$(printf '%s' "$1" | tr -d '[:space:]')" ] && return 0
  printf '### %s\n\n' "$3"
  entries "$1" "$2"
  printf '\n'
}

# The three groups the previous changelogs used, derived from the commit type
# so nobody has to pick a heading by hand — and so the type in the message and
# the heading in the note cannot disagree.
feats="$(commits_of 'feat')"
tunes="$(commits_of 'perf|refactor')"
fixes="$(commits_of 'fix')"

section() { # <english|chinese>
  if [ -z "$(printf '%s%s%s' "$feats" "$tunes" "$fixes" | tr -d '[:space:]')" ]; then
    if [ "$1" = english ]; then
      printf '_No user-facing changes._\n\n'
    else
      printf '_沒有使用者可見的變更。_\n\n'
    fi
    return
  fi
  if [ "$1" = english ]; then
    group "$feats" english '🌟 New features'
    group "$tunes" english '🔌 Improvements'
    group "$fixes" english '🐞 Bug fixes'
  else
    group "$feats" chinese '🌟 新功能'
    group "$tunes" chinese '🔌 最佳化'
    group "$fixes" chinese '🐞 錯誤修正'
  fi
}

repo="${GITHUB_REPOSITORY:-ExpTechTW/DPIP}"

{
  printf '# %s\n\n' "$label"
  if [ "$kind" = "--release" ]; then
    [ -n "$since" ] && printf '_自 %s 以來的全部變更。_\n\n' "$since"
  else
    printf '_快照，取自 main 的 `%s`。未經審查，可能有問題。_\n\n' \
      "$(git rev-parse --short HEAD)"
  fi

  # 中文 first and unfolded: this app is Taiwanese, and the language most of
  # its readers want should not be behind a click.
  section chinese

  # The English half, folded. The marker pair is what lets the app show one
  # language instead of both — `<details>` is HTML, which the in-app Markdown
  # renderer does not implement, so without it a phone would print the summary
  # text and then the whole English section expanded underneath the Chinese.
  printf '<!-- dpip-en -->\n'
  printf '<details>\n<summary>English</summary>\n\n'
  section english
  printf '</details>\n'
  printf '<!-- /dpip-en -->\n\n'

  if [ "$kind" = "--release" ] && [ -n "$since" ]; then
    # The compare link is how every other project answers "what changed
    # between these two" — GitHub's own generated notes end with exactly this
    # line. It is the authoritative diff; everything above is the readable one.
    printf -- '---\n\n'
    printf '**完整差異 / Full changelog**: https://github.com/%s/compare/%s...v%s\n\n' \
      "$repo" "$since" "$label"
    snapshots="$(git tag --list '[0-9][0-9]w[0-9][0-9]*' \
      --contains "$since" 2>/dev/null | sort || true)"
    if [ -n "$snapshots" ]; then
      printf '<details>\n<summary>包含的快照 · Snapshots covered</summary>\n\n'
      printf '%s\n' "$snapshots" | sed "s#^#- https://github.com/$repo/releases/tag/#"
      printf '\n</details>\n\n'
    fi
  fi

  # Machine-readable, and invisible in rendered Markdown: the app compares this
  # against its own ordinal to decide whether to offer an update. See
  # `buildCodeOf` in lib/features/changelog/domain/update_check.dart.
  printf '<!-- dpip-build: %s -->\n' "$code"
}
