#!/usr/bin/env bash
# Android lint for the app module.
#
#     tool/dev/lint_android.sh
#
# Lint reads the merged manifest and resources, not just the source, so it sees
# things the unit tests cannot: a receiver declared without `exported`, an
# attribute that needs a higher API than `minSdk`, a permission the Widget uses
# but does not declare. It is the only check here that would have caught a
# `widgetFeatures` typo, because a typo in an XML attribute is not a compile
# error.
#
# The baseline (`android/app/lint-baseline.xml`) records what was already
# failing before the Widget existed — a `NewApi` call in the location reporter —
# so this fails on anything *new*. Run `./gradlew updateLintBaseline` from
# android/ to re-record deliberately.
#
# Arguments are passed straight to Gradle's `:app:lintDebug`.
#
# The pinned Flutter SDK is required first, through `require_mise`, for the same
# reason `tool/dev/test_android.sh` needs it: the Android build reads
# `flutter.sdk` from android/local.properties, so a run outside the pin compiles
# against an SDK nobody chose.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

require_mise

# The wrapper and android/local.properties the Gradle call below needs, written
# the way tool/dev/test_android.sh writes them — and just as missing on a
# checkout that has never built.
step "Configuring the Android project for Gradle"
pinned flutter build apk --config-only

exec android/gradlew -p android :app:lintDebug "$@"
