class SpacingTokens {
  SpacingTokens._();

  // primitivos
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double xxl  = 24;

  // semânticos — formulários
  static const double labelToField    = sm;   // 8  — label → input
  static const double sectionGap        = xxl;  // 24 — entre grupos
  static const double formCounterTop      = xs;   // 4  — input → "0/40"

  // semânticos — listas
  static const double listItemGap         = sm;   // 8  — entre cards
  static const double listHorizontalPad   = lg;   // 16 — margem lateral da tela

  // semânticos — navegação
  static const double navBarVertical      = sm;   // 8  — padding vertical nav bar
  static const double sectionHeaderBottom = sm;   // 8  — header → conteúdo
  static const double navBarHeight = 44.0;
  static const double pageTopPadding = lg;
  static const double pageBottomPadding = xxl;
  static const double pageHorizontalPadding = lg;

  // semânticos — componentes
  static const double cardPaddingH        = lg;   // 16
  static const double cardPaddingV        = md;   // 12
  static const double segmentedPadding    = xs;   // 4  — padding interno do segmented
  static const double searchBarTopGap     = sm;   // 8  — título → search field
}