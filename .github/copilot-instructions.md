# Project Guidelines

## Architecture
- App entry and auth routing live in `lib/main.dart`. App startup initializes Firebase, then routes by `usuarios/{uid}.tipoUsuario`.
- Use the feature-first structure in `lib/features/<feature>/...` for UI and feature logic.
- Keep shared backend access in `lib/core/services` (example: `lib/core/services/rotina_service.dart`).
- Keep design tokens and theme behavior in `lib/core/theme/app_theme.dart`.
- Do not edit generated platform/plugin files under `linux/flutter/`, `macos/Flutter/`, `windows/flutter/`, or `build/`.

## Build And Test
- Install dependencies: `flutter pub get`
- Static analysis: `flutter analyze`
- Tests: `flutter test`
- Run Android: `flutter run -d android`
- Run iOS (macOS/Xcode required): `flutter run -d ios`
- Build Android artifacts: `flutter build apk` and `flutter build appbundle`

## Firebase And Platform Notes
- Firebase config is defined in `lib/core/config/firebase_options.dart` and Android `android/app/google-services.json`.
- `firebase_options.dart` currently supports `web`, `android`, and `ios` only. `linux`, `macos`, and `windows` throw `UnsupportedError`.
- Primary Firestore collections: `usuarios` and `rotinas`. Keep collection names unchanged unless explicitly requested.

## Code Conventions
- Follow existing state management style: `StatefulWidget` + local controllers/services. Do not introduce a global state framework without explicit request.
- Follow existing navigation pattern: `Navigator.push(MaterialPageRoute(...))` with constructor parameters.
- Build Firestore payloads in feature pages as `Map<String, dynamic>`, then pass to services.
- Wrap Firebase/Firestore mutations in `try/catch` and surface user-facing failures with `ScaffoldMessenger.of(context).showSnackBar(...)`.
- Preserve role-based flow and parameter passing (`userType`, `uid`) when changing auth, login, or dashboard transitions.

## Regras do Copilot
- Nunca faça commits sem a permissão explícita do usuário. Sempre pergunte antes de criar commits ou pushes envolvendo o repositório.

Sempre que o usuário disser "faça um commit", você deve:
1. Executar um `git diff` para analisar todas as mudanças feitas no repositório.
2. Analisar cuidadosamente as alterações realizadas.
3. Criar um novo commit com uma mensagem detalhada em português, explicando claramente o que foi alterado, criado, removido ou corrigido.
4. A mensagem deve ser clara, objetiva e descrever o impacto das mudanças no projeto.

## UI And Theme Conventions
- Reuse `AppTheme` tokens for color, spacing, radius, and typography.
- Prefer spacing constants (for example `space8`, `space12`, `space16`, `space24`) over hard-coded numbers.
- Keep visual hierarchy clear and compact: heading, section label, content, helper text.
- Avoid introducing new color systems, font families, or shadow styles outside `AppTheme` unless explicitly requested.

## Reference Files
- `lib/main.dart`: Firebase initialization and auth gate.
- `lib/core/config/firebase_options.dart`: platform support and Firebase setup.
- `lib/core/services/rotina_service.dart`: Firestore read/write pattern.
- `lib/core/theme/app_theme.dart`: tokens and global styling.
- `lib/features/auth/login_page.dart`: auth form, validation, SnackBar error flow.
- `lib/features/treinos/treinos_page.dart`: list + StreamBuilder + navigation pattern.
- `test/widget_test.dart`: placeholder test; expand with real app behavior when adding features.
