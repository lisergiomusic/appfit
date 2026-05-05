# Refactor `AlunoHistoricoPage` Business Logic

The `AlunoHistoricoPage` currently contains business logic (log processing, monthly navigation, and stream caching) within its widget and state classes. This refactoring aims to move this logic to a dedicated `HistoricoController` to improve maintainability and follow the project's separation of concerns principle, while keeping the UI widgets within the same file as requested.

## Proposed Changes

### [Treinos Aluno Feature]

Move business logic to a new controller.

#### [NEW] [historico_controller.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/aluno/controllers/historico_controller.dart)
- New `ChangeNotifier` to manage state for the history page.
- **State Management:**
    - `DateTime mesAtual`: Currently viewed month.
    - `Stream<List<Map<String, dynamic>>> logsStream`: Current month's log stream.
    - `Stream<dynamic> pesoStream`: Weight history stream.
- **Logic:**
    - Monthly navigation (`irParaMesAnterior`, `irParaProximoMes`).
    - Stream caching to prevent flickering when switching months.
    - Log processing (`processarLogs`) to group logs by day for the calendar.
    - Weight registration logic (calling `AlunoService`).

#### [aluno_historico_page.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/aluno/pages/aluno_historico_page.dart)
- **State Simplification:** Remove `_streamsCache`, `_mesAtual`, `_logsStream`, and `_processarLogs` from the widgets.
- **Controller Integration:** Use `ChangeNotifierProvider` at the top level of the page.
- **Event Handling:** Update `_NavButton` taps and day taps to use methods from the `HistoricoController`.
- **Stream Integration:** Replace local `StreamBuilder` logic with data provided by the controller.
- **UI Retention:** All private widgets (`_HistoricoContent`, `_CalendarioFrequenciaCard`, `_DiaTreinosSheet`, etc.) will remain in this file.

---

## Verification Plan

### Manual Verification
- Open the "Meu histórico" page.
- Verify that the weight history card still displays correctly and allows registration.
- Navigate through months and verify the training frequency calendar updates correctly.
- Click on a day with training and verify the workout detail sheet (or multiple workouts sheet) opens correctly.
- Verify that the UI remains identical to the current version.