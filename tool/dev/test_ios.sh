#!/usr/bin/env bash
# The Swift test suite — ios/RunnerTests, on a simulator.
#
#     tool/dev/test_ios.sh                     # the whole suite
#     tool/dev/test_ios.sh -only-testing:RunnerTests/ForecastWidgetTests
#
# Arguments are passed straight to `xcodebuild test`.
#
# tool/dev/test.sh cannot see any of this. The widget extension, the App Group
# snapshot storage and the WidgetKit timeline are Swift, their tests are
# XCTest, and until this script existed nothing ran them — not the checklist,
# not CI. A Swift test that nobody runs is indistinguishable from one that
# passes, and the suite had a case asserting a defect as if it were the
# contract.
#
# macOS and Xcode only; there is no cross-platform way to run this.
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"

if [[ $OSTYPE != darwin* ]]; then
  printf '\n  tool/dev/test_ios.sh needs macOS and Xcode.\n\n' >&2
  exit 1
fi

if ! xcrun --find xcodebuild >/dev/null 2>&1; then
  cat >&2 <<'EOF'

  No xcodebuild. Install Xcode (not just the Command Line Tools) and point
  xcode-select at it:

      sudo xcode-select -s /Applications/Xcode.app

EOF
  exit 1
fi

# A concrete simulator, because `xcodebuild test` cannot run against a generic
# destination. Resolved rather than named: a hardcoded "iPhone 16" is a device
# that exists on the machine it was written on and on no runner a year later,
# and the failure it produces names the destination rather than the cause.
#
# DPIP_IOS_SIMULATOR overrides with a name or a UDID, for testing an iPad
# layout or a specific OS version.
destination="${DPIP_IOS_SIMULATOR:-}"
if [[ -n $destination ]]; then
  if [[ $destination =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]]; then
    destination="platform=iOS Simulator,id=$destination"
  else
    # A name alone makes xcodebuild assume OS=latest, even when that device
    # exists only on an older installed runtime. Resolve its actual UDID.
    udid="$(xcrun simctl list devices available --json | python3 -c '
import json
import sys

devices = [
    device
    for runtime in json.load(sys.stdin)["devices"].values()
    for device in runtime
    if device["name"] == sys.argv[1]
]
booted = next((device for device in devices if device["state"] == "Booted"), None)
print((booted or devices[0])["udid"] if devices else "")
' "$destination")"
    if [[ -z $udid ]]; then
      printf '\n  No available iOS simulator named %s.\n\n' "$destination" >&2
      exit 1
    fi
    destination="platform=iOS Simulator,id=$udid"
  fi
else
  # `    iPhone 17 Pro (UDID) (Shutdown)` — the parenthesised field is the UDID.
  udid="$(xcrun simctl list devices available |
    awk -F '[()]' '/^ *iPhone /{ gsub(/ /, "", $2); print $2; exit }')"
  if [[ -z $udid ]]; then
    cat >&2 <<'EOF'

  No iPhone simulator is available. Xcode installs one with a platform:

      xcodebuild -downloadPlatform iOS

  Or name one yourself: DPIP_IOS_SIMULATOR='iPhone 17' tool/dev/test_ios.sh

EOF
    exit 1
  fi
  destination="id=$udid"
fi

# Generated.xcconfig and the Flutter framework the Runner target links against.
# xcodebuild has no idea how to produce either, and without them it fails on a
# missing include long before it reaches a test.
#
# DPIP_RUN_SH for the same reason tool/run.sh passes it: RunnerTests is hosted
# *in* the Runner app, so every test launches it, and a debug build that was
# not started through a tool script calls exit(1) from bootstrap before Flutter
# is up (lib/bootstrap.dart, _refuseUnlessLaunchedByTool). xcodebuild reports
# that as "the test runner exited with code 1 before establishing connection",
# which names neither the guard nor the app — so without this the whole suite
# fails on something no test wrote. The premise the guard protects holds here:
# this is a tool script and the SDK below is the pinned one.
step "Configuring the iOS project for the simulator"
pinned flutter build ios --simulator --debug --config-only \
  --dart-define=DPIP_RUN_SH=true

# The shared Runner scheme, which lists RunnerTests as its testable and depends
# on DPIPWidgetsExtension — so this compiles the widget target too, including
# the SwiftUI views that no other check reaches.
step "Running ios/RunnerTests on $destination"
xcodebuild test \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -destination "$destination" \
  -clonedSourcePackagesDirPath build/ios/SourcePackages \
  CODE_SIGNING_ALLOWED=NO \
  -quiet \
  "$@"
