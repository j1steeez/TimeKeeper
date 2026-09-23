#!/usr/bin/env bash
# Mirror root Resources/SeedPhotos into the SPM Core target resources folder.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/Resources/SeedPhotos"
DST="$ROOT/Sources/TimeKeeperCore/Resources/SeedPhotos"
mkdir -p "$(dirname "$DST")"
rsync -a --delete "$SRC/" "$DST/"
echo "Synced seed photos → Sources/TimeKeeperCore/Resources/SeedPhotos"
ls -1 "$DST"
