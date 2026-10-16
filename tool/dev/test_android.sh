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
# The pinned Flutter SDK is still required first, through `require_mise`, even
# though the toolchain command itself is Gradle: the Android build reads
# `flutter.sdk` from android/local.properties, so a run started outside the pin
# would compile the app module against an SDK nobody chose — the exact failure
# this repository's toolchain gate exists to catch. Gradle is not a mise tool,
# so it is invoked directly rather than through `pinned`.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

require_mise

if [[ ! -x android/gradlew ]]; then
  cat >&2 <<'EOF'

  android/gradlew is missing, so there is nothing to run the tests with.

EOF
  exit 1
fi

exec android/gradlew -p android :app:testDebugUnitTest "$@"
