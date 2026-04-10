import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appfit/features/treinos/personal/pages/personal_exercicio_detalhe_page.dart';
import 'package:appfit/features/treinos/shared/models/exercicio_model.dart';
import 'package:appfit/features/treinos/shared/widgets/exercicio_detalhe/serie_row.dart';



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

Future<void> _swipePrimeiraSerie(WidgetTester tester) async {
  final dismissible = find.byType(Dismissible).first;
  final topLeft = tester.getTopLeft(dismissible);
  final size = tester.getSize(dismissible);
  final startPoint = Offset(topLeft.dx + 30, topLeft.dy + size.height / 2);
  await tester.dragFrom(startPoint, const Offset(-400, 0));
  await tester.pumpAndSettle();
}


void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('Renderização', () {
    testWidgets('exibe o nome do exercício no cabeçalho', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final ex = _makeExercicio();
      await tester.pumpWidget(_buildPage(ex));
      await tester.pumpAndSettle();

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

      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Não deve haver crash no primeiro frame após dismiss',
      );

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
