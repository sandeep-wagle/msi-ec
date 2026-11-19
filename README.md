# msi_controller_linux

MSI Embedded Controller driver + Linux controller app.

## MSI-EC Kernel Driver

This directory contains the [msi-ec](https://github.com/BeardOverflow/msi-ec) Embedded Controller driver for MSI laptops, with ACPI battery hook compatibility fixes for Omarchy/kernels >= 6.2.

The driver registers a platform device at `/sys/devices/platform/msi-ec` and provides:
- Battery charge thresholds
- Webcam control
- Function key / Windows key swap
- Cooler boost
- Shift modes (eco, comfort, sport, turbo)
- Fan modes (auto, silent, basic, advanced)
- CPU/GPU temperature and fan speed monitoring
- LED control (mute, micmute, keyboard backlight)

See the original [msi-ec documentation](https://github.com/BeardOverflow/msi-ec) for full usage details.

### ACPI Battery Hook Fix

This fork adds compatibility macros (`msi_ec_battery_hook_register/unregister` and `msi_ec_battery_hook` typedef) so the driver compiles on both:
- Older kernels using `battery_hook_*` / `struct battery_hook`
- Omarchy / kernels >= 6.2 using `acpi_battery_hook_*` / `struct acpi_battery_hook`

The Makefile auto-detects the header variant and sets `-DMSI_EC_ACPI_BATTERY_HOOK` accordingly.

## Flutter App

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if you are new to Flutter:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
