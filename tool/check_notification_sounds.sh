#!/usr/bin/env bash
#
# Notification-sound gate — every `resource://raw/<name>` a channel declares
# must exist as a real file on both platforms.
#
# awesome_notifications validates channels natively and rejects one whose sound
# it cannot resolve. A missing file is therefore not a silent fallback to the
# default tone: the channel fails to register, and for an alerting app that
# means an alert category that never fires. The failure also only appears at
# runtime on a device, long after the commit that caused it — so it is checked
# here, where a missing file is one line of output instead of a field report.
#
# Android resolves `resource://raw/x` against `res/raw/x.*`; iOS resolves the
# same string against a file in the app bundle. Both are checked.
#
# Sibling to tool/check_layering.sh / check_storage.sh; zero new packages.
set -euo pipefail
cd "$(dirname "$0")/.."

channels='lib/core/notifications/notification_channels.dart'
android_raw='android/app/src/main/res/raw'
ios_dir='ios/Runner'

fail=0
sounds=$(grep -oE "resource://raw/[A-Za-z0-9_]+" "$channels" | sed 's|resource://raw/||' | sort -u)

for name in $sounds; do
  if ! compgen -G "$android_raw/$name.*" > /dev/null; then
    echo "  ✗ android: $android_raw/$name.* missing (declared by a channel)"
    fail=1
  fi
  if ! compgen -G "$ios_dir/$name.*" > /dev/null \
     && ! grep -q "$name\." ios/Runner.xcodeproj/project.pbxproj 2>/dev/null; then
    echo "  ✗ ios: no bundled sound named '$name' (declared by a channel)"
    fail=1
  fi
done

# Android is strict about resource names: lowercase letters, digits and
# underscore only, and it must not start with a digit. A file that breaks the
# rule is silently dropped from the build rather than reported.
while IFS= read -r file; do
  base=$(basename "$file"); base="${base%.*}"
  if ! printf '%s' "$base" | grep -qE '^[a-z][a-z0-9_]*$'; then
    echo "  ✗ android: res/raw/$base is not a legal resource name"
    fail=1
  fi
done < <(find "$android_raw" -type f 2>/dev/null)

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "Notification-sound gate failed — a channel would be rejected at runtime."
  exit 1
fi
echo "Notification-sound gate OK — every channel sound resolves on both platforms."
