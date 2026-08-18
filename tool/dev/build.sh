#!/usr/bin/env bash
# A release build, for the platform named first.
#
#     tool/dev/build.sh android      # APK  → build/app/outputs/flutter-apk/
#     tool/dev/build.sh bundle       # AAB  → what Play actually takes
#     tool/dev/build.sh ios          # unsigned, for a local check
#
# Any further arguments go to `flutter build` untouched, which is how the
# release workflow passes its `--dart-define`s. The release build and a local
# one therefore run the same command — the alternative is a build that only
# fails on a tag.
#
# iOS is always `--no-codesign` here. Signing on a developer's machine and
# signing in the release workflow are different problems, and the workflow
# drives xcodebuild itself for the second one (see .github/workflows/release.yml).
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

target="${1:-}"
shift || true

case "$target" in
  android) pinned flutter build apk --release "$@" ;;
  bundle)  pinned flutter build appbundle --release "$@" ;;
  ios)     pinned flutter build ios --release --no-codesign "$@" ;;
  *)
    printf 'usage: tool/dev/build.sh {android|bundle|ios} [flutter build args]\n' >&2
    exit 2
    ;;
esac
