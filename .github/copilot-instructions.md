# Copilot / AI Agent Instructions for AppFit

Brief: This Flutter app (AppFit) is a feature-organized mobile/web/desktop app using Firebase (Auth + Firestore). Agents should focus on feature pages under `lib/features`, shared services under `lib/core/services`, and theme/config under `lib/core`.

- Project entry: [lib/main.dart](lib/main.dart#L1) — initializes Firebase and routes users by `tipoUsuario` in Firestore.
- Firebase config: [lib/core/config/firebase_options.dart](lib/core/config/firebase_options.dart#L1) and Android `android/app/google-services.json` (exists in repo). Auth + Firestore are primary integrations.
- Feature structure: `lib/features/<feature>/...` (e.g., Treinos pages in `lib/features/treinos/`). UI is mostly StatefulWidgets + Navigator-based routing.
- Services: shared backend code lives in `lib/core/services` (e.g., [rotina_service.dart](lib/core/services/rotina_service.dart#L1)). Firestore collection names observed: `usuarios`, `rotinas`.
- Theming and design tokens: [lib/core/theme/app_theme.dart](lib/core/theme/app_theme.dart#L1) — use these colors/styles for consistent UI changes.

Build / run notes (explicit commands):
- Install deps: `flutter pub get`
- Run on connected Android device: `flutter run -d android`
- Run on Linux desktop (repo includes linux runner): `flutter run -d linux`
- Build Android APK / appbundle: `flutter build apk` or `flutter build appbundle`
- iOS: requires Xcode/macOS; Android uses Gradle wrapper in `android/` when building.

Codebase conventions & patterns (concrete):
- No heavy state management library: code uses StatefulWidgets and small service classes. Modify existing patterns rather than introducing global state managers unless approved.
- Navigation: uses `Navigator.push(MaterialPageRoute(...))` and passes parameters via constructors (e.g., `LoginPage(userType: 'aluno')`).
- Data modeling: pages construct JSON-like Maps before sending to services (see `lib/features/treinos/criar_rotina_page.dart` which builds `sessoesJson` then calls `RotinaService().criarRotina(...)`).
- Error handling: pages surface errors via `ScaffoldMessenger.of(context).showSnackBar(...)` — follow this UX for user-visible errors.

Testing & linting:
- Lints: `analysis_options.yaml` and `flutter_lints` are enabled. Keep code style consistent with existing files.
- There is a basic widget test at `test/widget_test.dart` — run `flutter test` to execute.

Important integration points to check before changes:
- Firebase auth flows: `FirebaseAuth.instance.authStateChanges()` in [lib/main.dart](lib/main.dart#L1) — changing auth behavior affects app routing.
- Firestore reads/writes: `lib/core/services/rotina_service.dart` and other service files. Keep collection naming (`usuarios`, `rotinas`) consistent.
- Platform entries: native/plugin registrants are generated under `linux/`, `macos/`, `windows/` — avoid editing generated files.

When editing:
- Preserve theming tokens in `lib/core/theme/app_theme.dart` to avoid visual regressions.
- Prefer small, localized changes in feature folders. When you must refactor cross-cutting concerns (auth, services, theme), document the change in the PR description.

Examples to reference when implementing features or fixes:
- Feature-to-service call: `lib/features/treinos/criar_rotina_page.dart` -> `lib/core/services/rotina_service.dart`.
- User gating by role: [lib/main.dart](lib/main.dart#L1) reads `tipoUsuario` from `usuarios` collection and constructs `DashboardPage(userType: tipo)`.

If anything is unclear or you need more environment details (API keys, CI, or emulator setup), ask for access or permission before changing secrets or platform configs.

Please review and tell me which sections need more detail or examples.
