import 'package:appfit/core/services/treino_service.dart';
import 'package:appfit/features/treinos/aluno/controllers/executar_treino_controller.dart';
import 'package:appfit/features/treinos/shared/models/exercicio_model.dart';
import 'package:appfit/features/treinos/shared/models/rotina_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTreinoService extends Mock implements TreinoService {}

void main() {
  late MockTreinoService mockTreinoService;
  late ExecutarTreinoController controller;
  late SessaoTreinoModel sessao;
  const alunoId = 'aluno_123';
  const rotinaId = 'rotina_456';

  setUp(() {
    mockTreinoService = MockTreinoService();

    when(
      () => mockTreinoService.saveTreinoLog(
        alunoId: any(named: 'alunoId'),
        rotinaId: any(named: 'rotinaId'),
        sessaoNome: any(named: 'sessaoNome'),
        exercicios: any(named: 'exercicios'),
        duracaoMinutos: any(named: 'duracaoMinutos'),
        esforco: any(named: 'esforco'),
        observacoes: any(named: 'observacoes'),
      ),
    ).thenAnswer((_) async {});

    sessao = SessaoTreinoModel(
      nome: 'Treino A',
      exercicios: [
        ExercicioItem(
          nome: 'Supino',
          series: [
            SerieItem(tipo: TipoSerie.trabalho, alvo: '12', carga: '50kg'),
          ],
        ),
      ],
    );

    controller = ExecutarTreinoController(
      sessao: sessao,
      rotinaId: rotinaId,
      alunoId: alunoId,
      treinoService: mockTreinoService,
    );
  });

  group('ExecutarTreinoController - saveTreinoLog', () {
    test('deve chamar TreinoService.saveTreinoLog com os parâmetros corretos', () async {
      final recordedData = {
        'exercicio_0': {
          'series': [
            {'reps': '12', 'peso': '50', 'completa': true}
          ]
        }
      };

      controller.saveTreinoLog(recordedData, duracaoMinutos: 45);
      await Future.delayed(Duration.zero);

      verify(
        () => mockTreinoService.saveTreinoLog(
          alunoId: alunoId,
          rotinaId: rotinaId,
          sessaoNome: 'Treino A',
          exercicios: any(named: 'exercicios'),
          duracaoMinutos: 45,
          esforco: any(named: 'esforco'),
          observacoes: any(named: 'observacoes'),
        ),
      ).called(1);
    });

    test('quando esforco > 0, deve repassar esforco ao service', () async {
      controller.saveTreinoLog({}, esforco: 8);
      await Future.delayed(Duration.zero);

      verify(
        () => mockTreinoService.saveTreinoLog(
          alunoId: any(named: 'alunoId'),
          rotinaId: any(named: 'rotinaId'),
          sessaoNome: any(named: 'sessaoNome'),
          exercicios: any(named: 'exercicios'),
          duracaoMinutos: any(named: 'duracaoMinutos'),
          esforco: 8,
          observacoes: any(named: 'observacoes'),
        ),
      ).called(1);
    });

    test('quando esforco == 0, deve repassar 0 ao service', () async {
      controller.saveTreinoLog({}, esforco: 0);
      await Future.delayed(Duration.zero);

      verify(
        () => mockTreinoService.saveTreinoLog(
          alunoId: any(named: 'alunoId'),
          rotinaId: any(named: 'rotinaId'),
          sessaoNome: any(named: 'sessaoNome'),
          exercicios: any(named: 'exercicios'),
          duracaoMinutos: any(named: 'duracaoMinutos'),
          esforco: 0,
          observacoes: any(named: 'observacoes'),
        ),
      ).called(1);
    });
  });

  group('ExecutarTreinoController - buildExerciciosLog', () {
    test('deve mapear exercícios com séries concluídas corretamente', () {
      final recordedData = {
        'exercicio_0': {
          'series': [
            {'reps': '12', 'peso': '50', 'completa': true},
            {'reps': '10', 'peso': '45', 'completa': false},
          ]
        }
      };

      final result = controller.buildExerciciosLog(recordedData);

      expect(result.length, 1);
      expect(result.first['nome'], 'Supino');
      final series = result.first['series'] as List;
      expect(series.length, 2);
      expect(series.first['concluida'], true);
    });

    test('deve retornar lista vazia quando recordedData está vazio', () {
      final result = controller.buildExerciciosLog({});
      expect(result, isEmpty);
    });
  });
}
