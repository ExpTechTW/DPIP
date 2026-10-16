#!/usr/bin/env bash
# The Widget's on-device tests — android/app/src/androidTest, on a real device.
#
#     tool/dev/test_android_device.sh
#     tool/dev/test_android_device.sh --tests '*WidgetOnDeviceTest*'
#
# `tool/dev/test_android.sh` runs the JVM suite, which covers the policy and —
# through Robolectric — the layouts and the store against a simulated framework.
# Three things it cannot do, and which this runs against the real ones: inflate a
# `RemoteViews` through the platform's own inflater, read `AppWidgetProviderInfo`
# the way a launcher does, and open the device's SQLite.
#
# **A device is required** — a USB device or a running emulator visible to `adb`.
# There is no emulator on a development laptop by default, which is why this is a
# separate script and not part of `tool/dev/test_android.sh`: a JVM run must stay
# runnable everywhere. CI runs it from android.yml on an emulator.
#
# Arguments are passed straight to Gradle's `:app:connectedDebugAndroidTest`.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

require_mise

if ! command -v adb >/dev/null 2>&1; then
  cat >&2 <<'EOF'

  No adb on PATH. Android instrumentation needs a device or a running emulator,
  and without one this would fail with a message about a missing device rather
  than about the tooling. Point ANDROID_HOME at an SDK with platform-tools, or
  start an emulator.

EOF
  exit 1
fi

if [[ -z $(adb devices | awk 'NR>1 && $2 == "device"') ]]; then
  cat >&2 <<'EOF'

  No device or emulator is attached (`adb devices` shows none in the "device"
  state). Start one, or run the JVM suite instead:

      tool/dev/test_android.sh

EOF
  exit 1
fi

# The wrapper and android/local.properties the Gradle call below needs, written
# the way tool/dev/test_android.sh writes them. After the device checks, so a
# run with nothing attached still fails without doing this first.
step "Configuring the Android project for Gradle"
pinned flutter build apk --config-only

exec android/gradlew -p android :app:connectedDebugAndroidTest "$@"
