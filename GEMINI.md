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
- **Instruction Hierarchy:**
    1. `instrucoes`: Global default from the exercise library.
    2. `instrucoes_personalizadas`: Trainer's persistent override for that specific exercise across all clients.
    3. `sessao_instrucoes`: Specific instruction for a single session instance.

## Developer Mindset and UI/UX Principles

*   **Staff-level Engineering:** Prioritize maintainability, scalability, and type safety.
*   **Premium Hybrid Aesthetic:** Our design language is an evolution of high-performance interfaces.
    *   **Spotify Inspiration:** We use Spotify as a reference for strong visual hierarchy, absolute contrast (Deep Black backgrounds), and pragmatic typography. We do not copy its flat layout; we use it as a benchmark for clarity and speed.
    *   **Modern Glassmorphism:** For top-level navigation (Bottom Nav) and critical floating actions, we adopt a hybrid approach using frosted glass effects (Blur + Translucency). This adds a layer of depth and technical sophistication (Apple/iOS style) over our solid industrial foundation.
    *   **Geometry:** Technical corners (Radius 12-16) for cards, and full pílula (pill) shapes (Radius 999) for floating navigation and main buttons.
    *   **SliverAppBar Header Standards (Staff-level):**
        *   **Dimensions:** Always use `expandedHeight: 110`. This height is calibrated to eliminate dead space while providing a high-density, professional look.
        *   **Typography:** Expanded headers MUST use `AppTheme.bigTitle` (Spotify-inspired: 28px, w900, -1.0 letter spacing). Collapsed headers MUST use `AppTheme.pageTitle` (Centered: 15px, w700, -0.5 letter spacing).
        *   **Casing:** Never use full UPPERCASE for page titles; use proper casing (e.g., 'Biblioteca de rotinas') for a more sophisticated look.
        *   **Clarity:** Always set `fadeTitle: false` in `FlexibleSpaceBar` and manage opacities manually using a `Stack` and `LayoutBuilder`. Expanded titles must have 100% opacity at the top to ensure high contrast and zero "foggy" effect.
        *   **Transition:** Use a clean cross-fade (Opacity) driven by scroll percentage. Avoid sliding or scaling animations. Expanded titles are fixed bottom-left (Positioned: left 20, bottom 16); collapsed titles are centered.
    *   **Atmospheric Design:** The UI should be a "silent tool". Use consistent spacing (SpacingTokens) and ergonomic touch targets (min 44px).
*   **Dirty Check Pattern:** Always implement `hasChanges` logic in complex forms to disable "Save" buttons and optimize network calls.
*   **Haptic Feedback:** Use `HapticFeedback.lightImpact()` for critical UI interactions (toggles, navigation, selections) to provide immediate tactile response.

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