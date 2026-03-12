# MSI Controller Project Rules

This document outlines the development rules for the MSI Controller Flutter project, based on the antigravity-kit agent rules. Follow these guidelines to ensure high-quality, maintainable code.

## Global Rules

### Code Quality Standards

#### General
- Write clean, readable, self-documenting code
- Follow the principle of least surprise
- Prefer explicit over implicit
- Keep functions small (under 20 lines, ideally under 10)
- Maximum 3 parameters per function (use objects for more)
- No magic numbers or strings — use named constants
- Delete dead code — don't comment it out
- Use meaningful names for everything (variables, functions, classes, files)

#### Error Handling
- Never silently swallow exceptions
- Handle all error states in the UI (loading, error, empty, data)
- Provide user-friendly error messages (not technical jargon)
- Log errors with sufficient context for debugging
- Use custom exception types for domain errors
- Fail fast at boundaries, handle gracefully at edges

#### Security
- Never store secrets in source code
- Validate and sanitize all user input
- Use parameterized queries for all database operations
- Encrypt sensitive data at rest and in transit
- Follow principle of least privilege for all access
- Keep dependencies up to date and scan for vulnerabilities

#### Performance
- Profile before optimizing — don't guess
- Optimize for the common case
- Use appropriate data structures
- Implement caching with proper invalidation
- Lazy load resources when possible
- Set performance budgets and monitor them

#### Testing
- Write tests for all business logic
- Follow the testing pyramid (unit > integration > e2e)
- Keep tests fast, isolated, and deterministic
- Test names should describe the scenario
- Every bug fix includes a regression test
- Minimum 80% coverage for business logic

#### Documentation
- Document "why" not "what" (code explains what)
- Keep README up to date
- Document all API endpoints
- Record architectural decisions in ADRs
- Include setup instructions for new developers
- Update documentation alongside code changes

#### Version Control
- Use conventional commits (feat:, fix:, docs:, refactor:, test:, chore:)
- Keep commits atomic (one logical change per commit)
- Write clear PR descriptions with context
- Review all code before merging
- Never commit secrets, credentials, or .env files
- Tag releases with semantic versioning

#### Collaboration
- Communicate decisions, not just code
- Ask for help when stuck for more than 30 minutes
- Share knowledge through documentation and code reviews
- Be constructive and specific in code reviews
- Respect existing patterns before introducing new ones

## Flutter Project Rules

### Dart/Flutter Standards

#### Code Style
- Follow the Effective Dart style guide
- Use `dart format` with default settings
- Use `dart analyze` with no warnings or errors
- Maximum line length: 80 characters
- Use trailing commas for better formatting and diffs
- Use relative imports within packages, package imports across packages

#### Widget Rules
- Use `const` constructors wherever possible
- Prefer `StatelessWidget` over `StatefulWidget` when no local state is needed
- Extract widgets into separate files when they exceed 50 lines
- Name widget files with snake_case matching the class name
- Always specify `Key` parameters for list items and animated widgets
- Dispose all controllers, subscriptions, and streams in `dispose()`

#### State Management
- Use Riverpod or Bloc for app-level state (choose one per project)
- Use `setState` only for truly local UI state
- Never store derived/computed state — compute it
- Keep state immutable (use freezed or copyWith)
- Handle all async states: loading, data, error

#### Navigation
- Use GoRouter or auto_route for declarative routing
- Define all routes in a central location
- Use typed route parameters
- Handle deep links properly
- Implement proper back navigation behavior

#### Naming Conventions
```
Files:       snake_case.dart (user_profile_screen.dart)
Classes:     PascalCase (UserProfileScreen)
Variables:   camelCase (userName)
Constants:   camelCase or SCREAMING_SNAKE_CASE (maxRetryCount, MAX_RETRY_COUNT)
Enums:       PascalCase with camelCase values (enum UserRole { admin, editor })
Extensions:  PascalCase with X suffix (StringX, DateTimeX)
Providers:   camelCase with Provider suffix (userProvider, authStateProvider)
Blocs:       PascalCase with Bloc/Cubit suffix (AuthBloc, ThemeCubit)
```

#### Project Structure
```
lib/
├── app/                    # App configuration, theme, router
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
├── core/                   # Shared utilities, constants, extensions
│   ├── constants/
│   ├── extensions/
│   ├── utils/
│   └── errors/
├── features/               # Feature modules
│   └── feature_name/
│       ├── data/           # Repositories, data sources, models
│       ├── domain/         # Entities, use cases (optional)
│       └── presentation/   # Screens, widgets, controllers
├── shared/                 # Shared widgets and components
│   ├── widgets/
│   └── components/
├── l10n/                   # Localization
└── main.dart
```

#### Theming
- Use Material 3 with ColorScheme.fromSeed()
- Define all colors through the theme (never hardcode hex values)
- Define text styles through ThemeData.textTheme
- Support both light and dark themes
- Use Theme.of(context) to access theme values

#### Assets
- Organize assets in typed directories (images/, icons/, fonts/, animations/)
- Use flutter_gen or similar for type-safe asset references
- Optimize images for mobile (appropriate resolution, WebP format)
- Use SVG for icons and illustrations when possible

#### Dependencies
- Prefer well-maintained packages with good pub scores
- Pin major versions in pubspec.yaml
- Audit new dependencies for quality and maintenance
- Minimize dependency count — don't add a package for trivial things
- Review dependency licenses for compatibility

#### Performance
- Use `ListView.builder` for long lists (never `ListView` with children)
- Use `RepaintBoundary` for frequently updating widgets
- Avoid rebuilding expensive widgets (use `const`, `select`, proper keys)
- Profile with Flutter DevTools before optimizing
- Use `compute()` or isolates for heavy computation

#### Localization
- Use Flutter's built-in l10n (intl package with ARB files)
- Never hardcode user-facing strings
- Support RTL layouts
- Format dates, numbers, and currencies with intl

#### Accessibility
- Add semantics labels to all interactive widgets
- Ensure sufficient color contrast
- Support screen readers (TalkBack, VoiceOver)
- Minimum touch target: 48x48 logical pixels
- Test with accessibility tools regularly

## DSP (Digital Signal Processing) Rules

### Audio Processing Standards

#### Real-Time Processing
- Maintain consistent buffer sizes (1024-4096 samples typical)
- Keep latency under 10ms for interactive applications
- Use double-precision (64-bit) floating point for calculations
- Implement thread-safe audio processing with isolates
- Profile CPU usage — target <50% for real-time processing

#### Audio Algorithms
- Implement DSP effects as pure functions (no side effects)
- Use immutable data structures for audio parameters
- Validate all audio parameters before processing (range, NaN, inf)
- Document algorithm latency and CPU requirements
- Test algorithms with edge cases (silence, clipping, DC offset)

#### Buffer Management
- Use fixed-size circular buffers for streaming audio
- Implement proper buffer underrun/overrun protection
- Pre-allocate audio buffers to avoid GC pressure
- Use efficient data structures (Float64List, Float32List)
- Zero-initialize buffers to prevent noise from uninitialized memory

#### State Management for DSP
- Store DSP parameters immutably (freezed/copyWith)
- Separate UI state from processing state
- Use reactive patterns for parameter changes
- Implement undo/redo for parameter adjustments
- Persist DSP settings with proper serialization

#### Performance Optimization
- Use SIMD operations where available (for vectorized math)
- Implement level 1 cache-friendly algorithms
- Profile memory bandwidth usage
- Optimize for branch prediction in inner loops
- Use lookup tables for expensive computations (sin, exp, etc.)

#### Audio I/O
- Handle device changes gracefully (hotplugging)
- Implement proper sample rate conversion when needed
- Support multiple audio formats (16-bit, 24-bit, 32-bit float)
- Validate audio device capabilities before initialization
- Provide fallback for missing audio hardware

#### Testing DSP Code
- Unit test algorithms with known input/output pairs
- Integration test with real audio files
- Performance test under load (multiple effects chained)
- Test parameter validation and edge cases
- Use golden files for audio output verification

#### UI/UX for DSP
- Provide visual feedback for parameter changes (meters, oscilloscopes)
- Implement proper knob/slider mappings (linear, exponential, logarithmic)
- Support preset management for effect chains
- Provide bypass switches for each effect
- Implement real-time parameter automation

#### Error Handling in DSP
- Gracefully handle audio device failures
- Provide fallback processing when real-time constraints missed
- Log processing errors without interrupting audio flow
- Implement recovery mechanisms for corrupted audio data
- Validate effect chain integrity before processing

## Git & Collaboration Rules

### Branch Strategy
- `main` — production-ready code, always deployable
- `develop` — integration branch for features
- `feature/{ticket-id}-short-description` — new features
- `fix/{ticket-id}-short-description` — bug fixes
- `hotfix/{ticket-id}-short-description` — urgent production fixes
- `release/v{version}` — release preparation

### Commit Messages
Follow Conventional Commits:
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

#### Types
- `feat` — new feature
- `fix` — bug fix
- `docs` — documentation changes
- `style` — formatting, no code change
- `refactor` — code change that neither fixes nor adds
- `perf` — performance improvement
- `test` — adding or updating tests
- `chore` — maintenance, dependencies, build
- `ci` — CI/CD changes
- `revert` — reverting a previous commit

#### Examples
```
feat(auth): add social login with Google OAuth
fix(cart): prevent negative quantity on item update
docs(readme): update setup instructions for M1 Macs
refactor(user): extract validation logic to separate class
```

### Pull Request Rules
- Keep PRs small and focused (under 400 lines changed)
- Write clear PR descriptions with context and screenshots
- Link to related issues/tickets
- All CI checks must pass before merge
- At least one approval required
- Resolve all review comments before merging
- Squash merge for feature branches
- Delete branches after merging

### Code Review Guidelines
- Review within 24 hours
- Be specific and constructive
- Use labels: [must-fix], [suggestion], [nit], [question]
- Test the changes locally for significant PRs
- Approve only when confident in correctness and quality

### Release Process
1. Create release branch from develop
2. Update version numbers and changelog
3. Run full test suite
4. Create PR to main
5. Tag release with semantic version
6. Deploy to production
7. Merge main back to develop

## Skills to Follow
Use these antigravity-kit skills for development:
- flutter-expert
- dart-patterns
- riverpod-bloc-provider
- state-management
- flutter-testing
- lint-and-validate
- architecture
- clean-code
- performance-profiling
- git-version-control
- mobile-design
- ui-ux-pro-max
- responsive-adaptive-design
- bash-linux (for scripts/builds)
- ci-cd-pipelines (if applicable)
- deployment-procedures
- systematic-debugging

Load skills via the skill tool as needed for tasks.