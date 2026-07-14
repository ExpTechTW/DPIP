#!/usr/bin/env bash
#
# Prefs gate — SharedPreferences may only be touched through the typed `Prefs`
# facade (lib/core/settings/prefs.dart). Only that file (which wraps it) and
# bootstrap.dart (which mints the single instance) may import the package;
# everywhere else must depend on `Prefs`, so an ad-hoc raw-string key can't reach
# storage. Sibling to tool/check_layering.sh / check_l10n.sh; zero new packages.
# See CLAUDE.md → Conventions.
set -euo pipefail
cd "$(dirname "$0")/.."

allow='lib/core/settings/prefs.dart lib/bootstrap.dart'
fail=0
while IFS= read -r file; do
  case " $allow " in *" $file "*) continue ;; esac
  # Match import AND export (a re-export re-exposes the API just as well), any
  # quote style, and the whole shared_preferences* family — the platform
  # interface / platform impls (shared_preferences_platform_interface, …) drive
  # the SAME native store, so no trailing '/' anchor. prefs.dart legitimately
  # imports the base package but is allowlisted above.
  if grep -qE "(import|export)[[:space:]]+['\"]package:shared_preferences" "$file"; then
    echo "  ✗ $file reaches shared_preferences directly — use Prefs (lib/core/settings/prefs.dart)"
    fail=1
  fi
done < <(find lib -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' | sort)

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "Prefs gate failed — route persistence through the Prefs facade."
  exit 1
fi
echo "Prefs gate OK — SharedPreferences is only touched via Prefs."
