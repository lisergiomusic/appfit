# 🚀 Plano de Implementação: Detalhe de Exercício Elite

Este documento detalha as melhorias estratégicas para elevar a página `PersonalExercicioDetalhePage` ao nível dos aplicativos de treino líderes de mercado (Hevy, Strong, Apple Fitness).

---

## 1. Visualização de Carga e Volume (Tonelagem)
**Conceito:** Exibir o custo metabólico total do exercício em tempo real.
- **Implementação:** No `ExercicioDetalheController`, criar um getter `totalVolume` que soma `reps * carga` de todas as séries.
- **UI:** Adicionar um pequeno badge ou texto sutil no cabeçalho (abaixo do nome do grupo muscular) com o ícone de peso 🏋️.
- **Impacto:** O Personal percebe o valor técnico do app ao planejar a progressão de carga.

## 2. Edição em Massa (Bulk Actions)
**Conceito:** Rapidez extrema na configuração de múltiplas séries.
- **Implementação:** Adicionar um menu de contexto (Pop-up Menu) no cabeçalho de cada seção (`SeriesSection`).
- **Ações:**
    - "Igualar Cargas": Aplica o valor da primeira série da seção em todas as outras.
    - "Igualar Descanso": Padroniza o tempo de recuperação da seção.
- **Impacto:** Reduz o tempo de edição de um treino complexo em até 40%.

## 3. Instruções Rápidas (Sticky Notes)
**Conceito:** Contexto técnico sem cliques extras.
- **UI:** Transformar as `instrucoesPersonalizadas` em um "Post-it" minimalista fixo no topo da lista de séries (ou logo abaixo do vídeo).
- **Funcionalidade:** Se estiver vazio, mostrar o botão de adicionar. Se preenchido, exibir os primeiros 80 caracteres com opção de "ver mais".
- **Impacto:** Garante que o Personal (e futuramente o aluno) visualize o detalhe técnico crucial do movimento imediatamente.

## 4. Feedback Háptico Refinado
**Conceito:** Sensação de aplicativo físico e responsivo.
- **Ação:** Implementar `HapticFeedback.selectionClick()` ao alternar o tipo de série e `HapticFeedback.mediumImpact()` ao salvar com sucesso.
- **Impacto:** Aumenta a percepção de qualidade premium do software através do tato.

---

## Próximos Passos Sugeridos
1. Começar pela **Tonelagem**, pois é uma mudança de lógica simples no Controller com grande impacto visual.
2. Seguir para o **Bulk Actions**, pois é a dor número 1 de quem monta muitos treinos.