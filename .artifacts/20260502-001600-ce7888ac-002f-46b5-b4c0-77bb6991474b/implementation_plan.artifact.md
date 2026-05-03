# Implementation Plan: Premium Exercise Detail Header Refactor

Refactor the exercise detail page header to prioritize technical info for Personal Trainers, making the video a compact, secondary element that expands on demand.

## Proposed Changes

### [UI/UX] [personal_exercicio_detalhe_page.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/personal/pages/personal_exercicio_detalhe_page.dart)

- **Compact Header Row**: Replace the vertical stack in the AppBar background with a Row layout.
    - Left side: Large bold title and muscle group badges.
    - Right side: Mini video thumbnail (16:9) with glassmorphism effects.
- **Media Expansion**: Implement a high-end full-screen player overlay triggered by tapping the mini thumbnail.
- **Visual Polish**:
    - Enhanced typography for the title.
    - Refined badge designs.
    - Improved spacing using `SpacingTokens`.
- **Logic Cleanup**: Remove the large `ExerciseVideoCard` from the main scroll body to save screen real estate.

### [NEW] [exercise_spotlight_overlay.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/shared/widgets/exercicio_detalhe/exercise_spotlight_overlay.dart)

- High-performance, fullscreen video player with glass controls and backdrop blur.
- Support for Hero transition from the mini thumbnail.

## Verification Plan

### Manual Verification
- Verify the header looks balanced on different screen sizes (using LayoutBuilder).
- Test the video expansion transition (smoothness and UX).
- Ensure muscle group badges wrap correctly if there are many.
- Check that "Save" and "Back" buttons remain functional and visible.