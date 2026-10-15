#!/usr/bin/env bash
# A third-party binary at a pinned release, verified before anything runs it.
#
#     tool/internal/pinned_tool.sh actionlint     # prints the binary's path
#     tool/internal/pinned_tool.sh zizmor
#
# For tools that are not the app's toolchain and so do not belong in
# mise.toml: mise-action installs everything that file lists in every workflow
# that uses it, the release job included, and a linter has no business on the
# runner that holds the store signing keys.
#
# What this replaces is `bash <(curl …/actionlint/main/scripts/…)`: a script
# fetched from a branch and executed as it arrived, so whoever could push to
# that branch could run anything on the runner, and nothing recorded which
# version had linted what. Here the release is named and the archive's SHA-256
# is written down, and an archive that does not match is refused before it is
# unpacked.
#
# The checksums are the ones the project publishes with the release, which
# GitHub also shows as each asset's digest. To move a pin, change the version
# and replace every checksum for that tool from the new release. A version
# whose checksums were not replaced fails here; it never runs unverified.
#
# Downloaded once into the git directory, beside the gate cache in
# dev/_lib.sh and for the same reasons — nothing has to gitignore it and
# `flutter clean` cannot reach it — in a directory named by the checksum, so a
# changed pin can never pick up the previous binary.
source "$(dirname "${BASH_SOURCE[0]}")/../dev/_lib.sh"
cd "$(repo_root)"

readonly ACTIONLINT=1.7.12
readonly ZIZMOR=1.30.1

tool="${1:-}"
case "$tool" in
actionlint)
  version=$ACTIONLINT
  base="https://github.com/rhysd/actionlint/releases/download/v$ACTIONLINT"
  ;;
zizmor)
  version=$ZIZMOR
  base="https://github.com/zizmorcore/zizmor/releases/download/v$ZIZMOR"
  ;;
*)
  printf 'usage: tool/internal/pinned_tool.sh <actionlint|zizmor>\n' >&2
  exit 2
  ;;
esac

case "$(uname -s)/$(uname -m)" in
Darwin/arm64) platform=darwin-arm64 ;;
Darwin/x86_64) platform=darwin-x64 ;;
Linux/x86_64) platform=linux-x64 ;;
Linux/aarch64 | Linux/arm64) platform=linux-arm64 ;;
*) platform="$(uname -s)/$(uname -m)" ;;
esac

# <archive> <sha256>, per tool and platform.
case "$tool/$platform" in
actionlint/darwin-arm64) pin="actionlint_${ACTIONLINT}_darwin_arm64.tar.gz aba9ced2dee8d27fecca3dc7feb1a7f9a52caefa1eb46f3271ea66b6e0e6953f" ;;
actionlint/darwin-x64) pin="actionlint_${ACTIONLINT}_darwin_amd64.tar.gz 5b44c3bc2255115c9b69e30efc0fecdf498fdb63c5d58e17084fd5f16324c644" ;;
actionlint/linux-x64) pin="actionlint_${ACTIONLINT}_linux_amd64.tar.gz 8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8" ;;
actionlint/linux-arm64) pin="actionlint_${ACTIONLINT}_linux_arm64.tar.gz 325e971b6ba9bfa504672e29be93c24981eeb1c07576d730e9f7c8805afff0c6" ;;
zizmor/darwin-arm64) pin="zizmor-aarch64-apple-darwin.tar.gz e28d22b087f9ebb8d99da6e740d348c930f559961c7c3f12badda54f882195a2" ;;
zizmor/darwin-x64) pin="zizmor-x86_64-apple-darwin.tar.gz 10e6b18b11ea07e515a16f0f0518c7b07527bc9977c1fd5698181ce7f3554202" ;;
zizmor/linux-x64) pin="zizmor-x86_64-unknown-linux-gnu.tar.gz e65324f4430c2717591937edcec90ccbefaf14c174f8ec9415e03ca875b46e1a" ;;
zizmor/linux-arm64) pin="zizmor-aarch64-unknown-linux-gnu.tar.gz 7ff1dce33bdd18fd2a4affe63bdd47efcccca97b2cec1c1863ec26e9e2647540" ;;
*)
  # A failure, not a skip. The gates that call this are in tool/check.sh, and
  # a gate that quietly does not run turns "green here means green in CI" into
  # a claim nobody checked.
  printf '\n  No pinned %s for %s. Add the release asset and its checksum\n' "$tool" "$platform" >&2
  printf '  to tool/internal/pinned_tool.sh, or let CI run this gate.\n\n' >&2
  exit 1
  ;;
esac
archive="${pin%% *}"
sum="${pin##* }"

store="$(cd "$(git rev-parse --git-dir)" && pwd)/dpip-tools/$tool-${sum:0:16}"
bin="$store/$tool"
if [[ -x $bin ]]; then
  printf '%s\n' "$bin"
  exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

printf '  fetching %s %s (%s) — once per clone\n' "$tool" "$version" "$platform" >&2
if ! curl -fsSL --retry 3 --max-time 300 -o "$tmp/$archive" "$base/$archive"; then
  printf '\n  Could not download %s from %s.\n' "$archive" "$base" >&2
  printf '  It is fetched once and kept in the git directory; re-run when online.\n\n' >&2
  exit 1
fi

actual="$(shasum -a 256 "$tmp/$archive" | cut -d' ' -f1)"
if [[ $actual != "$sum" ]]; then
  printf '\n  %s does not match its pinned checksum — refusing to run it.\n' "$archive" >&2
  printf '    expected %s\n    got      %s\n\n' "$sum" "$actual" >&2
  exit 1
fi

tar -xzf "$tmp/$archive" -C "$tmp" "$tool"
mkdir -p "$store"
# Into the store's own directory first, then renamed: a rename within one
# directory is atomic, so a second run can never find half a binary.
mv "$tmp/$tool" "$store/.$tool.$$"
chmod +x "$store/.$tool.$$"
mv -f "$store/.$tool.$$" "$bin"
printf '%s\n' "$bin"
