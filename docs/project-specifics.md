# Goalden — Project Specifics

## Tech Stack

### Frontend
- **Framework:** Flutter 3.x (latest stable)
- **Language:** Dart 3.x (latest stable)
- **Platforms:** iOS, Android, macOS, Windows, Linux
- **Minimum targets:** iOS 15+, Android API 26+ (Android 8.0), macOS 12+, Windows 10+

### State Management
- **Riverpod** (flutter_riverpod + riverpod_annotation + riverpod_generator)
- Use code generation with `@riverpod` annotations for all providers
- Prefer `AsyncNotifier` for async state, `Notifier` for sync state
- Keep providers small and focused — one provider per concern

### Local Storage
- **Drift** (SQLite wrapper) for all persistent data
- Define all tables and queries using Drift's Dart-based schema
- Use DAOs (Data Access Objects) to organize queries by domain (e.g., `TaskDao`, `GoalDao`)
- Run migrations properly — never drop and recreate tables

### Backend & Cloud Services
- **Custom backend in Go** — handles business logic, API endpoints, and server-side operations
- **Supabase** — used for authentication (Google, Apple, email/password) and real-time sync capabilities
- Communication with Go backend via REST API (HTTP)
- Communication with Supabase via the official `supabase_flutter` SDK

### Authentication
- **Supabase Auth** — handles all auth flows:
  - Google sign-in (`google_sign_in` package + Supabase OAuth)
  - Apple sign-in (`sign_in_with_apple` package + Supabase OAuth)
  - Email/password (Supabase native email auth)
- Session persistence managed by Supabase client (auto-refresh tokens)
- Auth state exposed via a Riverpod provider for reactive UI updates

---

## Project Architecture

### Folder Structure

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # MaterialApp / router configuration
├── core/                        # Shared utilities and constants
│   ├── theme/                   # Design system (colors, typography, spacing)
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   └── app_theme.dart
│   ├── constants/               # App-wide constants
│   ├── utils/                   # Helper functions
│   └── extensions/              # Dart extensions
├── data/                        # Data layer
│   ├── local/                   # Drift database
│   │   ├── database.dart        # Database definition
│   │   ├── tables/              # Table definitions
│   │   └── daos/                # Data Access Objects
│   ├── remote/                  # API clients
│   │   ├── supabase_client.dart
│   │   └── api_client.dart      # Go backend HTTP client
│   └── repositories/            # Repository implementations
├── domain/                      # Business logic
│   ├── models/                  # Domain models / entities
│   └── repositories/            # Repository interfaces (abstract)
├── presentation/                # UI layer
│   ├── auth/                    # Login screens and auth widgets
│   │   ├── screens/
│   │   └── widgets/
│   ├── today/                   # Today screen
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── providers/
│   ├── week/                    # Week screen
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── providers/
│   ├── goals/                   # Goals screen (future)
│   │   └── ...
│   ├── history/                 # History screen (future)
│   │   └── ...
│   └── shared/                  # Shared UI components
│       ├── widgets/             # Reusable widgets (buttons, cards, inputs)
│       └── layouts/             # App shell, responsive layout, navigation
└── providers/                   # Global Riverpod providers (auth, db, sync)
```

### Architecture Pattern

- **Clean Architecture** with 3 layers: data → domain → presentation
- **Data layer:** Drift DAOs, Supabase client, Go API client, repository implementations
- **Domain layer:** Models/entities, repository interfaces. No framework dependencies here
- **Presentation layer:** Screens, widgets, and Riverpod providers that connect UI to domain
- Dependencies flow inward: presentation → domain ← data

---

## Routing

- **GoRouter** (`go_router` package) for declarative routing
- Routes protected by auth state — unauthenticated users are redirected to login
- Deep linking support enabled for future use
- Route definitions centralized in a single file

---

## Key Packages

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `riverpod_annotation` + `riverpod_generator` | Code generation for providers |
| `drift` + `sqlite3_flutter_libs` | Local SQLite database |
| `supabase_flutter` | Supabase client (auth, database, realtime) |
| `google_sign_in` | Google OAuth |
| `sign_in_with_apple` | Apple sign-in |
| `go_router` | Navigation and routing |
| `freezed` + `json_serializable` | Immutable models and JSON serialization |
| `build_runner` | Code generation runner |
| `flutter_animate` | Micro-animations and transitions |
| `flutter_slidable` | Swipe actions on list items |
| `reorderable_grid` or `drag_and_drop_lists` | Drag & drop reordering |
| `intl` | Date formatting and localization |
| `connectivity_plus` | Network state detection (for offline/online sync) |

---

## Coding Conventions

### Dart Style
- Follow the official [Dart style guide](https://dart.dev/effective-dart/style)
- Use `dart format` for consistent formatting
- Max line length: 80 characters
- Always use trailing commas for better diffs and formatting
- Prefer `const` constructors wherever possible

### Naming Conventions
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables and functions: `camelCase`
- Constants: `camelCase` (Dart convention, not SCREAMING_CASE)
- Providers: `camelCase` ending with `Provider` (e.g., `taskListProvider`, `authStateProvider`)
- Private members: prefix with `_`

### Widget Guidelines
- Extract widgets into separate files when they exceed ~80 lines
- Prefer `StatelessWidget` + Riverpod over `StatefulWidget` when possible
- Use `ConsumerWidget` or `ConsumerStatefulWidget` for widgets that read providers
- Keep `build()` methods clean — extract complex logic into helper methods or separate widgets
- All reusable widgets go in `presentation/shared/widgets/`

### Error Handling
- Use `AsyncValue` from Riverpod for loading/error/data states in the UI
- Never catch errors silently — at minimum log them
- Show user-friendly error messages — never expose stack traces or technical errors
- Use `Result` pattern or `Either` for operations that can fail in the domain layer

---

## Design System Tokens

All visual values are centralized in `lib/core/theme/`. Never hardcode colors, font sizes, or spacing values in widgets.

### Colors (reference — exact values from Stitch design)
- Background: `#141414`
- Surface: slight elevation over background
- Accent / Golden: `#D4AF37`
- Text Primary: `#E8E4DC`
- Text Secondary: muted gray
- Text Muted: darker gray
- Error: red tone (not aggressive)
- Success: golden (same as accent — completing a task is a golden moment)

### Typography
- Display / Logo: Serif font (e.g., Playfair Display)
- Body / UI: Sans-serif font (e.g., DM Sans)
- Define a full type scale: heading, subheading, body, caption, label

### Spacing
- Use a consistent spacing scale: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64
- All padding and margins should reference these values

---

## Build & Run

Generated Dart files (Drift, Freezed, Riverpod) are **not committed** to the repository. Code generation is required on every clean checkout before building or running.

```bash
# 1. Get dependencies
flutter pub get

# 2. Run code generation — required from a clean checkout
dart run build_runner build --delete-conflicting-outputs

# 3. Run (supported V1 platforms)
flutter run -d linux --dart-define-from-file=.env    # Linux desktop
flutter run -d <device-id> --dart-define-from-file=.env  # Android

# Build release
flutter build linux --dart-define-from-file=.env    # Linux
flutter build apk --dart-define-from-file=.env      # Android APK
```

> macOS, Windows, iOS, and web are post-V1 targets. Platform directories for these are not yet set up in the repository.

---

## Git

### Branch Strategy
- `main` — stable, production-ready code
- `dev` — active development branch
- Feature branches: `feature/TASK-XXX-short-description`
- All work happens on `dev` or feature branches, merged into `main` when stable

### Commit Format
- `[TASK-XXX] short description of what was done`
- Example: `[TASK-004] implement login screen UI`
- Keep commits atomic — one task per commit when possible

---

## Environment Setup

### Required Tools
- Flutter SDK 3.x (latest stable)
- Dart SDK 3.x (comes with Flutter)
- Xcode (for iOS/macOS builds)
- Android Studio or Android SDK (for Android builds)
- A Supabase project with Auth configured (Google, Apple, Email providers enabled)

### Environment Variables
- Store sensitive configuration (Supabase URL, anon key) in environment files
- Never commit `.env` files — use `.env.example` as a template
- Access env vars through a centralized config class, not scattered across the codebase