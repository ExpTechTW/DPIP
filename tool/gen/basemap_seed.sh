#!/usr/bin/env bash
# Rebuilds the basemap tiles the app carries for a launch with no network.
#
#     tool/gen/basemap_seed.sh
#
# Downloads them from the origin, packs them into assets/map/basemap_seed/ and
# writes the index lib/shared/map/basemap_seed.g.dart — see the header of
# tool/gen/basemap_seed.dart for what is fetched and why. Commit all three; a
# changed tile set gets a new version, and installed copies reseed from it.
source "$(dirname "${BASH_SOURCE[0]}")/../dev/_lib.sh"
cd "$(repo_root)"

pinned dart run tool/gen/basemap_seed.dart
pinned dart format lib/shared/map/basemap_seed.g.dart
