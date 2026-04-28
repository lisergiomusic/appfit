This is a Flutter project named `appfit`. It's a high-performance mobile application for personal trainers to manage their clients' workouts, currently transitioned to a **Supabase-backed** architecture.

## Project Overview

The application follows a modular, feature-based structure with a focus on "Staff-level" UI/UX and a robust relational data model.

### Main User Flow
1.  **Authentication:** Powered by Supabase Auth (Email/Password, Google).
2.  **Dashboard:** Centralized hub for trainers to manage multiple students.
3.  **Treinos (Workouts):** 
    *   **Rotinas:** Relational plans with specific objectives and durations.
    *   **Sessões:** Specific workout days (e.g., "Push Day") with day-of-week assignments.
    *   **Exercícios:** Relational library with a hierarchical instruction system (Global -> Personalized -> Session).
    *   **Séries:** Complex structure supporting different types (Warm-up, Feeder, Work) with atomic persistence.

## Tech Stack & Dependencies

*   **Core:** Flutter (Material 3 + Custom Premium Theme)
*   **Backend:** Supabase (PostgreSQL, Auth, Storage, Edge Functions)
*   **State Management:** `Provider` + `ChangeNotifier` for local/feature state.
*   **UI Assets:** Google Fonts, Cupertino Icons, Custom "Glassmorphism" widgets.

## Data & Security (Supabase)

The project utilizes PostgreSQL's relational power:
- **RLS (Row Level Security):** Policies are strictly enforced. Trainers can only modify their own exercises or their `instrucoes_personalizadas` on global exercises.
- **Atomic Persistence:** Each exercise session handles its own state updates to ensure data integrity during complex edits.
- **Instruction Hierarchy:**
    1. `instrucoes`: Global default from the exercise library.
    2. `instrucoes_personalizadas`: Trainer's persistent override for that specific exercise across all clients.
    3. `sessao_instrucoes`: Specific instruction for a single session instance.

## Developer Mindset and UI/UX Principles

*   **Staff-level Engineering:** Prioritize maintainability, scalability, and type safety.
*   **Premium UI/UX:** Every interface must feel professional. Use "glassmorphism" for action buttons, consistent spacing (SpacingTokens), and ergonomic touch targets (min 44px).
*   **Dirty Check Pattern:** Always implement `hasChanges` logic in complex forms to disable "Save" buttons and optimize network calls.
*   **Haptic Feedback:** Use `HapticFeedback.lightImpact()` for critical UI interactions (toggles, reorders, selections).

## Development Conventions

### Code Structure
- Feature-based folder organization (e.g., `lib/features/treinos/personal/`).
- Separation of concerns: Controllers for logic, Widgets for UI.
- No business logic inside widgets.
- Mandatory error handling (never ignore exceptions).

### Git & Commits
When requested to **"gere um commit"**, follow this standard:
- **Format:** `type(scope): description` (e.g., `feat(treinos): implement dirty check for session details`)
- **Action:** Generate the message and display it. **Do not execute the commit.**

### Quality Standards
- `flutter_lints` rules must always pass.
- Use `ChangeNotifier` for complex view states.
- Follow the established `AppTheme` and `CardTokens` for visual consistency.