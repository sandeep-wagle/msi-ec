# MSI Controller — Installation

One command sets up everything (safe to re-run; every step is idempotent):

```bash
cd ~/Development/apps/flutter/apps/msi_controller
./packaging/install-all.sh
```

You will type your `sudo` password a few times **during install only**.
The app itself never prompts afterwards.

## What gets installed, in order

| # | Step | Script / source | Needs sudo | Skip condition |
|---|------|-----------------|------------|----------------|
| 1 | msi-ec EC driver (DKMS) for Cooler Boost, shift/fan modes, Win/Fn swap, battery thresholds | upstream `BeardOverflow/msi-ec` into `~/Development/drivers/msi-ec` | yes (dkms-install) | `/sys/devices/platform/msi-ec` already exists |
| 2 | udev permissions, EC module persistence, passwordless sudoers fallback | `packaging/install.sh` | yes | — |
| 3 | Tempered system volume keys (display 0–100 shared with the app, real 0–150 on the sink) | `packaging/install-omarchy-volume.sh` | yes | — |
| 4 | DSP service binary (`cargo build --release`) | `msi_dsp_service/` | no | prebuilt binary present |
| 5 | `msi-dsp.service` user unit — PipeWire audio processing that runs **without the app open** | `packaging/msi-dsp.service` | no | — |
| 6 | End-to-end verification of EC device, DSP socket, default sink, chain state, speaker level, sudo fallback | — | no | — |

## Manual prerequisites (only if a step reports them missing)

- **Rust toolchain** (step 4): `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
- **Kernel headers + build tools** (step 1): `sudo pacman -S --needed base-devel linux-headers dkms git`
- **Full-range DSP stages** (surround/compressor/limiter): `sudo pacman -S --needed swh-plugins`
  (without it the service runs a builtin-only graph with honest degradation)

## After Omarchy updates

Re-run `./packaging/install-omarchy-volume.sh` — system updates can
overwrite `/usr/share/omarchy/bin/omarchy-audio-output-volume`.

## What runs at boot / login (no app needed)

- `msi-ec` kernel module (via `/etc/modules-load.d/msi-ec.conf`)
- `msi-dsp.service` user unit (enabled): filter graph, default sink,
  link watchdog, volume restore, speaker pin
