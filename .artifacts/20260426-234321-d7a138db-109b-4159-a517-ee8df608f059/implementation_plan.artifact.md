# Redesign de UI: Botão "Concluir" Contextual (Header Action)

Substituir o ícone interno de "check" por uma ação de cabeçalho mais elegante e limpa, inspirada em apps premium que gerenciam formulários complexos.

## Proposta de Design (Staff UI/UX)

O ícone dentro do campo (suffixIcon) pode poluir o visual, especialmente em campos multi-linha.

### Nova Abordagem: Header Action
Em vez de colocar o botão *dentro* da caixa de texto, vamos colocá-lo **ao lado do rótulo (label)** do campo.

1.  **Estética**: O campo de texto permanece limpo e minimalista.
2.  **Visibilidade**: O botão "Concluir" (ou um ícone de check elegante) aparece no topo direito do campo apenas quando ele ganha o foco.
3.  **Hierarquia**: Mantém a hierarquia visual clara: Rótulo à esquerda, Ação à direita.

## Proposed Changes

### [Personal Feature]

#### [personal_editar_perfil_page.dart](file:///C:/Dev/Projetos/appfit/lib/features/alunos/personal/pages/personal_editar_perfil_page.dart)

- **Remover** o `suffixIcon` do `TextFormField` no método `_buildTextField`.
- **Adicionar** uma `Row` no topo do campo para conter o `Text(label)` e um `TextButton`/`IconButton` de conclusão.
- O botão de conclusão será animado ou aparecerá apenas via `Visibility` baseado no `focusNode.hasFocus`.

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(label, style: AppTheme.formLabel),
    if (focusNode != null && focusNode.hasFocus)
      GestureDetector(
        onTap: () => focusNode.unfocus(),
        child: const Text(
          'Concluir',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
  ],
),
```

## Plano de Verificação

### Verificação Manual
1.  **Foco**: Ao clicar no campo de Bio, o texto azul "Concluir" deve aparecer discretamente acima do campo, ao lado do nome "Especialidade".
2.  **Limpeza**: Confirmar que o interior do campo de texto não possui mais ícones de check.
3.  **Ação**: Clicar em "Concluir" e verificar se o teclado fecha corretamente.