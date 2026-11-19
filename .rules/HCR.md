# MSI Controller — HCR (Hard-Coded Reality)

**Read first: `/home/sandy/development/flutter/.rules/HCR.md`** — shared HCR protocol (has full rule kit index with flutter_antigravity, antigravity-kit, PRODUCTION_RULES).
**Read next: `/home/sandy/development/flutter/.rules/AGENT_EXECUTION.md`** — task classification.

## App Identity

| Property | Value |
|----------|-------|
| SDK | Flutter ^3.11.1 |
| State | flutter_bloc ^9.0.0 |
| DI | get_it + injectable |
| Project | `/home/sandy/development/flutter/apps/msi_controller` |

## Product-Specific Rules

This app controls MSI laptop hardware (fan speed, GPU mode, keyboard LEDs):

- **Never brick hardware** — try/catch + fallback on all native channel calls
- **Async all platform channels** — no blocking main thread for EC/Kernel reads
- **Cache hardware state** — avoid redundant EC queries (battery drain)
- **Graceful degradation** — unsupported features show disabled, not crash
- **Permissions-first** — request root/sudo/admin before hardware writes

## Commands

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
dart format .
flutter build apk --debug
```
