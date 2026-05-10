# AppFit: Visual Identity & Design System (Staff-Level)

Este documento define os princípios fundamentais de design e as regras de implementação para manter a consistência visual "Premium Hybrid" do AppFit. **Qualquer agente ou desenvolvedor deve seguir estas diretrizes rigorosamente.**

---

## 1. A Estética "Premium Hybrid"
O AppFit combina duas referências de alto desempenho:
- **Spotify (Industrial Dark):** Fundo preto absoluto, contraste extremo, tipografia pesada e hierarquia clara.
- **Apple (Glassmorphism):** Profundidade, efeitos de desfoque (Blur), transparências sutis e micro-interações táteis.

### Cores Fundamentais
- **Background:** `#121212` (Pure Deep Black). Nunca use cinzas escuros para o fundo principal.
- **Primary:** `AppColors.primary` (Neon Green/Yellow). Usada para ações principais e destaque de progresso.
- **Surface:** `AppColors.surfaceDark`. Usada para cards e modais, sempre com opacidade sutil.
- **Labels:**
  - `labelPrimary`: Branco puro para títulos.
  - `labelSecondary`: Cinza suave para informações de suporte.

---

## 2. Tipografia e Tokens de Texto
Centralizamos a tipografia para evitar o uso de `copyWith` manual.

- **`AppTheme.bigTitle` (28px, w900, -1.0):** Usado em Headers expandidos (Golden Standard).
- **`AppTheme.pageTitle` (15px, w700, -0.5):** Usado em AppBars fixas ou Headers colapsados.
- **`AppTheme.overTitle` (10px, w800, letterSpacing 1.2):** Usado para subtítulos técnicos e labels curtas acima de títulos. **Sempre em UPPERCASE.**
- **`AppTheme.sectionHeader`:** Usado para títulos de seções dentro de uma página.

---

## 3. Componentes de Assinatura

### O "Golden Header" (SliverAppBar Standard)
Padrão obrigatório para páginas de detalhe e dashboards principais:
- **Altura Expandida:** 110px ou 140px (dependendo da densidade).
- **expandedTitleScale:** Sempre `1.0` (para evitar bugs de escala do Flutter).
- **Cross-Fade:** O título expandido (bottom-left) deve desaparecer suavemente enquanto o título da AppBar colapsada aparece ao centro.
- **Geometria:** Título fixado a `left: 20` e `bottom: 16`.

### AppPremiumFAB
O botão de ação principal flutuante:
- **Formato:** Pílula (Radius 999).
- **Micro-interação:** Deve usar `AnimatedScale`. Ao pressionar, encolhe para `0.95`. Ao soltar, volta para `1.0` com `HapticFeedback.lightImpact()`.
- **Modos:** Suporta `isFullWidth` para preencher a largura da tela (com margens de 20px).

### Premium Cards
- **Decoração:** `AppTheme.premiumCardDecoration`.
- **Borda:** 0.5px de espessura com 10% de opacidade.
- **Raio:** `AppTheme.radiusXL` (16px).
- **Efeito:** Glassmorphism leve em áreas de navegação (Bottom Nav).

---

## 4. Layout e Ritmo Visual
- **Espaçamento de Tela:** Margem horizontal padrão de `20px` (`AppTheme.paddingScreen`).
- **Gaps de Lista:** Use `SpacingTokens.listItemGap` entre cards.
- **Safe Area Inferior:** Sempre adicione um `SizedBox(height: 120)` ao final de listas com FAB para garantir que o conteúdo não seja obstruído.

---

## 5. Experiência do Usuário (UX)
- **Silent UI:** Use `labelSecondary` e `UPPERCASE` para labels que não devem gritar por atenção.
- **Frictionless Action:** Prefira **Auto-Save no Pop** (ao voltar) em vez de botões "Salvar" explícitos em telas de edição complexas.
- **Feedback Visual:** Use overlays de desfoque (BackdropFilter) e Shimmer skeletons durante carregamentos ou salvamentos assíncronos.

---
**Nota para Agentes:** Ao criar uma nova funcionalidade, consulte este arquivo e o `AppTheme.dart` antes de definir qualquer estilo manual. Priorize sempre a reutilização de tokens existentes.