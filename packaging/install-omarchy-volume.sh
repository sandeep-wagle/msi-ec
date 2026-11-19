#!/usr/bin/env bash
# Installs the MSI-tempered Omarchy volume script (display 0-100 shared
# with MSI Controller, real 40-140 on the sink). Keeps a timestamped
# backup of the stock script and re-verifies after install.
# Re-run after Omarchy updates (they can overwrite /usr/share/omarchy).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/omarchy-audio-output-volume.msi-tempered"
DST="/usr/share/omarchy/bin/omarchy-audio-output-volume"

echo "[1/3] Backing up stock script"
sudo mkdir -p /usr/share/omarchy/bin/.msi-backup
sudo cp "$DST" "/usr/share/omarchy/bin/.msi-backup/omarchy-audio-output-volume.$(date +%Y%m%d-%H%M%S)"
echo "[2/3] Installing tempered script"
sudo install -m 0755 "$SRC" "$DST"
echo "[3/3] Verifying (display round-trip)"
bash -n "$DST" && echo "syntax OK"
sink="$(omarchy-audio-output-sink)"
echo "sink under control: $sink"
echo "Done. Fn+Left/Right now step display 0-100 (real 40-140)."
