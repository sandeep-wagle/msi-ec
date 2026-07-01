## Goal
- Fix audio DSP integration (PipeWire filter chain, virtual sink routing, profile effects) and finalize responsive/cute UI for the Features screen.

## Constraints & Preferences
- Build with `flutter analyze` 0 errors and `flutter build linux --release` passing
- Feature cards must be compact, visually "cute", responsive via Flutter layout tools
- All text colors must use theme tokens (AppColors), never hardcoded `Colors.white`
- No `backdropFilter`, `ImageFilter.blur`, or `dart:ui` blur effects anywhere
- DSP sink (`msi_dsp_sink`) must appear in system audio output settings
- Changing DSP profiles/effects in the app must produce audible changes
- Use `module-loopback` + `module-null-sink` (pulseaudio) instead of `pw-link` for reliable audio routing

## Progress
### Done
- **Features screen (cute redesign):**
  - Feature cards are compact with `childAspectRatio: 1.1` (square, not tall)
  - All hardcoded `Colors.white` replaced with `colors.textPrimary` / `colors.textSecondary`
  - Cute visual badges (version tags, CONFIGURE action badge)
  - Hover scale animation, proper overflow handling, responsive padding
- **GlassContainer/GlassCard cleanup:**
  - Removed all `dart:ui` blur + `BackdropFilter`
  - Removed `animationDelay` parameter (caused 19 build errors)
  - Fixed `msi_card.dart` — passed `animationDelay` to GlassCard in multiple files
- **Saved profile normalization:** Applied clamping/scaling in DSP service when saving new profiles
- **DSP audio routing fix (loopback, not pw-link):**
  - Root cause: `libpipewire-module-echo-cancel` failed because `aec/libspa-aec-webrtc` missing, and module had no `flags = [ ifexists nofail ]`, crashing the entire filter chain
  - Added `flags = [ ifexists nofail ]` to echo-cancel module in filter chain config template
  - Replaced broken `pw-link` routing with `module-loopback` + `module-null-sink` approach
  - Created virtual sink `msi_dsp_sink` (properly registered) — apps play to this
  - Created loopback `msi_dsp_sink.monitor` → `msi_dsp_input` (into filter chain DSP processing)
  - Created loopback `msi_dsp_input.monitor` → physical speaker (processed audio out)
  - Sets `msi_dsp_sink` as default audio sink — fixed to use `pw-metadata -n default` (pactl set-default-sink silently fails on PipeWire virtual sinks)
  - `msi_dsp_input` hidden from PulseAudio sinks (removed `media.class = "Audio/Sink"`) — only `msi_dsp_sink` appears in audio settings
  - Default sink description: "MSI DSP Output"
  - Virtual sink created via `pw-cli create-node adapter` (works with spaces in description)
  - Device monitor re-creates output loopback on audio device changes
  - `ensure_loopback_to_physical()` now unloads ALL stale loopbacks before creating new one (prevents duplicate accumulation from device monitor race)
  - Disable DSP unloads all loopbacks + destroys virtual sink + switches default back to physical speaker
- **C++ handler optimization:**
  - Changed `msi_handler.h` from `cargo run --release` to direct release binary launch
- **Rebuilt DSP service** (`cargo build --release`) successfully
- **Flutter app** builds and runs successfully with `flutter build linux --release`

### In Progress
- (none)

### Blocked
- (none)

## Key Decisions
- **Replaced `pw-link` with `module-loopback`** — PipeWire filter-chain nodes have `object.register = "false"` and cannot be set as default sink via `pactl set-default-sink`. Using `module-null-sink` creates a properly registered sink that works with PulseAudio default sink switching.
- **`pw-metadata -n default` over `pactl set-default-sink`** — `pactl set-default-sink` returns exit code 0 but silently fails to actually change the PipeWire default. Must use `pw-metadata -n default 0 'default.audio.sink' '{"name":"msi_dsp_sink"}'` to set the pipewire-pulse metadata store.
- **Added `nofail` flag to echo-cancel module** — the missing `aec/libspa-aec-webrtc` LADSPA plugin shouldn't crash the entire DSP filter chain.
- **Direct release binary in C++ handler** — `cargo run --release` requires full Rust toolchain on every app start; using the pre-built binary is instant.
- **Removed `animationDelay` from GlassCard/MsiSectionHeader/MsiProgressCard** — these one-shot entry animations added unnecessary overhead and didn't serve UX on Linux desktop.

## Next Steps
- Test DSP effects audibly: play audio, switch profiles in app, verify sound changes
- Handle headphones hotplug — device monitor should re-link loopback to new default sink
- Consider saving per-profile EQ data across app restarts (currently saved to `/tmp/msi_dsp_config/` which is ephemeral)
- Verify `msi_dsp_sink` default survives PipeWire restarts

## Critical Context
- `pw-link -o msi_dsp_output` returns NO output ports because filter-chain nodes have `object.register = "false"` and `node.virtual = "true"` — cannot be linked via pw-link
- `pactl set-default-sink msi_dsp_sink` returns success but doesn't change default — filter-chain Audio/Sink nodes are excluded from PulseAudio's default sink mechanism
- `pw-metadata -n default 0 'default.audio.sink' '{"name":"msi_dsp_sink"}'` is the correct command to set the default sink in PipeWire
- Echo-cancel module failure was the original silent bug: the config template lacked `flags = [ ifexists nofail ]` on the `libpipewire-module-echo-cancel` entry
- DSP service used `pw-link` for output routing; replaced with `module-loopback` from `msi_dsp_input.monitor` → physical sink
- Multiple stale `pw-filter-chain` processes can accumulate — `pkill -9 -f "pw-filter-chain.*msi_dsp"` is used during service restart
- DSP profiles and PipeWire filter chain config stored in `/tmp/msi_dsp_config/` (survives only until /tmp is cleaned or reboot)
- `.output()` on `Command::new("pw-loopback")` hangs indefinitely (long-lived process); must use `.spawn()` instead
- `flutter build linux --release` passes with 0 analyzer issues

## Relevant Files
- `linux/runner/msi_handler.h` — updated DSP service launch path (direct binary)
- `lib/screens/features_screen.dart` — responsive cute feature cards, theme-aware colors
- `lib/widgets/glass_container.dart` — solid containers only, no blur/animation
- `lib/widgets/msi_card.dart` — removed `animationDelay` from MsiSectionHeader/MsiProgressCard
- `msi_dsp_service/src/main.rs` — entire audio routing rewrite:
  - `generate_filter_chain_config()`: added `flags = [ ifexists nofail ]` to echo-cancel module
  - `ensure_virtual_sink()`: creates `msi_dsp_sink` null-sink (properly registered)
  - `ensure_loopback_to_dsp()`: loopback `msi_dsp_sink.monitor` → `msi_dsp_input`
  - `ensure_loopback_to_physical()`: loopback `msi_dsp_input.monitor` → physical speaker, unloads stale loopbacks first
  - `set_default_sink_to_dsp()`: sets `msi_dsp_sink` as default via `pw-metadata -n default`
  - `disable_dsp_switch_to_direct()`: unloads all loopbacks, restores physical default via `pw-metadata`
  - `kill_filter_chain()`: now also unloads all loopbacks + virtual sink
  - `apply_dsp_settings()`: replaced `link_filter_chain()` calls with new routing setup
  - Device monitor: changed `link_filter_chain()` → `ensure_loopback_to_physical()`
