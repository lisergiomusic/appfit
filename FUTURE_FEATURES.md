# Future Features & Roadmap - AppFit

This document tracks planned features, architectural improvements, and brainstormed ideas for future development cycles.

## 1. Bi-sets / Super-sets (Slot Grouping)
**Goal:** Allow trainers to group two or more exercises to be performed sequentially without rest.

### Proposed Implementation (The "Visual Connector" approach)
- **Data Model:** Add `bool isSupersetWithNext` to `ExercicioItem` (or a `groupId`).
- **Personal UI:**
    - Kebab menu option: "Agrupar com o próximo (Bi-set)".
    - Visual: Remove spacing between grouped cards and add a vertical "connector line" between thumbnails.
    - Drag-and-drop: Ensure grouped exercises move together or provide a way to "unbound" them.
- **Student UI:**
    - Flow: Exercise A (Set 1) -> No Rest -> Exercise B (Set 1) -> Start Rest Timer.
    - Smart Equalization: Suggest the same number of sets for all exercises in the group.

## 2. Advanced Slot Flex (Student Side)
**Goal:** Allow students to swap between the primary exercise and its alternatives during the workout.

- **UI:** A "Swap" icon on the workout execution card.
- **Logic:** History tracking must correctly attribute the load and reps to the specific exercise performed (Primary vs. Alt 1 vs. Alt 2).

## 3. Global History & PR (Personal Record) Tracking
**Goal:** Show the student's progress and all-time bests during exercise execution.

- **UI:** Small badge or line chart in the series section showing the "Last performance" or "Personal Best".

## 4. Audio/Voice Coaching
**Goal:** Voice commands for rest timer and next exercise.

---
*Last updated: 2024-05-03*