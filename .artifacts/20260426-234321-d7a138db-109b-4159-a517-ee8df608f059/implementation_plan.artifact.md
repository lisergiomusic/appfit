# Correção de Fluxo: Modo Gestão vs Modo Seleção (Biblioteca)

Garantir que a Biblioteca de Exercícios se comporte de forma adequada ao contexto de uso (Gestão nos Ajustes vs Seleção na Montagem de Treino).

## Proposta de Solução (Staff UX)

Implementar uma flag `isSelectionMode` na `PersonalExerciciosLibraryPage` para alternar entre as duas experiências.

### Comportamento no Modo Gestão (`isSelectionMode = false`):
*   **Remover**: Checkboxes de seleção nos cards.
*   **Remover**: Botão flutuante (FloatingActionButton) de "Ver lista / Salvar".
*   **Ação**: O clique no card abre apenas a visualização/edição do exercício.

### Comportamento no Modo Seleção (`isSelectionMode = true`):
*   **Manter**: Todo o fluxo atual de seleção múltipla e confirmação.

## Proposed Changes

### [Workout Features]

#### [personal_exercicios_library_page.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/personal/pages/personal_exercicios_library_page.dart)

- Adicionar `final bool isSelectionMode;` ao construtor (padrão `false`).
- Condicionalizar a exibição do `GestureDetector` (checkbox) nos cards.
- Condicionalizar o `floatingActionButton`.
- Ajustar o `onTap` do card para não alternar seleção se não estiver em modo de seleção.

#### [personal_sessao_detalhe_page.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/personal/pages/personal_sessao_detalhe_page.dart)

- Passar `isSelectionMode: true` ao abrir a biblioteca para montagem de treino.

## Plano de Verificação

### Verificação Manual
1.  **Ajustes**: Abrir via "Biblioteca" nos Ajustes e confirmar que NÃO aparecem círculos de seleção nem o botão de Salvar.
2.  **Montagem de Treino**: Abrir via criação de treino e confirmar que o fluxo de seleção múltipla continua funcionando normalmente.