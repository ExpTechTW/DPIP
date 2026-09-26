#!/usr/bin/env bash
# Generated Widget township resources must match the authoritative Dart assets.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

python3 tool/gen/widget_township_resources.py --check
