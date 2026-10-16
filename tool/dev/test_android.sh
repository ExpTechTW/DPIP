#!/usr/bin/env bash
# The Kotlin test suite — android/app/src/test, on the JVM.
#
#     tool/dev/test_android.sh                          # everything
#     tool/dev/test_android.sh --tests 'com.exptech.dpip.widget.*'
#
# tool/dev/test.sh cannot see any of this. The home-screen Widget's policy is
# Kotlin, its tests are JUnit, and no Flutter test compiles a line of it — so
# without this script a Kotlin test is indistinguishable from one that passes.
# CI runs it from android.yml; see AGENTS.md.
#
# Arguments are passed straight to Gradle's `:app:testDebugUnitTest`.
#
# The pinned Flutter SDK is required first, through `require_mise`: it is what
# writes the Gradle wrapper and android/local.properties below, and the build
# reads `flutter.sdk` from the latter — a run started outside the pin would
# compile the app module against an SDK nobody chose, the exact failure this
# repository's toolchain gate exists to catch. Gradle itself is not a mise
# tool, so the Gradle call is direct rather than through `pinned`.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

require_mise

# android/gradlew and android/local.properties: no checkout has either before
# its first Flutter build, because both are gitignored and the Flutter tool
# writes them out of its own cache the first time it runs Gradle in a Flutter
# project (`GradleUtils.getExecutable`). Every CI runner is such a checkout,
# which is where the two Android jobs failed on the missing wrapper.
# `--config-only` produces them and returns before any Gradle task starts —
# the Android mirror of test_ios.sh's `flutter build ios --config-only`.
step "Configuring the Android project for Gradle"
pinned flutter build apk --config-only

exec android/gradlew -p android :app:testDebugUnitTest "$@"
