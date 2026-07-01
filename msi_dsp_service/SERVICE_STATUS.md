# MSI Controller Service Status Logs

This document contains historical service status logs and troubleshooting information for the MSI DSP system.

## PipeWire PulseAudio Status (captured 2026-03-10)
```text
● pipewire-pulse.service - PipeWire PulseAudio
     Loaded: loaded (/usr/local/lib/systemd/user/pipewire-pulse.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2026-03-10 15:49:50 +0545; 2h 20min ago
TriggeredBy: ● pipewire-pulse.socket
   Main PID: 1630 (pipewire-pulse)
      Tasks: 3 (limit: 18729)
     Memory: 7.9M
        CPU: 303ms
     CGroup: /user.slice/user-1000.slice/user@1000.service/session.slice/pipewire-pulse.service
             └─1630 /usr/local/bin/pipewire-pulse

Mar 10 15:49:50 sandy-GF63-Thin-11SC systemd[1618]: Started PipeWire PulseAudio.
Mar 10 15:49:50 sandy-GF63-Thin-11SC pipewire-pulse[1630]: pw.stream: media.class Audio/Sink does not expect Output stream direction
Mar 10 15:49:50 sandy-GF63-Thin-11SC pipewire-pulse[1630]: pw.node: 0x6031b5b77e10: can't add port 0x6031b5ba0750: -28, No space left on device
Mar 10 15:51:00 sandy-GF63-Thin-11SC pipewire-pulse[1630]: mod.protocol-pulse: [gsd-power] timeout on stream 0x6031b5e5ee30 channel:0
Mar 10 15:51:30 sandy-GF63-Thin-11SC pipewire-pulse[1630]: mod.protocol-pulse: [gsd-power] timeout on stream 0x6031b5f006e0 channel:1
Mar 10 15:51:51 sandy-GF63-Thin-11SC pipewire-pulse[1630]: mod.protocol-pulse: [GNOME Settings] timeout on stream 0x6031b5d95400 channel:0
Mar 10 15:52:18 sandy-GF63-Thin-11SC pipewire-pulse[1630]: mod.protocol-pulse: [gnome-control-center] timeout on stream 0x6031b5f44fb0 channel:0
Mar 10 16:52:14 sandy-GF63-Thin-11SC pipewire-pulse[1630]: mod.protocol-pulse: [gsd-power] timeout on stream 0x6031b60bb390 channel:1
Mar 10 16:57:13 sandy-GF63-Thin-11SC pipewire-pulse[1630]: mod.protocol-pulse: [Mutter] timeout on stream 0x6031b6cec070 channel:0
```

## WirePlumber Status (captured 2026-03-10)
```text
● wireplumber.service - Multimedia Service Session Manager
     Loaded: loaded (/usr/local/lib/systemd/user/wireplumber.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2026-03-10 15:49:50 +0545; 2h 23min ago
   Main PID: 1629 (wireplumber)
      Tasks: 5 (limit: 18729)
     Memory: 6.0M
        CPU: 349ms
     CGroup: /user.slice/user-1000.slice/user@1000.service/session.slice/wireplumber.service
             └─1629 /usr/local/bin/wireplumber

Mar 10 15:49:50 sandy-GF63-Thin-11SC systemd[1618]: Started Multimedia Service Session Manager.
Mar 10 15:49:50 sandy-GF63-Thin-11SC wireplumber[1629]: wp-device: SPA handle 'api.libcamera.enum.manager' could not be loaded; is it installed?
Mar 10 15:49:50 sandy-GF63-Thin-11SC wireplumber[1629]: s-monitors-libcamera: PipeWire's libcamera SPA plugin is missing or broken. Some camera types may not be supported.
Mar 10 15:49:50 sandy-GF63-Thin-11SC wireplumber[1629]: wp-device: SPA handle 'api.bluez5.enum.dbus' could not be loaded; is it installed?
Mar 10 15:49:50 sandy-GF63-Thin-11SC wireplumber[1629]: s-monitors: PipeWire's BlueZ SPA plugin is missing or broken. Bluetooth devices will not be supported.
Mar 10 15:49:50 sandy-GF63-Thin-11SC wireplumber[1629]: wp-device: SPA handle 'api.bluez5.midi.enum' could not be loaded; is it installed?
Mar 10 15:49:50 sandy-GF63-Thin-11SC wireplumber[1629]: s-monitors: PipeWire's BlueZ MIDI SPA missing or broken. Bluetooth not supported.
Mar 10 15:49:50 sandy-GF63-Thin-11SC wireplumber[1629]: pw.resource: can't create node: No such file or directory
Mar 10 15:49:50 sandy-GF63-Thin-11SC wireplumber[1629]: wp-node: failed to create node from factory 'spa-node-factory'
Mar 10 15:49:50 sandy-GF63-Thin-11SC wireplumber[1629]: s-monitors: Failed to create BLE MIDI server.
```

## Useful Commands
```bash
# Install WirePlumber
sudo apt install wireplumber

# Start PipeWire
systemctl --user start pipewire pipewire-pulse wireplumber
```
