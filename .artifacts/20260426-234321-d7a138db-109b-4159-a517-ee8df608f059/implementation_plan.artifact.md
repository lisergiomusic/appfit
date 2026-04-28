# Refinamento de Fluxo: Modo Visualização vs Seleção (Detalhes do Exercício)

Garantir que a página de detalhes do exercício (`PersonalExercicioViewPage`) respeite o contexto de navegação, ocultando botões de ação de treino quando acessada via configurações.

## Proposta de Solução (Staff UI/UX)

Propagar a flag `isSelectionMode` da Biblioteca para a página de Detalhes.

### Comportamento no Modo Gestão (`isSelectionMode = false`):
*   **Ocultar**: O botão inferior "Adicionar ao Treino" / "Remover do Treino".
*   **Layout**: A lista de detalhes ocupará todo o espaço vertical disponível, sem a barra de ação fixa no rodapé.

### Comportamento no Modo Seleção (`isSelectionMode = true`):
*   **Manter**: O botão inferior para alternar a seleção do exercício para o treino atual.

## Proposed Changes

### [Workout Features]

#### [personal_exercicio_view_page.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/personal/pages/personal_exercicio_view_page.dart)

- Adicionar `final bool isSelectionMode;` ao construtor (padrão `false`).
- Condicionalizar a exibição do `Container` inferior que contém o `ElevatedButton`.

#### [personal_exercicios_library_page.dart](file:///C:/Dev/Projetos/appfit/lib/features/treinos/personal/pages/personal_exercicios_library_page.dart)

- Atualizar a chamada `_mostrarPreviewExercicio` para passar o valor de `widget.isSelectionMode`.

## Plano de Verificação

### Verificação Manual
1.  **Ajustes -> Biblioteca**: Abrir um exercício e confirmar que o botão "Adicionar ao Treino" no rodapé **não** aparece.
2.  **Montagem de Treino**: Abrir um exercício e confirmar que o botão aparece e funciona normalmente para selecionar/remover.