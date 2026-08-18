#!/usr/bin/env bash
# Builds a release note out of the changelog lines its commits declare.
#
# A commit says what belongs in the changelog by carrying one line per entry:
#
#     New(zh-Hant): 地圖可以疊加雷達回波
#     New(en-US): the map can overlay radar echo
#     Fix(zh-Hant): 修正離線時圖層閃爍
#     Fix(en-US): stop layers flickering when offline
#
# Everything here is extracted with one regular expression. Three consequences
# make this worth more than the prose bodies it replaces:
#
#   * **A squash cannot corrupt it.** GitHub concatenates every commit on the
#     branch into one body; that just yields more matching lines, all of them
#     valid. The previous scheme split prose on a `=== 中文 ===` marker, and a
#     squash put raw markers and whole English paragraphs inside the Chinese
#     section of 26w33b.
#   * **One commit can be more than one entry**, in more than one category —
#     which is often true, and which a one-commit-one-entry mapping could not
#     express.
#   * **It scales past two languages.** The app ships ten locales; a note that
#     is only 中文 and English can serve two of them.
#
# The category is declared, not inferred from the commit type. A user-visible
# change filed under `chore:` used to vanish from every note with nothing to
# warn anyone; now the line is either there or it is not.
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
# Usage:  tool/release/notes.sh <label> <code> [--release]
set -euo pipefail

label="${1:?label required}"
code="${2:?build code required}"
kind="${3:-}"

# The primary language, printed unfolded. Every other language is published in
# its own folded, marked block that the in-app changelog picks by locale.
readonly PRIMARY='zh-Hant'

# Category → heading, per language. Adding a language means adding rows here
# and a locale to tool/check/commits.sh; nothing else changes.
heading_for() { # <category> <locale>
  case "$2::$1" in
  zh-Hant::New | zh-Hant-HK::New) printf '🌟 新功能' ;;
  zh-Hant::Optimization | zh-Hant-HK::Optimization) printf '🔌 最佳化' ;;
  zh-Hant::Fix | zh-Hant-HK::Fix) printf '🐞 錯誤修正' ;;
  zh-Hans::New) printf '🌟 新功能' ;;
  zh-Hans::Optimization) printf '🔌 优化' ;;
  zh-Hans::Fix) printf '🐞 错误修复' ;;
  ja-JP::New) printf '🌟 新機能' ;;
  ja-JP::Optimization) printf '🔌 改善' ;;
  ja-JP::Fix) printf '🐞 不具合修正' ;;
  *::New) printf '🌟 New features' ;;
  *::Optimization) printf '🔌 Improvements' ;;
  *::Fix) printf '🐞 Bug fixes' ;;
  esac
}

language_name() { # <locale>
  case "$1" in
  en-US) printf 'English' ;;
  ja-JP) printf '日本語' ;;
  ko-KR) printf '한국어' ;;
  th-TH) printf 'ไทย' ;;
  vi-VN) printf 'Tiếng Việt' ;;
  id-ID) printf 'Bahasa Indonesia' ;;
  fil-PH) printf 'Filipino' ;;
  zh-Hans) printf '简体中文' ;;
  zh-Hant-HK) printf '繁體中文（香港）' ;;
  *) printf '%s' "$1" ;;
  esac
}

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

# Which platforms an entry applies to, always stated.
#
# A `Platform:` trailer narrows it to one; without a trailer the change is on
# both, and both icons are drawn. Marking only the single-platform entries
# leaves every other line ambiguous — the reader cannot tell "applies to both"
# from "nobody said", and those are different claims.
platform_tag() {
  case "$(git log -1 --format=%b "$1" |
    sed -n 's/^[Pp]latform: *\([a-zA-Z]*\).*/\1/p' | head -n 1 |
    tr '[:upper:]' '[:lower:]')" in
  android) printf '%s ' "$TAG_ANDROID" ;;
  ios) printf '%s ' "$TAG_IOS" ;;
  *) printf '%s %s ' "$TAG_ANDROID" "$TAG_IOS" ;;
  esac
}

# Who to credit.
#
# **Not the commit author.** GitHub squashes a pull request into one commit and
# sets its author to whoever pressed the button, demoting everyone who actually
# wrote it to a `Co-authored-by:` trailer. `41a3c1e8 Fix eew (#534)` is authored
# by the maintainer who merged it and was written, every commit of it, by
# someone else — so the note credited the wrong person, which is worse than
# crediting nobody.
#
# So: when a summary carries a pull request number, the authors are the authors
# of *that pull request's commits*. `Co-authored-by:` trailers are merged in
# too, because a merge without a number still records them. The commit's own
# author is the fallback, and the display name after that — all a laptop with
# no network can know.
readonly REPO_API='https://api.github.com/repos'

# One field out of a JSON document. python3 because the shape is nested and
# `sed` cannot see structure — it reads the first `"login"` on a line and calls
# it the answer, which is right until the day it is not.
api_json() { # <path> <python expression over `d`>
  local body status
  body="$(curl -sS --max-time 15 -w '\n%{http_code}' \
    -H 'Accept: application/vnd.github+json' \
    ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
    "$REPO_API/${GITHUB_REPOSITORY:-ExpTechTW/DPIP}/$1" 2>/dev/null)"
  status="${body##*$'\n'}"
  body="${body%$'\n'*}"

  # Say so, once per call, rather than returning nothing and letting the note
  # ship with no attribution. Unauthenticated the limit is 60 requests an hour
  # *per IP*, shared with every other job on that runner, so a rate-limited
  # release used to produce a note that looked finished and credited nobody.
  case "$status" in
  200) ;;
  403 | 429)
    printf 'notes.sh: GitHub rate-limited %s (HTTP %s) — attribution will be incomplete\n' \
      "$1" "$status" >&2
    return 0
    ;;
  *)
    printf 'notes.sh: GitHub returned HTTP %s for %s\n' "$status" "$1" >&2
    return 0
    ;;
  esac

  printf '%s' "$body" | python3 -c "
import json,sys
try: d = json.load(sys.stdin)
except Exception: raise SystemExit
$2" 2>/dev/null || true
}

# Who wrote the change, as a GitHub login.
#
# Only rebase merging is allowed here (Settings → Pull requests), so a commit on
# main is the commit somebody wrote: its author is the author, and one lookup by
# sha answers it. There used to be a fourth path that resolved `(#N)` back to a
# pull request's own commits, because a squash sets the author to whoever
# pressed merge — that is gone with squashing, and the deliberate cost is the
# 282 commits already on main that came in that way. Their entries will credit
# the merger unless a trailer says otherwise.
authors_of() {
  local sha="$1" logins=""

  # Trailers first, and no network: when a co-author is recorded, they are the
  # answer, and a local `notes.sh` run should not need the API to say so.
  local trailer
  trailer="$(git log -1 --format=%b "$sha" |
    sed -n 's/^[Cc]o-authored-by: *\(.*\) <\(.*\)>.*/\2|\1/p')"
  while IFS='|' read -r email name; do
    [ -n "$name" ] || continue
    # `1234+login@users.noreply.github.com` carries the login; a real address
    # does not, and GitHub will not resolve one — so the name is used as given.
    case "$email" in
    *+*@users.noreply.github.com) logins="$logins ${email#*+}" ;;
    *) logins="$logins $name" ;;
    esac
  done <<EOF
$trailer
EOF
  logins="$(printf '%s' "${logins% }" | tr ' ' '\n' | sed 's/@users.noreply.github.com//' |
    grep -v '^$' | awk '!seen[$0]++' | tr '\n' ' ')"

  if [ -z "${logins// /}" ]; then
    logins="$(api_json "commits/$sha" "print(d['author']['login'] if d.get('author') else '')")"
  fi
  if [ -z "${logins// /}" ]; then
    printf '%s' "$(git log -1 --format=%an "$sha")"
    return
  fi
  # `@a, @b` — every name that wrote it, trailers first.
  printf '%s' "$(printf '%s' "${logins% }" | sed 's/[^ ][^ ]*/@&/g; s/ /, /g')"
}

# The snapshot a change first shipped in — the nearest snapshot tag at or after
# the commit. Only meaningful in a release note; a snapshot's own entries all
# came from itself.
#
# Almost no project does this. GitHub's generated notes, Keep a Changelog and
# Flutter all publish a flat list and answer "what changed between these two"
# with a compare link instead — which is also at the foot of this note. It is
# here because DPIP publishes every snapshot, so a tester who has been running
# them can see at a glance which entries they already have.
first_seen_in() {
  [ "$kind" = "--release" ] || return 0
  git tag --list '[0-9][0-9]w[0-9][0-9]*' 'snapshot/[0-9][0-9]w[0-9][0-9]*' \
    --contains "$1" 2>/dev/null | sed 's#^snapshot/##' | sort | head -n 1
}

# One file per category+locale: macOS still ships bash 3.2, which has no
# associative arrays, and this has to run the same on a laptop as on a runner.
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# The whole format, in one expression:  Category(locale): text
readonly LINE_RE='^(New|Optimization|Fix)\(([A-Za-z]{2,3}(-[A-Za-z0-9]+)*)\):[[:space:]]*(.+)$'

readonly repo_slug="${GITHUB_REPOSITORY:-ExpTechTW/DPIP}"

locales=""
for sha in $(git rev-list --no-merges --reverse "$range" 2>/dev/null); do
  # Read the body once. A commit with no changelog line contributes nothing and
  # costs no API call.
  # An entry may be hard-wrapped — commit.md's own Android example is — and the
  # regex below is whole-line, so a continuation used to be dropped in silence.
  # Three sentences shipped cut mid-clause in 41a3c1e8: "…on the monitor and
  # the", with "replay map" left behind. Folded back on first, so what the
  # writer wrote is what the reader gets.
  body="$(git log -1 --format=%b "$sha" | awk '
    /^[[:space:]]+[^[:space:]]/ && held { sub(/^[[:space:]]+/, " "); printf "%s", $0; next }
    { if (held) printf "\n"; printf "%s", $0; held = 1 }
    END { if (held) printf "\n" }
  ')"
  printf '%s\n' "$body" | grep -Eq "$LINE_RE" || continue

  tag="$(platform_tag "$sha")"
  who="$(authors_of "$sha")"
  short="$(git log -1 --format=%h "$sha")"
  snapshot="$(first_seen_in "$sha")"

  while IFS= read -r line; do
    printf '%s' "$line" | grep -Eq "$LINE_RE" || continue
    category="$(printf '%s' "$line" | sed -E "s/$LINE_RE/\\1/")"
    locale="$(printf '%s' "$line" | sed -E "s/$LINE_RE/\\2/")"
    text="$(printf '%s' "$line" | sed -E "s/$LINE_RE/\\4/")"
    # The pre-release an entry first shipped in, on the end of its own line. A
    # tester running snapshots reads it to see what they already have; an entry
    # with no marker is new in this release and nobody has seen it yet.
    # The commit is linked from every entry: an entry says what changed, and
    # the link is the only way to ask *how* without going looking for it. For a
    # squashed pull request GitHub redirects that commit to the request, so one
    # link answers both.
    printf -- '- %s%s — %s ([`%s`](https://github.com/%s/commit/%s))%s\n' \
      "$tag" "$text" "$who" "$short" "$repo_slug" "$sha" \
      "${snapshot:+ · \`$snapshot\`}" \
      >>"$work/$category.$locale"
    case " $locales " in
    *" $locale "*) ;;
    *) locales="$locales $locale" ;;
    esac
  done <<EOF
$body
EOF
done

# Primary first, then the rest alphabetically, so a note's language order does
# not shuffle between builds.
ordered_locales() {
  printf '%s\n' "$PRIMARY"
  for l in $locales; do
    [ "$l" = "$PRIMARY" ] || printf '%s\n' "$l"
  done | sort
}

section() { # <locale>
  local any=0 c file
  for c in New Optimization Fix; do
    file="$work/$c.$1"
    [ -s "$file" ] || continue
    any=1
    printf '### %s\n\n' "$(heading_for "$c" "$1")"
    cat "$file"
    printf '\n'
  done
  if [ "$any" -eq 0 ]; then
    if [ "$1" = "$PRIMARY" ]; then
      printf '_沒有使用者可見的變更。_\n\n'
    else
      printf '_No user-facing changes._\n\n'
    fi
  fi
}

repo="${GITHUB_REPOSITORY:-ExpTechTW/DPIP}"

{
  # No heading: GitHub prints the release name above the body, and the app's
  # changelog tile prints it too, so a `# 26w33b` here is the same string twice
  # in both places it is ever read.
  if [ "$kind" = "--release" ]; then
    [ -n "$since" ] && printf '_自 %s 以來的全部變更。_\n\n' "$since"
  else
    printf '_快照，取自 main 的 `%s`。未經審查，可能有問題。_\n\n' \
      "$(git rev-parse --short HEAD)"
  fi

  # 中文 first and unfolded: this app is Taiwanese, and the language most of
  # its readers want should not be behind a click.
  section "$PRIMARY"

  # Every other language in its own folded block. The markers are what let the
  # app show one language instead of all of them — `<details>` is HTML, which
  # the in-app Markdown renderer does not implement, so without them a phone
  # would print each `<summary>` as prose and then every translation expanded
  # underneath the Chinese.
  # Everything that is not the primary language sits inside one `dpip-en`
  # region as well.
  #
  # Every already-installed build looks for exactly that marker pair, and shows
  # a body **whole** when it is absent — so publishing only the new per-language
  # markers made every phone in the field print `<summary>English</summary>` as
  # a line of prose and then the whole English section under the Chinese. A
  # note is read by the app versions that already exist, not only by the one
  # being built.
  #
  # One region around all of them rather than a pair per block, because the old
  # parser understands exactly one: this way a 中文 reader on an old build gets
  # a clean note, and a reader of some other language gets every translation
  # unfolded — degraded, but readable, and their own language is in there.
  first_extra=1
  for locale in $(ordered_locales); do
    [ "$locale" = "$PRIMARY" ] && continue
    if [ "$first_extra" = 1 ]; then
      printf '<!-- dpip-en -->\n'
      first_extra=0
    fi
    printf '<!-- dpip-lang:%s -->\n' "$locale"
    printf '<details>\n<summary>%s</summary>\n\n' "$(language_name "$locale")"
    section "$locale"
    printf '</details>\n'
    printf '<!-- /dpip-lang:%s -->\n\n' "$locale"
  done
  [ "$first_extra" = 0 ] && printf '<!-- /dpip-en -->\n\n'

  if [ "$kind" = "--release" ] && [ -n "$since" ]; then
    # The compare link is how every other project answers "what changed
    # between these two" — GitHub's own generated notes end with exactly this
    # line. It is the authoritative diff; everything above is the readable one.
    printf -- '---\n\n'
    printf '**完整差異 / Full changelog**: https://github.com/%s/compare/%s...v%s\n\n' \
      "$repo" "$since" "$label"
  fi

  # Machine-readable, and invisible in rendered Markdown: the app compares this
  # against its own ordinal to decide whether to offer an update. See
  # `buildCodeOf` in lib/features/changelog/domain/update_check.dart.
  printf '<!-- dpip-build: %s -->\n' "$code"
}
