#!/usr/bin/env bash
# MSI Center Linux — SINGLE one-shot installer. Run once (sudo password
# asked a few times, never again by the app itself):
#
#   ./packaging/install-all.sh
#
# What it sets up, in order (every step is idempotent — safe to re-run):
#   [1] msi-ec EC driver via DKMS (MSI laptops only; skipped when the
#       /sys device already exists). Needed for Cooler Boost, shift
#       modes, fan modes, Win/Fn swap.
#   [2] packaging/install.sh — udev permissions, EC module persistence,
#       passwordless sudoers fallback.
#   [3] packaging/install-omarchy-volume.sh — tempered system volume keys
#       (display 0-100 shared with the app, real 40-140 on the sink).
#   [4] DSP service binary build (only if Rust is installed).
#   [5] msi-dsp.service user unit — PipeWire audio processing that runs
#       WITHOUT the app open (enable + start now).
#   [6] End-to-end verification of every layer.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRIVERS_DIR="$HOME/Development/drivers"
fail=0

step() { echo; echo "=== [$1] $2 ==="; }

step 1 "EC driver (msi-ec via DKMS)"
if [ -d /sys/devices/platform/msi-ec ]; then
  echo "OK: msi-ec device already present, skipping driver install."
else
  if [ ! -d "$DRIVERS_DIR/msi-ec" ]; then
    echo "Cloning upstream msi-ec driver..."
    mkdir -p "$DRIVERS_DIR"
    git clone --depth 1 https://github.com/BeardOverflow/msi-ec "$DRIVERS_DIR/msi-ec"
  fi
  if (cd "$DRIVERS_DIR/msi-ec" && sudo make dkms-install); then
    echo "DKMS install done. Loading with sibling-model firmware config..."
    sudo modprobe msi-ec firmware=16R6EMS1.103 || sudo modprobe msi-ec || true
  else
    echo "WARNING: DKMS install failed; continuing without EC control."
    fail=1
  fi
  if [ -d /sys/devices/platform/msi-ec ]; then
    echo "OK: /sys/devices/platform/msi-ec present."
  else
    echo "WARNING: no msi-ec device (model may need another firmware= config)."
    echo "Check: dmesg | grep -i msi-ec"
    fail=1
  fi
fi

step 2 "udev + sudoers (packaging/install.sh)"
bash "$REPO_DIR/packaging/install.sh" || fail=1

step 3 "Tempered system volume keys (packaging/install-omarchy-volume.sh)"
bash "$REPO_DIR/packaging/install-omarchy-volume.sh" || fail=1

step 4 "DSP service binary"
DSP_BIN="$REPO_DIR/msi_dsp_service/target/release/msi_dsp_service"
if [ -x "$DSP_BIN" ]; then
  echo "OK: prebuilt binary present: $DSP_BIN"
elif command -v cargo >/dev/null 2>&1; then
  echo "Building with cargo (takes a few minutes)..."
  (cd "$REPO_DIR/msi_dsp_service" && cargo build --release) || fail=1
else
  echo "NOTE: no prebuilt binary and no cargo; audio DSP unavailable."
  echo "Install Rust (rustup) and re-run this script."
  fail=1
fi
if [ -x "$DSP_BIN" ]; then
  mkdir -p ~/.local/bin
  cp "$DSP_BIN" ~/.local/bin/msi_dsp_service
  echo "Installed DSP binary to ~/.local/bin (stable unit path)."
fi

step 5 "msi-dsp.service user unit (audio without the app open)"
if [ -x "$DSP_BIN" ]; then
  mkdir -p ~/.config/systemd/user
  cp "$REPO_DIR/packaging/msi-dsp.service" ~/.config/systemd/user/msi-dsp.service
  systemctl --user daemon-reload
  systemctl --user enable --now msi-dsp.service
  sleep 2
  systemctl --user is-active msi-dsp.service || fail=1
else
  echo "SKIP: no DSP binary, unit not installed."
fi

step 6 "Verification"
echo "--- EC device: $([ -d /sys/devices/platform/msi-ec ] && echo PRESENT || echo MISSING)"
echo "--- DSP socket: $([ -S /tmp/msi_dsp.sock ] && echo LIVE || echo MISSING)"
echo "--- default sink: $(pactl get-default-sink 2>/dev/null || echo UNKNOWN)"
echo "--- chain input: $(pw-cli info msi_dsp_input 2>/dev/null | grep -m1 state: || echo MISSING)"
echo "--- speaker level: $(pactl get-sink-volume alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink 2>/dev/null | head -n 1 | grep -o '[0-9]*%' | head -n 1)"
echo "--- passwordless sudo: $(sudo -n true 2>/dev/null && echo ARMED || echo NOT-ARMED)"

if [ "$fail" -eq 0 ]; then
  echo
  echo "ALL GREEN. Restart the MSI Controller app; everything applies without password prompts."
else
  echo
  echo "DONE WITH WARNINGS (see lines above). Re-run after fixing them."
  exit 1
fi
