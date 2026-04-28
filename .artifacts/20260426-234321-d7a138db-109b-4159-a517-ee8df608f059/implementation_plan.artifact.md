# Implementation Plan - Dirty Check for Session Details

Implement a "dirty check" mechanism in `PersonalSessaoDetalhePage` to disable the "Salvar" button when no changes have been made. This improves UX by preventing redundant network calls and clarifying the state of the data.

## User Review Required

> [!NOTE]
> The `PopScope` will now only trigger the save flow if `hasChanges` is true. If the user tries to go back without changes, it will pop immediately without showing any "Saving" state.

## Proposed Changes

### Treinos Feature

#### [configurar_treino_controller.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/personal/controllers/configurar_treino_controller.dart)

- Implement a robust `_checkDirty()` method that evaluates **Session-level** changes only:
    - **Nome**: Current vs Initial.
    - **Nota**: Current vs Initial.
    - **Lista de Exercícios (Estrutura/Ordem)**: Compare current exercise IDs and their order against a snapshot of the initial state.
- **Clarification**: Individual exercise internal data (series, reps) is saved locally/automatically within `PersonalExercicioDetalhePage`. This "Salvar" button at the session level is strictly for persisting the session's metadata and exercise composition to Firebase.
- Add `_initialExercicioIds` to store the initial order and set of exercises.
- Update `hasChanges` logic to dynamically check these conditions.

#### [personal_sessao_detalhe_page.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/personal/pages/personal_sessao_detalhe_page.dart)

- Update the `AppBarTextButton` to use `controller.hasChanges` for its `onPressed` logic.
- Update `PopScope` to check `controller.hasChanges` before calling `_concluirESalvar`.
- Ensure that when returning from `PersonalExercicioDetalhePage`, the session page reflects any UI updates, but `hasChanges` for the session itself remains `false` unless the structure changed.

```dart
AppBarTextButton(
  label: 'Salvar',
  isLoading: _isSaving,
  onPressed: (_isSaving || !controller.hasChanges)
      ? null
      : () => _concluirESalvar(context),
),
```

---

## Verification Plan

### Automated Tests
- No automated tests available for this specific UI state; will use manual verification.

### Manual Verification
1. **Open Session Detail**: The "Salvar" button should be disabled (greyed out) initially.
2. **Edit Name**: Change the session name. The "Salvar" button should enable. Revert the name to the original. The button should disable again.
3. **Edit Note**: Change the note. The button should enable.
4. **Modify Exercises**: Add, delete, or reorder exercises. The button should enable.
5. **Auto-Save Verification**: Verify that after editing an individual exercise (which triggers auto-save in the current implementation), the `hasChanges` state is correctly handled (should probably be reset to false if the parent persists it).
6. **Pop Behavior**: Press the back button without changes; it should exit immediately. Press after changes; it should trigger the save flow.