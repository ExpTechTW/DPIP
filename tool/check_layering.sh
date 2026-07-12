#!/usr/bin/env bash
#
# Layering gate — enforces the architecture rules from CLAUDE.md without needing
# a build or `pub get`, so it fails fast in CI and can be run locally any time.
#
# Rules (see CLAUDE.md → Conventions → Architecture):
#   1. lib/core and lib/shared must NOT import features.
#   2. presentation must NOT import any feature's data layer (depend on domain).
#   3. a feature must NOT import another feature's data or presentation
#      (cross-feature coupling goes through shared/ or a domain interface).
#
# Usage:  tool/check_layering.sh   (run from the repo root)
set -euo pipefail

cd "$(dirname "$0")/.."

fail=0
report() {
  echo "  ✗ $1"
  fail=1
}

# All first-party source, excluding generated code.
while IFS= read -r file; do
  imports=$(grep -oE "import 'package:dpip/[^']+'" "$file" \
    | sed -E "s|import 'package:dpip/([^']+)'|\1|") || true
  [ -z "$imports" ] && continue

  case "$file" in
    lib/core/* | lib/shared/*)
      while IFS= read -r imp; do
        [ -z "$imp" ] && continue
        case "$imp" in
          features/*)
            report "$file → $imp (core/shared must not import features)"
            ;;
        esac
      done <<< "$imports"
      ;;

    lib/features/*)
      self=$(printf '%s' "$file" | sed -E 's|lib/features/([^/]+)/.*|\1|')
      case "$file" in
        *"/presentation/"*) in_pres=1 ;;
        *) in_pres=0 ;;
      esac
      while IFS= read -r imp; do
        [ -z "$imp" ] && continue
        case "$imp" in
          features/*)
            other=$(printf '%s' "$imp" | sed -E 's|features/([^/]+)/.*|\1|')
            layer=$(printf '%s' "$imp" | sed -E 's|features/[^/]+/([^/]+)/.*|\1|')
            if [ "$other" != "$self" ]; then
              case "$layer" in
                data | presentation)
                  report "$file → $imp (cross-feature import of $other/$layer)"
                  ;;
              esac
            fi
            if [ "$in_pres" = "1" ] && [ "$layer" = "data" ]; then
              report "$file → $imp (presentation must depend on domain, not data)"
            fi
            ;;
        esac
      done <<< "$imports"
      ;;
  esac
done < <(find lib -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' | sort)

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "Layering violations found — see CLAUDE.md → Conventions → Architecture."
  exit 1
fi

echo "Layering OK — no violations."
