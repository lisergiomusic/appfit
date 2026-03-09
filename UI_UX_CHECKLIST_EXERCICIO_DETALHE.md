# Checklist UI/UX - Exercicio Detalhe (Padrao Big Tech)

Objetivo: elevar a tela `lib/features/treinos/exercicio_detalhe_page.dart` ao nivel de consistencia, previsibilidade e qualidade percebida de produtos como Apple, Strava, Runna e Notion.

## Como usar este checklist
- Execute por prioridade (`P0` -> `P1` -> `P2`).
- Marque cada item somente quando cumprir os criterios de aceite.
- Sempre validar em telas pequenas e com teclado aberto.

## P0 - Critico (fazer primeiro)

### 1) Claridade do objetivo principal da tela
- [ ] Definir uma acao primaria dominante por estado da tela (editar series).
- [ ] Reduzir competicao visual entre video, instrucoes e tabela de series.
- [ ] Ajustar ordem de blocos para favorecer fluxo natural: contexto -> edicao -> acao.

Criterios de aceite:
- Usuario entende em ate 3 segundos qual e a principal tarefa da tela.
- Nao existem dois CTAs primarios concorrendo no mesmo viewport.

### 2) Modelo de edicao previsivel nos campos
- [x] Remover comportamento de limpar automaticamente o campo ao tocar.
- [ ] Manter valor existente ao focar; usuario edita de forma explicita.
- [ ] Confirmar comportamento consistente entre `REPS`, `PESO` e `DESCANSO`.
- [ ] Garantir commit claro em `onFieldSubmitted` e perda de foco (`onTapOutside`).

Criterios de aceite:
- Primeiro toque em campo nunca causa perda aparente de informacao.
- Usuario consegue editar 3 series seguidas sem erro de interacao.

### 3) Seguranca para acao destrutiva (deletar serie)
- [ ] Manter swipe para deletar com haptic.
- [ ] Adicionar `SnackBar` com acao `Desfazer` apos remover serie.
- [ ] Restaurar item na posicao original ao desfazer.

Criterios de aceite:
- Toda exclusao pode ser revertida imediatamente.
- Sem perda acidental de dados durante uso rapido.

### 4) Estados reais para video/imagem
- [ ] Tratar `imagemUrl` invalida com fallback local ou placeholder visual consistente.
- [ ] Evitar prometer acao nao implementada (ex.: "Abrindo video..." sem abrir nada).
- [ ] Se recurso nao existir, exibir estado "Indisponivel" com microcopy clara.

Criterios de aceite:
- Nenhum CTA gera expectativa falsa.
- Falha de rede nao quebra o layout nem a confianca.

## P1 - Alta prioridade (qualidade percebida)

### 5) Hierarquia visual e escaneabilidade da grade
- [ ] Reduzir densidade visual dos headers da tabela.
- [ ] Diferenciar melhor informacao primaria (valor) de secundaria (rotulo).
- [ ] Reforcar alinhamentos para leitura em bloco (colunas e baseline de texto).
- [ ] Padronizar pesos tipograficos e tamanhos (evitar variacoes sem funcao).

Criterios de aceite:
- Usuario interpreta uma linha de serie em menos de 2 segundos.
- A tela parece "limpa" mesmo com muitas series.

### 6) Acessibilidade de nivel produto maduro
- [ ] Garantir alvo minimo de toque (44x44) para todos os elementos interativos.
- [ ] Expandir `Semantics` para botoes, campos e acoes de swipe.
- [ ] Validar contraste de textos secundarios e estados de foco.
- [ ] Validar comportamento com fonte aumentada (text scale).
- [ ] Validar ordem de foco no teclado e leitor de tela.

Criterios de aceite:
- Fluxo completo utilizavel com TalkBack/VoiceOver.
- Sem truncamentos graves com acessibilidade de fonte.

### 7) Consistencia de Design System (`AppTheme`)
- [ ] Migrar cores hardcoded para tokens do `AppTheme` quando aplicavel.
- [ ] Migrar espacamentos/radius/tipografia soltos para tokens existentes.
- [ ] Definir tokens faltantes no tema antes de repetir constantes locais.

Criterios de aceite:
- Principais estilos da tela referenciam tokens do `AppTheme`.
- Mudancas de tema impactam a tela de forma previsivel.

## P2 - Refinamento premium

### 8) Microinteracoes e motion intencional
- [ ] Revisar duracoes/curvas para consistencia entre entradas e saidas.
- [ ] Evitar animacoes redundantes; manter apenas as que ajudam compreensao.
- [ ] Melhorar transicoes de estado (ex.: teclado aberto, inclusao/remocao de serie).

Criterios de aceite:
- Motion comunica estado, nao apenas "enfeita".
- Nao ha jank perceptivel em dispositivos medianos.

### 9) Microcopy de produto
- [ ] Revisar textos para linguagem orientada a acao e contexto.
- [ ] Padronizar tom e nomenclatura (serie, reps, peso, descanso, instrucoes).
- [ ] Reduzir ambiguidade em labels e helper texts.

Criterios de aceite:
- Textos curtos, claros e sem termos duplicados para a mesma acao.
- Usuario nao precisa "interpretar" o que cada acao faz.

### 10) Qualidade tecnica para evolucao
- [ ] Separar widgets grandes em componentes menores (header, video card, tabela, instrucoes).
- [ ] Cobrir fluxos criticos com testes de widget (edicao, exclusao com undo, acessibilidade basica).
- [ ] Validar com `flutter analyze` e `flutter test` sem regressao.

Criterios de aceite:
- Arquivo fica mais legivel e facil de manter.
- Fluxos principais possuem teste automatizado.

---

## Definicao de pronto (DoD)
- [ ] Fluxo de edicao totalmente previsivel e sem perda acidental.
- [ ] Exclusao com desfazer implementada.
- [ ] Hierarquia visual clara em todos os tamanhos de tela.
- [ ] Acessibilidade minima atendida (toque, contraste, semantics, text scale).
- [ ] Tokens do `AppTheme` aplicados de forma consistente.
- [ ] Testes e analise estaticas passando.

## Comandos de validacao
```bash
flutter analyze
flutter test
```

## Arquivo-alvo principal
- `lib/features/treinos/exercicio_detalhe_page.dart`
