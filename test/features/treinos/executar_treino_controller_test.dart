import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appfit/features/treinos/aluno/controllers/executar_treino_controller.dart';
import '../../helpers/treino_fixtures.dart';

void main() {
  group('ExecutarTreinoController', () {
    late ExecutarTreinoController controller;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      controller = ExecutarTreinoController(
        sessao: fakeSessao(),
        rotinaId: 'rotina_test_123',
        alunoId: 'aluno_test_123',
        firestore: fakeFirestore,
      );
    });

    group('buildExerciciosLog', () {
      test('persiste exercícios com campos corretos', () {
        final recordedData = {
          'exercicio_0': {
            'series': [
              {'reps': '15', 'peso': '40', 'completa': true},
              {'reps': '10', 'peso': '60', 'completa': true},
            ],
          },
          'exercicio_1': {
            'series': [
              {'reps': '12', 'peso': '50', 'completa': true},
            ],
          },
        };

        final exerciciosLog = controller.buildExerciciosLog(recordedData);

        expect(exerciciosLog, isA<List>());
        expect(exerciciosLog.length, 2);

        final primeiroEx = exerciciosLog[0];
        expect(primeiroEx['nome'], 'Supino Reto');
        expect(primeiroEx['grupoMuscular'], ['Peito']);
        expect(primeiroEx['series'], isA<List>());
        expect(primeiroEx['series'].length, 3);

        final primeiraSerie = primeiroEx['series'][0];
        expect(primeiraSerie['repsRealizadas'], '15');
        expect(primeiraSerie['pesoRealizado'], '40');
        expect(primeiraSerie['concluida'], true);
      });

      test('preserva alvo e cargaAlvo do treino original', () {
        final recordedData = {
          'exercicio_0': {
            'series': [
              {'reps': '8', 'peso': '65', 'completa': true},
            ],
          },
        };

        final exerciciosLog = controller.buildExerciciosLog(recordedData);

        final primeiraSerieLog = exerciciosLog[0]['series'][0];
        expect(primeiraSerieLog['alvo'], '15');
        expect(primeiraSerieLog['cargaAlvo'], '40');
        expect(primeiraSerieLog['repsRealizadas'], '8');
        expect(primeiraSerieLog['pesoRealizado'], '65');
      });

      test('constrói séries com tipo correto', () {
        final recordedData = {
          'exercicio_0': {
            'series': [
              {'reps': '15', 'peso': '40', 'completa': true},
              {'reps': '10', 'peso': '60', 'completa': true},
              {'reps': '8', 'peso': '65', 'completa': true},
            ],
          },
        };

        final exerciciosLog = controller.buildExerciciosLog(recordedData);

        final primeiroEx = exerciciosLog[0];
        expect(primeiroEx['series'][0], containsPair('alvo', '15'));
        expect(primeiroEx['series'][0], containsPair('cargaAlvo', '40'));
      });

      test('mapeia 0 exercícios corretamente', () {
        controller = ExecutarTreinoController(
          sessao: fakeSessao(exercicios: []),
          rotinaId: 'rotina_test_123',
          alunoId: 'aluno_test_123',
          firestore: fakeFirestore,
        );

        final exerciciosLog = controller.buildExerciciosLog({});

        expect(exerciciosLog, isEmpty);
      });

      test('mapeia múltiplos exercícios e séries', () {
        final recordedData = {
          'exercicio_0': {
            'series': [
              {'reps': '15', 'peso': '40', 'completa': true},
              {'reps': '10', 'peso': '60', 'completa': true},
              {'reps': '8', 'peso': '65', 'completa': true},
            ],
          },
          'exercicio_1': {
            'series': [
              {'reps': '12', 'peso': '50', 'completa': true},
            ],
          },
        };

        final exerciciosLog = controller.buildExerciciosLog(recordedData);

        expect(exerciciosLog[0]['series'].length, 3);
        expect(exerciciosLog[1]['series'].length, 1);
      });

      test('preenche reps vazio com string vazia', () {
        final recordedData = {
          'exercicio_0': {
            'series': [
              {'peso': '40', 'completa': true},
              {'reps': '10', 'peso': '60', 'completa': true},
              {'reps': '8', 'peso': '65', 'completa': true},
            ],
          },
        };

        final exerciciosLog = controller.buildExerciciosLog(recordedData);

        expect(exerciciosLog[0]['series'][0]['repsRealizadas'], '');
      });

      test('preenche peso vazio com string vazia', () {
        final recordedData = {
          'exercicio_0': {
            'series': [
              {'reps': '10', 'completa': true},
              {'reps': '10', 'peso': '60', 'completa': true},
              {'reps': '8', 'peso': '65', 'completa': true},
            ],
          },
        };

        final exerciciosLog = controller.buildExerciciosLog(recordedData);

        expect(exerciciosLog[0]['series'][0]['pesoRealizado'], '');
      });
    });

    group('dispose', () {
      test('não lança exceção', () {
        expect(() => controller.dispose(), returnsNormally);
      });
    });

    group('Construtor e estado', () {
      test('armazena sessao corretamente', () {
        expect(controller.sessao.nome, 'Peito e Costas');
      });

      test('armazena rotinaId corretamente', () {
        expect(controller.rotinaId, 'rotina_test_123');
      });

      test('armazena alunoId corretamente', () {
        expect(controller.alunoId, 'aluno_test_123');
      });
    });
  });
}
