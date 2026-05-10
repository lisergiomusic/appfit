This is a Flutter project named `appfit`. It's a high-performance mobile application for personal trainers to manage their clients' workouts, powered by a **Supabase (PostgreSQL)** backend.

## Project Overview

The application follows a modular, feature-based structure with a focus on "Staff-level" UI/UX and a robust relational data model.

### Main User Flow
1.  **Authentication:** Powered by Supabase Auth (Email/Password, Google).
2.  **Dashboard:** Centralized hub for trainers to manage multiple students.
3.  **Modelos & Biblioteca (Workouts):** 
    *   **Modelos:** Relational plans with specific objectives and durations (formerly 'Rotinas').
    *   **Sessões:** Specific workout days (e.g., "Push Day") with day-of-week assignments.
    *   **Exercícios:** Relational library with a hierarchical instruction system (Global -> Personalized -> Session).
    *   **Séries:** Complex structure supporting different types (Warm-up, Work) with atomic persistence.

## Tech Stack & Dependencies

*   **Core:** Flutter (Material 3 + Custom Premium Theme)
*   **Backend:** Supabase (PostgreSQL, Auth, Storage, Edge Functions)
*   **State Management:** `Provider` + `ChangeNotifier` for local/feature state.
*   **UI Assets:** Google Fonts, Cupertino Icons, Custom "Glassmorphism" widgets.

## Data & Security (Supabase)

The project utilizes PostgreSQL's relational power:
- **RLS (Row Level Security):** Policies are strictly enforced. Trainers can only modify their own exercises or their `instrucoes_personalizadas` on global exercises.
- **Atomic Persistence:** Each exercise session handles its own state updates to ensure data integrity during complex edits.
- **Relational Integrity:** We do not use "docs" (Firebase). We work with typed Models and PostgreSQL JSONB for complex structures.

## Developer Mindset and UI/UX Principles (Premium Hybrid)

### Visual Identity
*   **Industrial Background:** Pure Deep Black (`#121212`) is the standard background.
*   **Minimalist Cards & Mode-Specific UI:** Avoid excessive use of cards. We follow a 'Mode-Specific UI' philosophy:
    *   **Creation/Editing (Personal Trainer):** Use tactile, floating cards (`AppTheme.premiumCardDecoration` with `radiusXL`) to signify draggable, editable objects (e.g., configuring a workout).
    *   **Consumption (Aluno):** Do NOT use cards. Use flat lists blending into the deep black background, separated only by subtle dividers (`alpha 0.08`), to create a distraction-free, "playlist-like" experience during execution.
    *   **General Rule:** Prefer metrics and text floating directly on the black background over wrapping everything in a card.
*   **Geometry:** Mandatory 16px (`radiusXL`) for cards and inputs. Full pill shape (`radiusFull`) for buttons.
*   **Typography Hierarchy:**
    *   **Page Titles:** Proper Casing (e.g., 'Gerenciar alunos') for sophistication.
    *   **Section Headers:** UPPERCASE with letter spacing (e.g., 'LISTA DE EXERCÍCIOS').
    *   **Tags/Pills:** UPPERCASE, small font, semi-bold (`PillTokens`).

### Frictionless UX (Auto-Save Pattern)
*   **Auto-save on Pop:** Page detail views MUST NOT have "Salvar" buttons. Implement `PopScope` logic to trigger saving when the user leaves the page.
*   **Frictionless Actions:** Use `CupertinoIcons.settings` (gear) in the AppBar to toggle configuration modals, never inline edit fields in headers.
*   **Feedback:** Use a translucent Blur Overlay ("Salvando...") during async persistence.
*   **Tactile Response:** `HapticFeedback.lightImpact()` is mandatory for all primary interactions (toggles, nav, selections).

### SliverAppBar Header Standards (Staff-level)
*   **Dimensions:** `expandedHeight: 110` for title only; `expandedHeight: 150` for title + subtitle/pills.
*   **Header Content:** MUST use `AppTheme.premiumGradient` background.
*   **Transition:** Manual cross-fade (Opacity) using `LayoutBuilder`. Expanded title at `bottom: 16`, `left: 20`. Collapsed title centered.

## Development Conventions

### Code Structure
- Feature-based folder organization (e.g., `lib/features/treinos/personal/`).
- Use `Color.withValues(alpha: ...)` instead of `withOpacity` or `withAlpha`.
- Dirty Check Pattern: Use internal `hasChanges` to optimize network calls during Auto-save.

### Git & Commits
Format: `type(scope): description` (e.g., `feat(treinos): implement auto-save for session details`). Generate the message but do not execute the commit unless asked.

### Quality Standards
- `flutter_lints` rules must always pass.
- Use `ChangeNotifier` for complex view states.
- No business logic inside widgets.
- Mandatory error handling (never ignore exceptions).