#!/usr/bin/env bash
# Run the isolated production-widget fixture and its XCUI tests.
# DPIP_IOS_SIMULATOR must be a simulator UDID; extra arguments go to xcodebuild.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"
cd "$(repo_root)"
: "${DPIP_IOS_SIMULATOR:?Set DPIP_IOS_SIMULATOR to an iOS simulator UDID}"
xcodebuild test -project ios/Runner.xcodeproj -scheme WidgetFixture \
  -destination "platform=iOS Simulator,id=$DPIP_IOS_SIMULATOR" \
  CODE_SIGNING_ALLOWED=NO "$@"
