# Goalden

A minimal daily and weekly task management app built with Flutter. Goalden helps you plan your day, manage recurring tasks, and stay on top of your week — on Linux desktop and Android.

---

## Engineering highlights

- **Offline-first** — all reads and writes go to local SQLite (Drift); sync is a background concern that never blocks the UI
- **Bidirectional sync** — last-write-wins on `updated_at`; handles concurrent edits, offline queues, and reconnect scenarios
- **Soft-delete tombstoning** — deletions are tracked and synced to other devices instead of silently removed
- **Recurring task deletion** — deleting a recurring source soft-deletes all future instances so they don't recreate themselves on other devices (regression-tested)
- **Sync concurrency guard** — synchronous boolean guard prevents overlapping sync calls across async boundaries
- **Lazy recurrence generation** — recurring instances are generated on demand per date, keeping the dataset small and sync fast
- **Per-user database isolation** — each Supabase user gets their own SQLite file; switching accounts opens a fresh database

See [goalden-back/docs/ARCHITECTURE.md](https://github.com/mavalu22/goalden-back/blob/main/docs/ARCHITECTURE.md) for the full system design.

---

## Features

- **Today screen** — daily task list with quick add, completion toggle, swipe-to-postpone, swipe-to-remove, and drag-to-reorder
- **Week screen** — 7-day overview with per-day task lists and drag-between-days
- **Task detail** — full creation and editing form with title, notes, time range, recurrence, and scheduling
- **Recurring tasks** — daily, weekly, and custom recurrence with delete-all-or-just-this awareness
- **Desktop-optimized layout** — contextual sidebar, hover menus, right-click context menus, keyboard-friendly interactions
- **Authentication** — Email/password, Google Sign In, Apple Sign In (iOS/macOS native; OAuth redirect on other platforms)
- **Profile screen** — display name editing and account management
- **Empty and feedback states** — loading, error, and empty states throughout

---

## Tech stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart 3.x) |
| State management | Riverpod (riverpod_generator, AsyncNotifier) |
| Local storage | Drift (SQLite) with per-user database isolation |
| Backend | Custom Go REST API |
| Auth & sync | Supabase Auth (Google, Apple, Email) |
| Navigation | go_router |
| Models | Freezed + json_serializable |
| Animations | flutter_animate |

---

## Platforms

| Platform | V1 Status |
|---|---|
| Linux (desktop) | Supported — primary V1 target |
| Android | Supported — requires signing config for release builds |
| macOS | Post-V1 |
| Windows | Post-V1 |
| iOS | Post-V1 |

See [docs/PLATFORM_STATUS.md](docs/PLATFORM_STATUS.md) for a full per-platform readiness evaluation.

---

## Local setup

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (stable channel)
- Java 17+ and Android SDK (Android builds only — see [docs/RELEASE.md](docs/RELEASE.md))

### 1. Clone and install dependencies

```bash
git clone https://github.com/mavalu22/goalden-front
cd goalden-front
flutter pub get
```

### 2. Configure environment

Copy the example env file and fill in your Supabase credentials:

```bash
cp .env.example .env
```

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
API_BASE_URL=http://localhost:8080/api/v1
```

### 3. Run code generation

Generated Dart files (Drift, Freezed, Riverpod) are not committed to the repository. This step is **required** on every clean checkout before building or running the app:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run

```bash
# Linux desktop
flutter run -d linux --dart-define-from-file=.env

# Android (device must be connected with USB debugging enabled)
flutter run -d <device-id> --dart-define-from-file=.env

# Linux release build
flutter build linux --dart-define-from-file=.env

# Android release APK
flutter build apk --dart-define-from-file=.env
```

---

## Project structure

```
lib/
├── app.dart                  # Root app widget and router setup
├── main.dart                 # Entry point, Supabase init, deep link handling
├── core/
│   ├── config/               # Environment config (Env class)
│   ├── platform/             # Platform-specific URL scheme handling
│   └── theme/                # Design system (colors, typography, tokens)
├── data/
│   ├── local/                # Drift database, tables, DAOs, migrations
│   └── repositories/         # Auth and task repository implementations
├── domain/
│   ├── models/               # Freezed data models (AppUser, Task, etc.)
│   └── repositories/         # Repository interfaces
└── presentation/
    ├── auth/                 # Login, email auth screens
    ├── today/                # Today screen, task tiles, task detail
    ├── week/                 # Week screen, day columns
    └── profile/              # Profile screen
```

---

## Related

- [goalden-back](https://github.com/mavalu22/goalden-back) — Go REST API backend
- [goalden-back/docs/ARCHITECTURE.md](https://github.com/mavalu22/goalden-back/blob/main/docs/ARCHITECTURE.md) — Full system architecture and sync protocol
- [docs/RELEASE.md](docs/RELEASE.md) — Build and release instructions
- [docs/PLATFORM_STATUS.md](docs/PLATFORM_STATUS.md) — Platform readiness report
- [docs/SYNC_TESTING.md](docs/SYNC_TESTING.md) — Multi-device sync test checklist
