# Checklist de Melhorias de UI/UX - Página de Detalhe do Exercício

Este documento serve como um guia para implementar as melhorias de UI/UX sugeridas para a página `lib/features/treinos/exercicio_detalhe_page.dart`. As tarefas podem ser realizadas em qualquer ordem.

---

### ☐ 1. Refinar o Paradigma de Edição In-line

O objetivo é aumentar a clareza sobre o estado dos dados durante e após a edição de uma série.

- [ ] **Adicionar Feedback Visual Pós-Edição (Flash de Confirmação)**
  - **Tarefa:** Após uma alteração ser salva (`onTapOutside` ou `onFieldSubmitted`), acionar uma breve animação no card da série (ex: um "flash" de cor) para confirmar visualmente que a ação foi concluída com sucesso.
  - **Implementação:**
    1.  Crie um `AnimationController` de curta duração (e.g., 300-400ms).
    2.  Use um `ColorTween` para animar a cor do `BoxDecoration` do `Container` principal do `_buildSerieRow` (de `AppTheme.surfaceDark` para `AppTheme.accentMetrics.withAlpha(50)` e de volta).
    3.  Acione a animação no final das funções `_restorePreviousIfNoChange` e `_handleFieldChanged` quando uma edição for confirmada.

- [ ] **(Opcional/Avançado) Implementar Botão de Confirmação Explícito**
  - **Tarefa:** Em vez de salvar implicitamente, adicione botões de "Salvar" (ícone de check) e "Cancelar" (ícone 'X') que aparecem na linha quando ela entra em modo de edição.
  - **Implementação:**
    1.  Mantenha um `Set<int>` no `State` para armazenar o `hashCode` das séries que estão em modo de edição.
    2.  No `_buildSerieRow`, verifique se a série atual está no `Set`. Se estiver, renderize os botões de ação no final da linha.
    3.  A lógica de salvamento (`widget.onChanged()`) só será chamada ao pressionar o botão "Salvar". O botão "Cancelar" reverte os valores nos `TextEditingController`s para os valores originais.

---

### ☐ 2. Otimizar Fluxo de Adição de Séries

O objetivo é reduzir o número de passos para realizar a ação mais comum.

- [ ] **Implementar "Quick Add" por Seção**
  - **Tarefa:** Adicionar um botão `+ Adicionar` ou similar diretamente no cabeçalho de cada seção (`AQUECIMENTO`, `FEEDER`, `SÉRIES DE TRABALHO`).
  - **Implementação:**
    1.  No widget `_buildSeriesSection`, modifique o `Row` do cabeçalho da seção.
    2.  Adicione um `TextButton` ou `IconButton` (ex: `Icons.add_circle_outline`) ao lado do título da seção.
    3.  No `onPressed` desse botão, chame a lógica de `_adicionarSerie`, passando o `TipoSerie` correspondente àquela seção diretamente, pulando a exibição do `showModalBottomSheet`.

---

### ☐ 3. Melhorar a Edição de Instruções

O objetivo é tornar a ação de salvar mais proeminente e contextual.

- [ ] **Criar Ação de Confirmação Contextual para Instruções**
  - **Tarefa:** Quando o campo de texto "Instruções" estiver em foco, o botão de ação principal da tela (`OrangeGlassActionButton`) deve mudar sua função e texto de "Adicionar Série" para "Salvar Instruções".
  - **Implementação:**
    1.  No método `build`, verifique o estado `_instructionsFocusNode.hasFocus`.
    2.  Use uma variável para determinar o `label` e a função `onTap` do `OrangeGlassActionButton`.
    3.  Se o campo de instruções estiver focado, o `onTap` deve chamar um método que salva as alterações (`_saveInstructions()`) e remove o foco (`_instructionsFocusNode.unfocus()`).

---

### ☐ 4. Aumentar a Ergonomia da Interface

O objetivo é tornar os alvos de toque maiores e mais confortáveis, reduzindo a chance de erros.

- [ ] **Aumentar Espaçamento Vertical e Alvos de Toque**
  - **Tarefa:** Aumentar o padding interno dos campos de edição e o espaçamento geral das linhas das séries.
  - **Implementação:**
    1.  Na função `_editableFieldDecoration`, aumente o `contentPadding` vertical (ex: de 6 para 8 ou 10).
    2.  No widget `_buildSerieRow`, aumente o `padding` vertical do `Padding` que envolve a `Row` principal (ex: de 4 para 6).
    3.  Avalie o resultado visual e ajuste os valores conforme necessário para encontrar um bom equilíbrio entre densidade e ergonomia.
