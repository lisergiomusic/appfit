# Relatório de Review: ConfigurarExerciciosPage

**Autor:** Gemini Code Assist (Perfil Senior Flutter & UI/UX)
**Data:** 13 de Março de 2026
**Arquivo Analisado:** `lib/features/treinos/configurar_exercicios_page.dart`

## 1. Visão Geral
A página implementa uma lista reordenável de exercícios com funcionalidades de edição de título e observações gerais. O uso de `CustomScrollView` e `Slivers` demonstra um nível avançado de conhecimento de layout em Flutter, permitindo cabeçalhos expansíveis e listas eficientes.

## 2. Pontos Fortes (Highlights)

*   **Feedback Tátil e Visual:** O uso de `HapticFeedback.lightImpact()` e as animações de escala (`ScaleTransition`) durante o reordenamento e na exibição do FAB elevam a percepção de qualidade do app.
*   **Prevenção de Erros:** A implementação do `_onBackPressed` interceptando a navegação quando há mudanças não salvas (`_hasChanges`) é uma excelente prática de UX (Heurística de Nielsen: Prevenção de erros).
*   **Layout Responsivo:** A lógica `isKeyboardVisible` para ocultar o FAB quando o teclado abre evita que o botão flutuante cubra campos de texto ou quebre o layout.
*   **Micro-interações:** A transição do título entre modo de visualização e edição (`TextField` vs `Text`) é funcional e intuitiva.

## 3. Problemas Críticos e Bugs Potenciais

### 3.1. Chaves de Identificação Instáveis (Bug Lógico/UX)
**Onde:** `_buildExercicioCard` -> `key: ValueKey('${ex.nome}_$exIndex')`
**O Problema:** Em listas reordenáveis (`ReorderableList`), as `Keys` devem ser únicas e **estáveis**. Ao incluir o `index` na chave, a identidade do widget muda assim que ele muda de posição.
**Impacto UX:** Isso confunde o framework durante a animação de "drag & drop", podendo causar "pulos" visuais, perda de estado interno do item ou falha na animação de troca.
**Solução:** O modelo `ExercicioItem` deve ter um ID único (UUID) gerado na criação. A Key deve ser `ValueKey(ex.id)`.

### 3.2. Touch Targets (Acessibilidade)
**Onde:** Ícone de arrastar (`Icons.drag_indicator`) e botão de check no AppBar.
**O Problema:** Alguns alvos de toque parecem depender apenas do tamanho do ícone.
**Recomendação:** Garantir que todos os `InkWell` ou `GestureDetector` tenham uma área de toque mínima de 48x48dp (padrão Material/Apple), usando `padding` transparente se necessário.

## 4. Sugestões de Melhoria de UI/UX

### 4.1. Empty State (Estado Vazio)
O estado vazio atual é informativo, mas passivo.
*   **Sugestão:** Adicionar uma seta animada ou um botão "call-to-action" (CTA) evidente no centro da tela vazia, além do FAB, para reduzir a carga cognitiva de "onde clico agora?".

### 4.2. Editor de Notas
O `_NoteEditorModal` é visualmente agradável, mas o uso de `showGeneralDialog` com uma construção totalmente manual pode ser trabalhoso para manter.
*   **Sugestão:** Considerar o uso de `showModalBottomSheet` com `isScrollControlled: true`. É um padrão mais nativo em mobile para entrada de dados secundária, permitindo que o usuário arraste para fechar.

### 4.3. Feedback de Exclusão
O diálogo de confirmação (`AlertDialog`) para remover cada exercício é seguro, mas pode tornar o fluxo lento se o usuário quiser remover vários itens.
*   **Sugestão (Padrão Gmail/Photos):** Permitir a exclusão direta (sem diálogo) e mostrar uma `SnackBar` com botão "Desfazer" por 3 a 5 segundos. Isso agiliza o fluxo mantendo a segurança.

## 5. Refatoração de Código (Clean Code)

*   **Extração de Widgets:** O arquivo contém 3 classes (`_ConfigurarExerciciosPageState`, `_SessaoNoteWidget`, `_NoteEditorModal`). As duas últimas deveriam ser extraídas para arquivos próprios na pasta `widgets` ou `components`. Isso melhora a legibilidade da página principal.
*   **Separação de Lógica:** A lógica de reordenação e conversão de modelos está misturada na UI. Idealmente, mover a gestão da lista (`_exerciciosLocais`) para um `Controller` ou `Store` separado (mesmo que seja um simples `ChangeNotifier` local).

## 6. Plano de Ação Recomendado

1.  **Imediato:** Corrigir a geração da `Key` na lista reordenável (remover dependência do index).
2.  **Curto Prazo:** Extrair `_SessaoNoteWidget` e `_NoteEditorModal` para arquivos separados.
3.  **Refinamento:** Substituir o diálogo de exclusão por SnackBar com Undo.

---
*Fim do relatório.*