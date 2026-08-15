#!/usr/bin/env bash
#
# Storage gate — two rules about where persisted data may be touched.
#
# 1. `SharedPreferences` is gone — package and all. Settings live in SQLite,
#    reached through the typed `SettingsStore` facade, whose methods take a
#    `SettingKey` and never a raw `String`, so an ad-hoc key cannot reach
#    storage. Nothing may import the package; it is not a dependency.
#
# 2. `sqflite` is opened and schema'd only by the stores that own a table, plus
#    bootstrap (which mints the handles). A feature reaching for a Database
#    would be a feature able to drop somebody else's table — which is exactly
#    what "clearing the cache must not delete anything else" is about.
#
# Sibling to tool/check_layering.sh / check_l10n.sh; zero new packages.
# See CLAUDE.md → Conventions.
set -euo pipefail
cd "$(dirname "$0")/.."

sqflite_allow='lib/bootstrap.dart
lib/core/settings/settings_store.dart
lib/core/storage/app_database.dart
lib/core/astro/tle_store.dart
lib/core/meshtastic/data/mesh_store.dart
lib/core/network/etag_cache_store.dart
lib/core/network/network_usage_store.dart'

fail=0
while IFS= read -r file; do
  # Match import AND export (a re-export re-exposes the API just as well), any
  # quote style, and the whole shared_preferences* family — the platform
  # interface / platform impls drive the SAME native store, so no trailing '/'.
  if grep -qE "(import|export)[[:space:]]+['\"]package:shared_preferences" "$file"; then
    echo "  ✗ $file reaches shared_preferences — settings live in SQLite;"
    echo "    use SettingsStore (lib/core/settings/settings_store.dart)"
    fail=1
  fi
  if grep -qE "(import|export)[[:space:]]+['\"]package:sqflite" "$file"; then
    case "
$sqflite_allow
" in
      *"
$file
"*) ;;
      *)
        echo "  ✗ $file opens sqflite directly — go through the store that owns"
        echo "    the table (see lib/core/storage/app_database.dart)"
        fail=1
        ;;
    esac
  fi
done < <(find lib -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' | sort)

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "Storage gate failed — route persistence through the store that owns it."
  exit 1
fi
echo "Storage gate OK — settings via SettingsStore; SQLite only in its stores."
