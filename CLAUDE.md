# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get           # Install dependencies
flutter analyze           # Static analysis / lint
flutter test              # Run all tests
flutter test test/features/treinos/treinos_page_test.dart  # Run a single test file
flutter run -d android    # Run on Android
flutter run -d ios        # Run on iOS (requires macOS + Xcode)
flutter build apk         # Android APK
flutter build appbundle   # Android App Bundle
```

## Architecture

**Entry point:** `lib/main.dart` initializes Firebase, then routes based on `usuarios/{uid}.tipoUsuario` (Firestore) to split personal trainer vs. student flows.

**Feature-first structure under `lib/`:**
- `core/services/` — Firestore and auth access (shared across features)
- `core/theme/app_theme.dart` — All design tokens: colors, spacing, radius, typography
- `core/widgets/` — Reusable UI components
- `features/auth/` — Login and registration
- `features/dashboard/` — Tab shell (Home, Alunos, Treinos, Settings)
- `features/alunos/` — Student management (personal trainer's view)
- `features/treinos/` — Workout routine editor (core feature)

**State management:** `StatefulWidget` + local controllers/services. `StreamBuilder` for real-time Firestore data, `FutureBuilder` for one-off async calls. Do not introduce a global state framework without explicit request.

**Navigation:** `Navigator.push(MaterialPageRoute(...))` with explicit constructor parameters (e.g. `userType`, `uid`, `alunoId`). No named routes.

## Key Conventions

- **Firestore payloads:** Build as `Map<String, dynamic>` in the feature page, pass to services. Mutations must be wrapped in `try/catch` with `ScaffoldMessenger.showSnackBar(...)` for errors.
- **Firestore collections:** `usuarios`, `rotinas`, `exercicios`. Do not rename without explicit request.
- **Firebase platform support:** `firebase_options.dart` supports web, android, and iOS only — `linux`, `macos`, `windows` throw `UnsupportedError`.
- **Theme tokens:** Always use `AppTheme` constants (`space8`, `space12`, `space16`, `space24`, etc.). Never hard-code colors, spacing, or font sizes.
- **Remote images:** Use `cached_network_image` (not `Image.network`) to avoid flicker and reduce bandwidth.

## Notable Patterns

- **Routine editor (`rotina_detalhe_page.dart`):** On back navigation with unsaved changes, triggers `_salvarRotinaCompleta()` in the background (non-blocking) via `PopScope`. Be aware of this when changing navigation flow.
- **Session reordering:** Uses `ReorderableListView`; reorder option is disabled when fewer than 2 sessions exist.
- **`RotinaService.atualizarRotina(...)`:** Pass `dataCriacao` original to preserve creation date when calculating `dataVencimento`.
- **`grupoMuscular` migration:** `rotina_detalhe_page.dart` migrates legacy comma-separated strings to `List<String>` on read.
- **`personalId` preservation:** When saving exercises within a routine, each exercise map must retain its `personalId` field.

## Testing

Tests use `FakeFirebaseFirestore` + `firebase_auth_mocks` + `mocktail` for isolation — no real Firebase connections.

```
test/
├── widget_test.dart                          # App smoke test
└── features/
    ├── treinos/treinos_page_test.dart
    └── alunos/editar_aluno_page_test.dart
```

## Do Not Edit

Generated platform/plugin files under `build/`, `linux/flutter/`, `macos/Flutter/`, `windows/flutter/`.
