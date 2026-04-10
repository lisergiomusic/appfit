import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appfit/features/treinos/personal/pages/personal_exercicio_detalhe_page.dart';
import 'package:appfit/features/treinos/shared/models/exercicio_model.dart';
import 'package:appfit/features/treinos/shared/widgets/exercicio_detalhe/serie_row.dart';

// ─────────────────────────────────────────────────────────────────────────────
// POR QUE USAMOS dragFrom E NÃO tester.drag?
//
// tester.drag(finder, offset) faz o gesto a partir do CENTRO do widget.
// O centro de uma SerieRow cai em cima de um TextField (campo de reps/carga).
// O TextField participa do "gesture arena" e CAPTURA o gesto horizontal
// para seleção de texto — o Dismissible nunca recebe o evento.
//
// A solução: arrastar a partir da área do BADGE NUMÉRICO (lado esquerdo da
// linha), onde não há TextField. Usamos tester.getTopLeft() para calcular
// a posição real do widget dinamicamente, sem hardcode de coordenadas.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

ExercicioItem _makeExercicio({
  int numSeries = 2,
  TipoSerie tipo = TipoSerie.trabalho,
}) {
  return ExercicioItem(
    nome: 'Supino Reto',
    grupoMuscular: ['Peito'],
    series: List.generate(
      numSeries,
      (i) => SerieItem(
        tipo: tipo,
        alvo: '${8 + i}',
        carga: '${60 - i * 5}kg',
        descanso: '90s',
      ),
    ),
  );
}

Widget _buildPage(ExercicioItem ex, {VoidCallback? onChanged}) {
  return MaterialApp(
    home: PersonalExercicioDetalhePage(
      exercicio: ex,
      onChanged: onChanged ?? () {},
    ),
  );
}

/// Faz swipe para esquerda na PRIMEIRA série visível.
///
/// Arrasta a partir do LADO ESQUERDO do Dismissible (badge numérico),
/// porque o centro do widget cai sobre um TextField que captura o gesto.
///
/// Como funciona o cálculo:
///   - getTopLeft() devolve a posição (x, y) do canto superior esquerdo
///   - dx + 30  → 30px do lado esquerdo (região do badge numérico)
///   - dy + altura/2 → centro vertical da linha
///   - Offset(-400, 0) → arrasta 400px para a esquerda
Future<void> _swipePrimeiraSerie(WidgetTester tester) async {
  final dismissible = find.byType(Dismissible).first;
  final topLeft = tester.getTopLeft(dismissible);
  final size = tester.getSize(dismissible);
  final startPoint = Offset(topLeft.dx + 30, topLeft.dy + size.height / 2);
  await tester.dragFrom(startPoint, const Offset(-400, 0));
  await tester.pumpAndSettle();
}

// ─────────────────────────────────────────────────────────────────────────────
// TESTES
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // Tamanho de tela fixo para todos os testes (simula iPhone 14)
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  // ───────────────────────────────────────────────────────────────────────────
  // GRUPO 1 — Renderização básica
  // ───────────────────────────────────────────────────────────────────────────
  group('Renderização', () {
    testWidgets('exibe o nome do exercício no cabeçalho', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final ex = _makeExercicio();
      await tester.pumpWidget(_buildPage(ex));
      await tester.pumpAndSettle();

      // findsWidgets: o nome aparece tanto no AppBar compacto quanto
      // no fundo expandido do SliverAppBar — são dois Text widgets distintos
      expect(find.text('Supino Reto'), findsWidgets);
    });

    testWidgets('exibe estado vazio quando não há séries', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final ex = _makeExercicio(numSeries: 0);
      await tester.pumpWidget(_buildPage(ex));
      await tester.pumpAndSettle();

      expect(find.text('Prescreva o exercício'), findsOneWidget);
    });

    testWidgets('exibe uma SerieRow por série', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final ex = _makeExercicio(numSeries: 3);
      await tester.pumpWidget(_buildPage(ex));
      await tester.pumpAndSettle();

      expect(find.byType(SerieRow), findsNWidgets(3));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // GRUPO 2 — Swipe para remover série
  //
  // ESTE GRUPO TERIA CAPTURADO O BUG QUE CORRIGIMOS.
  //
  // O bug: setState era chamado ANTES de AnimatedList.removeItem().
  // Isso forçava o Flutter a reconstruir o Dismissible no estado "dismissed"
  // enquanto ele ainda estava na árvore → assertion error no Flutter.
  //
  // Como o teste captura o bug:
  //   1. tester.dragFrom() simula o swipe → dispara onDismissed
  //   2. onDismissed chama _onDeleteSerie()
  //   3. _onDeleteSerie() chama setState() ANTES de removeItem() [bug]
  //   4. Flutter reconstrói a árvore com o Dismissible em estado dismissed
  //   5. Flutter lança uma FlutterError/assertion → o teste falha
  //   6. tester.takeException() retorna o erro, expect(null) detecta
  // ───────────────────────────────────────────────────────────────────────────
  group('Swipe para remover série', () {
    testWidgets('swipe não lança exception — regressão do bug do Dismissible', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final ex = _makeExercicio(numSeries: 2);
      await tester.pumpWidget(_buildPage(ex));
      await tester.pumpAndSettle();

      final dismissible = find.byType(Dismissible).first;
      final topLeft = tester.getTopLeft(dismissible);
      final size = tester.getSize(dismissible);
      final startPoint = Offset(topLeft.dx + 30, topLeft.dy + size.height / 2);

      await tester.dragFrom(startPoint, const Offset(-400, 0));

      // pump() avança EXATAMENTE UM FRAME.
      // Era nesse frame que o crash acontecia antes da correção:
      // o Dismissible era reconstruído em estado "dismissed" enquanto
      // ainda estava na árvore.
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Não deve haver crash no primeiro frame após dismiss',
      );

      // Aguarda todas as animações terminarem
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Não deve haver crash após animações',
      );
    });

    testWidgets('swipe remove a série do modelo de dados', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final ex = _makeExercicio(numSeries: 2);
      await tester.pumpWidget(_buildPage(ex));
      await tester.pumpAndSettle();

      await _swipePrimeiraSerie(tester);

      expect(ex.series.length, 1);
    });

    testWidgets('swipe remove a SerieRow da tela', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final ex = _makeExercicio(numSeries: 2);
      await tester.pumpWidget(_buildPage(ex));
      await tester.pumpAndSettle();

      expect(find.byType(SerieRow), findsNWidgets(2));

      await _swipePrimeiraSerie(tester);

      expect(find.byType(SerieRow), findsNWidgets(1));
    });

    testWidgets('remover a última série exibe estado vazio', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final ex = _makeExercicio(numSeries: 1);
      await tester.pumpWidget(_buildPage(ex));
      await tester.pumpAndSettle();

      await _swipePrimeiraSerie(tester);

      expect(find.text('Prescreva o exercício'), findsOneWidget);
      expect(find.byType(SerieRow), findsNothing);
    });

    testWidgets('swipe chama onChanged', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final ex = _makeExercicio(numSeries: 2);
      var chamadas = 0;
      await tester.pumpWidget(_buildPage(ex, onChanged: () => chamadas++));
      await tester.pumpAndSettle();

      await _swipePrimeiraSerie(tester);

      expect(chamadas, greaterThan(0));
    });

    testWidgets('remover todas as séries uma por uma não causa crash', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final ex = _makeExercicio(numSeries: 3);
      await tester.pumpWidget(_buildPage(ex));
      await tester.pumpAndSettle();

      for (var i = 3; i > 0; i--) {
        expect(find.byType(SerieRow), findsNWidgets(i));
        await _swipePrimeiraSerie(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: 'crash na remoção da série $i',
        );
      }

      expect(find.text('Prescreva o exercício'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // GRUPO 3 — SnackBar "DESFAZER"
  //
  // A ExercicioDetalhePage usa um ScaffoldMessenger PRÓPRIO (com key interna)
  // para isolar os SnackBars. Por isso find.text() ainda funciona — ele busca
  // na árvore inteira, incluindo esse ScaffoldMessenger interno.
  // ───────────────────────────────────────────────────────────────────────────
  group('SnackBar DESFAZER após remoção', () {
    testWidgets('snackbar "Série removida" aparece após swipe', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final ex = _makeExercicio(numSeries: 2);
      await tester.pumpWidget(_buildPage(ex));
      await tester.pumpAndSettle();

      await _swipePrimeiraSerie(tester);

      expect(find.text('Série removida'), findsOneWidget);
      expect(find.text('DESFAZER'), findsOneWidget);
    });

    testWidgets('tocar DESFAZER restaura a série removida na lista', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final ex = _makeExercicio(numSeries: 2);
      await tester.pumpWidget(_buildPage(ex));
      await tester.pumpAndSettle();

      await _swipePrimeiraSerie(tester);
      expect(ex.series.length, 1);

      await tester.tap(find.text('DESFAZER'));
      await tester.pumpAndSettle();

      expect(ex.series.length, 2);
      expect(find.byType(SerieRow), findsNWidgets(2));
    });

    testWidgets('tocar DESFAZER não causa exception', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final ex = _makeExercicio(numSeries: 2);
      await tester.pumpWidget(_buildPage(ex));
      await tester.pumpAndSettle();

      await _swipePrimeiraSerie(tester);
      await tester.tap(find.text('DESFAZER'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
