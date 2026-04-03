import 'package:appfit/core/services/rotina_service.dart';
import 'package:appfit/features/treinos/rotina_detalhe_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRotinaService extends Mock implements RotinaService {}

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  Map<String, dynamic> rotinaDataBase() => {
    'nome': 'Rotina Base',
    'objetivo': 'Objetivo Base',
    'tipoVencimento': 'sessoes',
    'vencimentoSessoes': 20,
    'sessoes': [
      {
        'nome': 'Treino A',
        'diaSemana': '',
        'orientacoes': '',
        'exercicios': [
          {
            'nome': 'Supino',
            'grupoMuscular': ['Peito'],
            'tipoAlvo': 'Reps',
            'series': [
              {
                'tipo': 'trabalho',
                'alvo': '10',
                'carga': '80kg',
                'descanso': '60s',
              },
            ],
          },
        ],
      },
    ],
  };

  Future<void> pumpPage(WidgetTester tester, RotinaService service) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RotinaDetalhePage(
          rotinaId: 'rotina_1',
          rotinaData: rotinaDataBase(),
          rotinaService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('RotinaDetalhePage - pop com alteracoes', () {
    testWidgets('ao sair com alteracoes, atualiza rotina no service', (
      tester,
    ) async {
      final mockService = MockRotinaService();

      when(
        () => mockService.atualizarRotina(
          rotinaId: any(named: 'rotinaId'),
          nome: any(named: 'nome'),
          objetivo: any(named: 'objetivo'),
          sessoes: any(named: 'sessoes'),
          tipoVencimento: any(named: 'tipoVencimento'),
          sessoesAlvo: any(named: 'sessoesAlvo'),
          dataVencimento: any(named: 'dataVencimento'),
        ),
      ).thenAnswer((_) async {});

      await pumpPage(tester, mockService);

      await tester.tap(find.byIcon(CupertinoIcons.ellipsis_vertical).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).last,
        'Treino A - novo',
      );
      await tester.tap(find.text('SALVAR').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar').first);
      await tester.pumpAndSettle();

      final verifyResult = verify(
        () => mockService.atualizarRotina(
          rotinaId: 'rotina_1',
          nome: 'Rotina Base',
          objetivo: 'Objetivo Base',
          sessoes: captureAny(named: 'sessoes'),
          tipoVencimento: 'sessoes',
          sessoesAlvo: 20,
          dataVencimento: null,
        ),
      );

      verifyResult.called(1);

      final payload =
          verifyResult.captured.single as List<Map<String, dynamic>>;
      final sessoes = payload;
      expect(sessoes.first['nome'], 'Treino A - novo');
    });

    testWidgets('ao sair sem alteracoes, nao chama atualizar', (tester) async {
      final mockService = MockRotinaService();

      when(
        () => mockService.atualizarRotina(
          rotinaId: any(named: 'rotinaId'),
          nome: any(named: 'nome'),
          objetivo: any(named: 'objetivo'),
          sessoes: any(named: 'sessoes'),
          tipoVencimento: any(named: 'tipoVencimento'),
          sessoesAlvo: any(named: 'sessoesAlvo'),
          dataVencimento: any(named: 'dataVencimento'),
        ),
      ).thenAnswer((_) async {});

      await pumpPage(tester, mockService);

      await tester.tap(find.text('Salvar').first);
      await tester.pumpAndSettle();

      verifyNever(
        () => mockService.atualizarRotina(
          rotinaId: any(named: 'rotinaId'),
          nome: any(named: 'nome'),
          objetivo: any(named: 'objetivo'),
          sessoes: any(named: 'sessoes'),
          tipoVencimento: any(named: 'tipoVencimento'),
          sessoesAlvo: any(named: 'sessoesAlvo'),
          dataVencimento: any(named: 'dataVencimento'),
        ),
      );
    });
  });
}
