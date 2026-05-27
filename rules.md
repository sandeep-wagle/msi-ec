# MSI Controller — Supreme Rules (HCR Enforced)

**Read first: `.rules/HCR.md`** — app HCR config.
**Shared root: `/home/sandy/development/flutter/.rules/`** — shared protocol, agent execution, skills index.

Read in order:

| # | File | What |
|---|------|------|
| 1 | `.rules/HCR.md` | App-specific HCR config |
| 2 | `/home/sandy/development/flutter/.rules/HCR.md` | Shared HCR protocol (behavior, exclusions, Golden Architect) |
| 3 | `/home/sandy/development/flutter/.rules/AGENT_EXECUTION.md` | Task classification, agent roles, workflows |
| 4 | `/home/sandy/development/flutter/.rules/flutter_antigravity/.agent/rules/project-rules.md` | Flutter architecture, widget rules, theming, DI, testing (551 lines) |
| 5 | `/home/sandy/development/flutter/.rules/antigravity-kit/.agent/rules/global-rules.md` | Cold Architect, zero-trust mandate, forensic integrity |
| 6 | `/home/sandy/development/flutter/.rules/antigravity-kit/.agent/rules/flutter-rules.md` | File length limits, context extensions, state management |
| 7 | `/home/sandy/development/flutter/.rules/antigravity-kit/.agent/rules/git-rules.md` | Branch strategy, conventional commits, PR rules |
| 8 | `/home/sandy/development/flutter/.rules/PRODUCTION_RULES.md` | 40MB APK, permissions, CI/CD gates, pre-flight checklist |

## App Identity

| Property | Value |
|----------|-------|
| Name | msi_controller |
| SDK | Flutter ^3.11.1 |
| State | flutter_bloc ^9.0.0 |
| DI | get_it + injectable |
| Project Root | `/home/sandy/development/flutter/apps/msi_controller` |

## HCR Response Architecture (Mandatory)

```
[THE RAW TRUTH]
<direct answer>

[THE CATCH]
<what could break>

[BIASES DETECTED]
1. bias
2. bias
3. bias

[CONFIDENCE]
High/Medium/Low + %
```

Trivial 1-3 line answers can skip. Complex code MUST use it.

## Exclusion Rules (Banned)

| Tag | Never Say |
|-----|-----------|
| 🚫 | "As an AI," "I understand," "I'm sorry," "I'm here to help" |
| 🚫 | "Let me explain what I'm going to do" — just do it |
| 🚫 | "In summary," "To wrap up," "As we've seen" |
| 🚫 | Passive voice |
| 🚫 | Inline comments in code |

## Golden Architect — State Management

```dart
// Simpler project — use GoldenState<T> or pattern-match with sealed freezed
@freezed
sealed class XState with _$XState {
  const factory XState.initial() = XInitial;
  const factory XState.loading() = XLoading;
  const factory XState.loaded({required T data}) = XLoaded;
  const factory XState.error({required String message}) = XError;
}

// MUST use .when — NO type casts, NO if (state is X) chains
state.when(
  initial: () => ...,
  loading: () => ...,
  loaded: (data) => ...,
  error: (msg) => ...,
);
```

BANNED: DataState<T> with nullable fields, type casting, if(isLoading) chains, Equatable on states.

## Product-Specific Requirements

This app controls MSI laptop hardware (fan speed, GPU mode, keyboard LEDs). Priority rules:
- **Never brick hardware** — validate all native channel calls with try/catch + fallback
- **Async all platform channels** — no blocking main thread for EC/Kernel reads
- **Cache hardware state** — avoid redundant EC queries (battery drain)
- **Graceful degradation** — if a feature isn't supported on this model, show disabled, not crash
- **Permissions-first** — request root/sudo/admin access before hardware writes

## Performance (Low-End Device)

- `BlocSelector` over `BlocBuilder` — prevent rebuilds
- `ListView.builder` always — never `Column(children: map)` for >20 items
- `withValues(alpha:)` — NEVER `withOpacity()`
- `const` constructors on every widget
- NO heavy ops in `build()`

## Coding Standards

- NO magic numbers/strings
- NO `dynamic` — explicit types
- NO `print()` — structured logging
- NO dead code — zero TODO, zero commented blocks
- const constructors with `super.key` on every widget

## Import Order

```dart
// 1. dart:*
// 2. package:flutter/*
// 3. third-party (alpha)
// 4. package:msi_controller/* (alpha)
// 5. ../relative
```

## Validation

```
[ ] HCR exclusion: no banned phrases
[ ] State: sealed + .when(), no casts
[ ] Performance: builder, const, withValues
[ ] Naming: snake_case files, PascalCase classes
[ ] Hardware safety: try/catch on all platform channels
[ ] flutter analyze: 0 errors
```

## Commands

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
dart format .
flutter build apk --debug
```
