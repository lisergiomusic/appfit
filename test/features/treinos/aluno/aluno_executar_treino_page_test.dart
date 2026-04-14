import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:appfit/features/treinos/aluno/controllers/executar_treino_controller.dart';
import 'package:appfit/core/services/treino_service.dart';
import '../../../helpers/treino_fixtures.dart';

class MockTreinoService extends Mock implements TreinoService {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockTreinoService mockTreinoService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockTreinoService = MockTreinoService();
    when(() => mockTreinoService.fetchUltimoHistoricoSessao(
          alunoId: any(named: 'alunoId'),
          sessaoNome: any(named: 'sessaoNome'),
        )).thenAnswer((_) async => {});
  });

  group('ExecutarTreinoController', () {
    test('carrega histórico sem erro', () async {
      final controller = ExecutarTreinoController(
        sessao: fakeSessao(),
        rotinaId: 'rotina_test_1',
        alunoId: 'aluno_test_1',
        firestore: fakeFirestore,
        treinoService: mockTreinoService,
      );

      await controller.carregarUltimoHistorico();
      expect(controller.ultimoHistorico, isA<Map>());
    });

    test('saveTreinoLog persiste log corretamente', () async {
      await fakeFirestore.collection('rotinas').doc('rotina_test_1').set({
        'sessoesConcluidas': 0,
      });

      final controller = ExecutarTreinoController(
        sessao: fakeSessao(),
        rotinaId: 'rotina_test_1',
        alunoId: 'aluno_test_1',
        firestore: fakeFirestore,
        treinoService: mockTreinoService,
      );

      final recordedData = {
        'exercicio_0': {
          'series': [
            {'reps': '10', 'peso': '60', 'completa': true},
          ],
        },
      };

      await controller.saveTreinoLog(recordedData, duracaoMinutos: 30);

      final logs = await fakeFirestore.collection('logs_treino').get();
      expect(logs.docs.length, equals(1));
      expect(logs.docs[0]['alunoId'], equals('aluno_test_1'));
    });

    test('saveTreinoLog incrementa sessoesConcluidas', () async {
      await fakeFirestore.collection('rotinas').doc('rotina_test_1').set({
        'sessoesConcluidas': 0,
      });

      final controller = ExecutarTreinoController(
        sessao: fakeSessao(),
        rotinaId: 'rotina_test_1',
        alunoId: 'aluno_test_1',
        firestore: fakeFirestore,
        treinoService: mockTreinoService,
      );

      final recordedData = {
        'exercicio_0': {
          'series': [
            {'reps': '10', 'peso': '60', 'completa': true},
          ],
        },
      };

      await controller.saveTreinoLog(recordedData, duracaoMinutos: 30);

      final rotinaDoc =
          await fakeFirestore.collection('rotinas').doc('rotina_test_1').get();
      expect(rotinaDoc['sessoesConcluidas'], equals(1));
    });

    test('buildExerciciosLog transforma dados corretamente', () {
      final controller = ExecutarTreinoController(
        sessao: fakeSessao(),
        rotinaId: 'rotina_test_1',
        alunoId: 'aluno_test_1',
        firestore: fakeFirestore,
        treinoService: mockTreinoService,
      );

      final recordedData = {
        'exercicio_0': {
          'series': [
            {'reps': '10', 'peso': '60', 'completa': true},
          ],
        },
      };

      final exerciciosLog = controller.buildExerciciosLog(recordedData);
      expect(exerciciosLog.length, greaterThan(0));
      expect(exerciciosLog[0]['nome'], isA<String>());
      expect(exerciciosLog[0]['series'], isA<List>());
    });

    test('saveTreinoLog com dados vazios não lança erro', () async {
      await fakeFirestore.collection('rotinas').doc('rotina_test_1').set({
        'sessoesConcluidas': 0,
      });

      final controller = ExecutarTreinoController(
        sessao: fakeSessao(),
        rotinaId: 'rotina_test_1',
        alunoId: 'aluno_test_1',
        firestore: fakeFirestore,
        treinoService: mockTreinoService,
      );

      final recordedData = {
        'exercicio_0': {
          'series': [
            {'reps': '', 'peso': '', 'completa': false},
          ],
        },
      };

      await controller.saveTreinoLog(recordedData, duracaoMinutos: 0);

      final logs = await fakeFirestore.collection('logs_treino').get();
      expect(logs.docs.length, equals(1));
    });
  });
}
