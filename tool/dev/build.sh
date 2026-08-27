#!/usr/bin/env bash
# A release build, for the platform named first.
#
#     tool/dev/build.sh android      # APK  → build/app/outputs/flutter-apk/
#     tool/dev/build.sh android-debug   # debug-signed APK, installable over run.sh
#     tool/dev/build.sh bundle       # AAB  → what Play actually takes
#     tool/dev/build.sh ios          # unsigned, for a local check
#
# Any further arguments go to `flutter build` untouched, which is how the
# release workflow passes its `--dart-define`s. The release build and a local
# one therefore run the same command — the alternative is a build that only
# fails on a tag.
#
# iOS is always `--no-codesign` here, so this script cannot create a
# certificate: the pinned SDK adds `-allowProvisioningUpdates` only when
# codesigning is on, and otherwise forces CODE_SIGNING_ALLOWED=NO.
#
# Signing on a developer's machine and signing in the release workflow are
# different problems, and the workflow drives xcodebuild itself for the second
# one — see .github/workflows/release.yml, and tool/release/ios_keychain.sh for
# why the runner has to be handed a development identity before it starts.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

target="${1:-}"
shift || true

# A debug-signed APK, for installing over a `tool/run.sh` build.
#
# Release and debug are signed with different keys, so `adb install -r` refuses
# to replace one with the other — and uninstalling to get around it takes the
# app's permissions, settings and databases with it. Without this an agent (or
# anyone iterating on native code) has to hand every build back to a human to
# install, which is exactly how three rounds of shader fixes reached nobody.
case "$target" in
  android)       pinned flutter build apk --release "$@" ;;
  android-debug) pinned flutter build apk --debug "$@" ;;
  bundle)  pinned flutter build appbundle --release "$@" ;;
  # No --release: `flutter build ios` is release by default, and hardcoding it
  # would fight the `--debug` the iOS smoke-test build passes.
  ios)     pinned flutter build ios --no-codesign "$@" ;;
  *)
    printf 'usage: tool/dev/build.sh {android|android-debug|bundle|ios} [flutter build args]\n' >&2
    exit 2
    ;;
esac
