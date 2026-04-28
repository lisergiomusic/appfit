# Implementation Plan - Dirty Check for Exercise Details

Implement a "dirty check" in `PersonalExercicioDetalhePage` to disable/enable the "Salvar" button based on actual changes to exercise instructions and series. This aligns with the "Staff-level" engineering standards established for the session page.

## User Review Required

> [!NOTE]
> The saving responsibility remains atomic for the exercise, but the UI will now provide feedback on whether changes exist.

## Proposed Changes

### Treinos Feature

#### [exercicio_detalhe_controller.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/personal/controllers/exercicio_detalhe_controller.dart)

- Change from a plain class to `ChangeNotifier` to notify the UI of state changes.
- Store a deep clone of the initial `ExercicioItem` (including series and instructions) as a snapshot.
- Implement a `hasChanges` getter that performs a deep comparison between the current state and the snapshot.
- Update methods like `insertAt`, `deleteSerie`, `duplicateSerie`, and a new `updateInstructions` to call `notifyListeners()`.

#### [personal_exercicio_detalhe_page.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/personal/pages/personal_exercicio_detalhe_page.dart)

- Wrap the page in a `ChangeNotifierProvider` for the controller.
- Update the `AppBarTextButton` to use `controller.hasChanges` to determine its `onPressed` state.
- Update `PopScope` (if applicable) to handle clean exits vs save-required exits.
- Ensure that updating instructions via the bottom sheet correctly triggers the controller's change detection.

---

## Verification Plan

### Manual Verification
1. **Open Exercise Detail**: The "Salvar" button should be disabled (greyed out) initially.
2. **Edit Instructions**: Change the personalized instructions. The "Salvar" button should enable. Revert to original text; button should disable.
3. **Add/Delete/Duplicate Series**: Perform list operations. The button should enable.
4. **Modify Serie Values**: Change reps, weight, or rest time. The button should enable.
5. **Back Navigation**: Verify that exiting without changes is immediate, while exiting with changes follows the save flow.