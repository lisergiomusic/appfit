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
- `features/financeiro/` — Invoice tracking (faturas) per student

**State management:** `StatefulWidget` + local controllers/services. `StreamBuilder` for real-time Firestore data, `FutureBuilder` for one-off async calls. Complex pages use `ChangeNotifier` controllers wrapped in a local `ChangeNotifierProvider` — this is intentional and scoped to the page, not a global state framework. Do not introduce app-wide Provider state without explicit request.

**Navigation:** `Navigator.push(MaterialPageRoute(...))` with explicit constructor parameters (e.g. `userType`, `uid`, `alunoId`). No named routes.

## Key Conventions

- **Firestore payloads:** Build as `Map<String, dynamic>` in the feature page, pass to services. Mutations must be wrapped in `try/catch` with `ScaffoldMessenger.showSnackBar(...)` for errors.
- **Firestore collections:** `usuarios`, `rotinas`, `exercicios_base`, `logs_treino`, `faturas`. Sub-collection: `usuarios/{alunoId}/historico_peso`. Do not rename without explicit request.
- **Firebase platform support:** `firebase_options.dart` supports web, android, and iOS only — `linux`, `macos`, `windows` throw `UnsupportedError`.
- **Theme tokens:** Prefer semantic `SpacingTokens` constants (`pageTopPadding`, `sectionGap`, `cardPaddingH`, `listItemGap`, etc.) over numeric `AppTheme.spaceN` constants. For text styles use `AppTheme`, `CardTokens`, `ButtonTokens`, or `AppBarTokens` as appropriate. For sized components use `AvatarTokens` (sm/md/lg), `PillTokens`, or `ThumbnailTokens`. Colors live in `AppColors`. Never hard-code colors, spacing, or font sizes.
- **Remote images:** Use `cached_network_image` (not `Image.network`) to avoid flicker and reduce bandwidth.
- **Date locale:** `intl` is initialized for `pt_BR` in `main()` — always use `DateFormat(..., 'pt_BR')` for user-facing date strings.

## Notable Patterns

- **Routine editor (`rotina_detalhe_page.dart`):** On back navigation with unsaved changes, triggers `_salvarRotinaCompleta()` in the background (non-blocking) via `PopScope`. Be aware of this when changing navigation flow.
- **Session reordering:** Uses `ReorderableListView`; reorder option is disabled when fewer than 2 sessions exist.
- **`RotinaService.atualizarRotina(...)`:** Pass `dataCriacao` original to preserve creation date when calculating `dataVencimento`.
- **`grupoMuscular` migration:** `rotina_detalhe_page.dart` migrates legacy comma-separated strings to `List<String>` on read.
- **`personalId` preservation:** When saving exercises within a routine, each exercise map must retain its `personalId` field.
- **Controller pattern:** Complex pages delegate business logic to a dedicated controller class (e.g. `rotina_detalhe_controller.dart`, `configurar_treino_controller.dart`, `exercicio_detalhe_controller.dart`). Use this pattern for new pages with significant local state or multi-step logic.
- **Template rotinas:** A `rotinas` document with `alunoId: null` is a personal trainer's library template. `AlunoService.atribuirTreinoAoAluno()` copies a template into a student-specific rotina (deactivates previous active rotina first).
- **Combined streams:** Use `rxdart`'s `Rx.combineLatest2` when a page needs a single stream from two Firestore queries (see `AlunoService.getAlunoPerfilCompletoStream()`).
- **Student status:** The `usuarios` collection tracks `status` (`ativo`/`inativo`) and `ultimoTreino` (timestamp). Students not seen in 7+ days are flagged as "risco" in `AlunoService.fetchContagens()`.
- **First-access migration (`AuthService.primeiroAcessoAluno()`):** When a pre-registered student logs in for the first time, their UID is migrated into the existing `usuarios` doc and all related `rotinas` documents are updated. If the migration fails, the orphaned auth user is deleted for consistency.
- **Exercise search normalization:** `ExerciseService` strips diacritics before matching (e.g. "joelho" matches "Joelho") — avoid re-implementing this logic inline.
- **Shimmer loading:** Use `shimmer` package (`Shimmer.fromColors`) for skeleton placeholders while `StreamBuilder` / `FutureBuilder` is in `ConnectionState.waiting`, consistent with existing pages (e.g. `personal_aluno_perfil_page.dart`).

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
