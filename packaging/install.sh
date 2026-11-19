#!/usr/bin/env bash
# MSI Center Linux — one-shot passwordless setup (all distros).
# Usage: ./packaging/install.sh   (prompts for sudo ONCE, during install only —
# the app itself never prompts afterwards).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULE_SRC="$REPO_DIR/99-msi-ec.rules"
SUDOERS_SRC="$REPO_DIR/msi-center-sudoers"

echo "[1/3] Installing udev rule -> /etc/udev/rules.d/99-msi-ec.rules"
sudo install -m 0644 "$RULE_SRC" /etc/udev/rules.d/99-msi-ec.rules
if command -v udevadm >/dev/null 2>&1; then
  sudo udevadm control --reload-rules || true
  sudo udevadm trigger --subsystem-match=platform || true
fi

echo "[1b/3] Enabling msi-ec kernel module (MSI laptops only)"
if modinfo msi-ec >/dev/null 2>&1; then
  echo "msi-ec" | sudo tee /etc/modules-load.d/msi-ec.conf >/dev/null
  sudo modprobe msi-ec || true
  # Re-trigger AFTER the module creates the device, otherwise the rule never
  # sees it (this ordering bug left nodes root-locked on first setup).
  if command -v udevadm >/dev/null 2>&1; then
    sudo udevadm control --reload-rules || true
    sudo udevadm trigger --subsystem-match=platform || true
    sleep 1
  fi
  # Belt and suspenders: apply the bits directly too (udev RUN can race the
  # driver creating attributes; capital X keeps directories traversable).
  if [ -d /sys/devices/platform/msi-ec ]; then
    sudo chmod -R a+rwX /sys/devices/platform/msi-ec/ || true
  fi
  if [ -d /sys/devices/platform/msi-ec ]; then
    echo "OK: /sys/devices/platform/msi-ec present."
  else
    echo "WARNING: module loaded but no msi-ec device."
    echo "Your model may not be in this kernel's EC allowlist."
    echo "Check: dmesg | grep -i msi-ec"
  fi
else
  echo "NOTE: msi-ec module not found in this kernel; skipping."
  echo "Generic monitoring still works via hwmon fallbacks."
fi

echo "[2/3] Installing sudoers drop-in -> /etc/sudoers.d/msi-center"
sudo install -m 0440 "$SUDOERS_SRC" /etc/sudoers.d/msi-center
# Validate ONLY our file: a global `visudo -c` also trips over unrelated
# third-party drop-ins (e.g. stale files with bad permissions), which must
# not abort our setup. (sudo itself skips such files.)
sudo visudo -c -f /etc/sudoers.d/msi-center

echo "[3/3] Verifying (non-interactive, must not prompt)"
if sudo -n true 2>/dev/null; then
  echo "OK: passwordless sudo path available (fallback armed)."
else
  echo "NOTE: 'sudo -n true' still requires a password — direct udev writes"
  echo "will be used instead. If sysfs stays read-only, add your user to the"
  echo "sudo/wheel group and re-run this script."
fi
echo "Done. Restart the app; toggles/sliders apply without password prompts."
