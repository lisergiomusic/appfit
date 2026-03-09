# Review: ExercicioDetalhePage

**Arquivo:** `lib/features/treinos/exercicio_detalhe_page.dart`  
**Data:** 09/03/2026

---

## ✅ Pontos Positivos Implementados

- [x] **AnimatedList** para séries com animações suaves de entrada/remoção (300ms)
- [x] **Micro-animations** no título colapsado (fade + slide com AnimatedSwitcher)
- [x] **SnackBar com undo** para remoção de séries (4s + ação "Desfazer")
- [x] **Haptic feedback** progressivo no swipe-to-dismiss (threshold 0.45)
- [x] **Input formatters** customizados (`_CargaKgInputFormatter`, `_DescansoSecondsInputFormatter`)
- [x] **Semantics** básicos adicionados (título, botões, campos de instruções, vídeo)
- [x] **Controllers estáveis** usando `hashCode` para manter estado em AnimatedList
- [x] **Shadows padronizados** (blur 12, offset 2) seguindo guia de marca
- [x] **Inline editing** para instruções com indicador "Concluir" condicional
- [x] **SafeArea** implementado para Android nav bar
- [x] **Theme tokens** migrados para Material Dark (#121212, #1E1E1E)

---

## 🔧 Melhorias Necessárias

### 🐛 Bugs e Correções Urgentes

- [x] **Crash 'Dismissible' durante remoção**: Corrigido com ghost row (`_buildRemovedSerieRow()`) e lock de mutações

- [ ] **Edge case no AnimatedList**: `entries.first.value.tipo` pode lançar exception se lista estiver vazia
 - [x] **Edge case no AnimatedList**: `entries.first.value.tipo` pode lançar exception se lista estiver vazia
  - **Localização:** Linha ~987 (`_buildSeriesSection`)
  - **Solução:** Adicionar guard clause ou usar tipo como parâmetro direto

- [ ] **Performance**: `ex.series.indexOf(serie)` chamado em cada rebuild do AnimatedList
  - **Localização:** Linha ~1006 (itemBuilder)
  - **Impacto:** O(n) por item = O(n²) total
  - **Solução:** Passar `realIndex` via closure ou computar uma vez

### 📝 Code Quality

- [ ] **Warnings do analyzer** (18 issues):
  - [x] `if` sem chaves (linhas 383, 385)
  - [x] Interpolações desnecessárias `${}` (linhas 511, 512, 513)
  - [x] Underscores múltiplos desnecessários (linha 1421)

- [ ] **Código duplicado**: Lógica repetida 3x nos campos de série (reps/carga/descanso)
  - **Localização:** Linhas 660-840
  - **Sugestão:** Extrair para `_buildEditableSerieField()` helper

- [ ] **Magic numbers**: Valores hardcoded poderiam ser constantes
  - `0.45` (dismiss threshold)
  - `300` (animation duration ms)
  - `220` (title animation ms)
  - `0.08` (slide offset)

### ♿ Acessibilidade

- [ ] **Semantics incompletos** em campos editáveis de séries
  - Faltam labels para reps/carga/descanso
  - Faltam hints de interação ("Deslize para remover")
  
- [ ] **Contraste insuficiente** em alguns textos secundários
  - `withAlpha(120)` no hint de instruções pode estar abaixo WCAG AA

- [ ] **Touch targets** em campos pequenos podem estar < 44x44
  - Verificar em device real

### 🎨 UX & UI

- [x] **Feedback visual ausente** ao adicionar série (scroll automático + subtle highlight)

- [ ] **Contador de caracteres** opcional para campo de instruções
  - Útil se houver limite de caracteres

- [ ] **Loading state** para imagem do vídeo ausente
  - Atualmente mostra placeholder apenas em erro
  - **Sugestão:** Adicionar `loadingBuilder` com shimmer/spinner

- [ ] **Empty state** quando não há séries
  - Atualmente só mostra botão "Adicionar Série"
  - **Sugestão:** Ilustração + texto motivacional

- [ ] **Ordem das séries** não é editável (drag to reorder)
  - Considerar `ReorderableListView` como evolução futura

### 🏗️ Arquitetura & Manutenibilidade

- [ ] **Lógica de negócio no widget**: Estado muito acoplado à UI
  - **Sugestão:** Extrair para `ExercicioDetalheController` ou ViewModel

- [ ] **Gerenciamento de controllers**: Map manual de TextEditingController é frágil
  - **Alternativa:** Considerar `Form` + `GlobalKey<FormState>`

- [ ] **Testes unitários ausentes**
  - Formatters (`_CargaKgInputFormatter`, `_DescansoSecondsInputFormatter`)
  - Lógica de undo/redo
  - Animação de inserção/remoção

- [ ] **Testes de widget ausentes**
  - Fluxo completo de adicionar/remover série
  - Interação com campos editáveis
  - Swipe to dismiss

### ⚡ Performance

- [ ] **Controllers não dispostos** ao remover séries do meio da lista
  - `_clearEditingState()` remove todos, mas pode deixar órfãos se remoção for parcial

- [ ] **Rebuild desnecessário**: `build()` recomputa `warmupEntries`, `feederEntries`, `workEntries` a cada setState
  - **Sugestão:** Usar `useMemoized` ou computar apenas quando `ex.series` mudar

- [ ] **Image.network sem cache config**: Pode recarregar imagem a cada rebuild
  - **Sugestão:** Adicionar `cacheWidth`/`cacheHeight`

---

## 🎯 Priorização

-### P0 - Crítico (Deve ser feito antes de release)
- [x] Corrigir edge case `entries.first` no AnimatedList
- [x] Resolver warnings do analyzer (curly braces, interpolations)
- [ ] Fix performance O(n²) no indexOf dentro do AnimatedList

### P1 - Importante (Próxima iteração)
- [ ] Adicionar Semantics completos nos campos de série
- [ ] Extrair código duplicado dos TextFormFields
- [ ] Adicionar loading state na imagem do vídeo
- [ ] Testes unitários dos formatters

### P2 - Nice to Have (Backlog)
- [ ] Extrair lógica para controller/ViewModel
- [ ] Drag to reorder séries
- [ ] Empty state ilustrado
- [ ] Contador de caracteres em instruções
- [x] Smooth scroll ao adicionar série

---

## 📊 Métricas

- **Linhas de código:** ~1450
- **Complexidade ciclomática estimada:** Alta (muitos ifs aninhados e callbacks)
- **Cobertura de testes:** 0%
- **Issues do analyzer:** 18 (todos info-level)
- **Tempo estimado de refactor P0:** 4-6 horas
- **Tempo estimado de refactor P1:** 8-12 horas

---

## 💡 Sugestões de Arquitetura Futura

1. **View Model Pattern:**
   ```dart
   class ExercicioDetalheViewModel extends ChangeNotifier {
     final ExercicioItem exercicio;
     final AnimatedListController aquecimentoList;
     final AnimatedListController feederList;
     final AnimatedListController trabalhoList;
     
     void adicionarSerie(TipoSerie tipo) { ... }
     void removerSerie(SerieItem serie) { ... }
     Future<void> desfazerRemocao() { ... }
   }
   ```

2. **Widget Extraction:**
   - `_SerieEditableField` (reutilizável)
   - `_SerieRowCard` (container isolado)
   - `_SectionHeader` (título + ícone/dot)

3. **Service Layer:**
   - `ExercicioService` para persistência
   - `HapticService` para feedback tátil centralizado

---

## 🔗 Referências

- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Accessibility Guidelines](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [Material Design Motion](https://m3.material.io/styles/motion/overview)

---

**Revisado por:** GitHub Copilot (Claude Sonnet 4.5)  
**Status:** ✅ Pronto para discussão
