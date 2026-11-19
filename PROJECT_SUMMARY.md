# MSI Controller — Project Summary

> **Stack:** Flutter · flutter_bloc · get_it · injectable · PipeWire/Rust (Backend)

---

## 1. Project Overview
**MSI Controller** is a Linux-based system utility designed to manage hardware settings and audio DSP for MSI laptops. It provides a centralized hub for system monitoring (battery, fans), performance modes, RGB lighting (Mystic Light), and advanced audio routing via a custom PipeWire-based DSP service.

---

## 2. Tech Stack
| Layer | Technology |
|---|---|
| Framework | Flutter (SDK ^3.11.1) |
| State Management | flutter_bloc for business logic |
| Dependency Injection | get_it + injectable (automated registration) |
| Navigation | `GlobalKey<NavigatorState>` for context-less navigation |
| Local Storage | shared_preferences for user profiles and settings |
| Backend Service | Custom Rust-based `msi_dsp_service` |
| Audio Routing | PipeWire (module-null-sink, module-loopback) |

---

## 3. Architecture
**Pattern:** Layered Architecture (Clean Architecture influence).

- **`lib/core/`**: Constants, theme tokens (`AppColors`), and DI config.
- **`lib/domain/`**: Core entities (`AudioProfile`, `SystemInfo`) and abstract repository interfaces (`MsiRepository`).
- **`lib/data/`**: Repository implementations and data sources interacting with the hardware/DSP service.
- **`lib/logic/`**: BLoCs (`SoundBloc`, `SettingsBloc`, `AudioBloc`) bridging UI and domain.
- **`lib/screens/` & `lib/widgets/`**: UI layer with a high-fidelity "glassmorphism" and "cute" visual aesthetic.

---

## 4. Data Models
- **Entities**: Defined in `lib/domain/entities/` (e.g., `AudioProfile`, `SystemInfo`).
- **Serialization**: Manual `toJson`/`fromJson` in `AudioProfile` for configuration persistence.
- **Optimization**: `equatable` used in BLoC states to minimize unnecessary rebuilds.

---

## 5. Authentication
**N/A**: As a local system utility, the app operates with direct hardware/service access and requires no user accounts or authentication.

---

## 6. API Layer & Hardware Integration
- **IPC (Inter-Process Communication)**: Communicates with a local backend service rather than a REST API.
- **DSP Service**: A Rust binary (`msi_dsp_service`) handles audio routing and filtering.
- **Connection**: `MsiRepository` maintains a `Socket` connection (`dspSocket`) for real-time audio control and system updates.

---

## 7. Infrastructure
- **Audio Pipeline**: Complex PipeWire setup creating `msi_dsp_sink` and routing audio through a filter chain via `module-loopback`.
- **Persistence**: `PersistenceService` wraps `SharedPreferences` for theme, Mystic Light, and Smart Priority lists.
- **OS Integration**: Targeted specifically for Linux, leveraging `pw-metadata` and `pw-cli`.

---

## 8. Security
- **Privileges**: Requires system-level permissions to modify audio settings and access the Embedded Controller (EC).
- **Encryption**: No encryption implemented; settings are stored in plain text via `SharedPreferences`.

---

## 9. Performance
- **UI Optimization**: 
  - `restartable()` BLoC transformers to cancel pending events during rapid input (e.g., sliders).
  - Removal of heavy `BackdropFilter` and blur effects to maintain high FPS on Linux desktops.
- **Latency**: The DSP service is run as a release binary to minimize startup and response latency.

---

## 10. Development Practices
- **Linting**: `flutter_lints` standard; `flutter analyze` used as a CI gate.
- **Code Gen**: `build_runner` with `injectable_generator` for DI.
- **Design Tokens**: Strict use of `AppColors` tokens to ensure visual consistency and prevent hardcoded colors.

---

## 11. Human vs AI Patterns
- **AI Influence**: High. The highly structured boilerplate (Injectable + BLoC + Clean Architecture) and the "cute" UI redesign documented in `AGENTS.md` indicate AI-driven refinement.
- **Human Engineering**: The Rust/PipeWire integration and low-level debugging (e.g., `libspa-aec-webrtc` crashes) are characteristic of specialized human system engineering.

---

## 12. Documentation Quality
- **Living Docs**: `AGENTS.md` serves as a comprehensive log of goals, constraints, and progress.
- **Structure**: Clean directory structure makes the architecture self-documenting.
- **Gap**: Lacks formal API/technical documentation (e.g., DartDoc) for the domain layer.
