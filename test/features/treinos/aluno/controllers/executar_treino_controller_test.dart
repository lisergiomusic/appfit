import 'package:appfit/core/services/treino_service.dart';
import 'package:appfit/features/treinos/aluno/controllers/executar_treino_controller.dart';
import 'package:appfit/features/treinos/shared/models/exercicio_model.dart';
import 'package:appfit/features/treinos/shared/models/rotina_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/firestore_fixtures.dart';

class MockTreinoService extends Mock implements TreinoService {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockTreinoService mockTreinoService;
  late ExecutarTreinoController controller;
  late SessaoTreinoModel sessao;
  const alunoId = 'aluno_123';
  const rotinaId = 'rotina_456';

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    mockTreinoService = MockTreinoService();

    // Criar documentos necessários para evitar erros de "not-found" nos logs
    await fakeFirestore.collection('usuarios').doc(alunoId).set(
      FirestoreFixtures.aluno(),
    );
    await fakeFirestore.collection('rotinas').doc(rotinaId).set(
      FirestoreFixtures.rotina(alunoId: alunoId),
    );

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
      firestore: fakeFirestore,
      treinoService: mockTreinoService,
    );
  });

  group('ExecutarTreinoController - saveTreinoLog', () {
    test('deve criar documento em logs_treino com os campos corretos', () async {
      final recordedData = {
        'exercicio_0': {
          'series': [
            {'reps': '12', 'peso': '50', 'completa': true}
          ]
        }
      };

      controller.saveTreinoLog(recordedData, duracaoMinutos: 45);

      // Como o controller usa _saveLogAsync sem aguardar o Future (fire-and-forget),
      // precisamos dar um tempo para o processamento assíncrono ou usar pump se fosse UI.
      // Em testes de unidade pura com fake_cloud_firestore, geralmente é síncrono no mock
      // mas o controller não retorna o future.
      
      await Future.delayed(Duration.zero);

      final logs = await fakeFirestore.collection('logs_treino').get();
      expect(logs.docs.length, 1);
      final log = logs.docs.first.data();
      
      expect(log['alunoId'], alunoId);
      expect(log['rotinaId'], rotinaId);
      expect(log['sessaoNome'], 'Treino A');
      expect(log['duracaoMinutos'], 45);
      expect(log['dataHora'], isA<Timestamp>());
      expect(log['exercicios'], isNotEmpty);
    });

    test('quando esforco > 0, campo esforco deve estar presente', () async {
      controller.saveTreinoLog({}, esforco: 8);
      await Future.delayed(Duration.zero);

      final logs = await fakeFirestore.collection('logs_treino').get();
      expect(logs.docs.first.data()['esforco'], 8);
    });

    test('quando esforco == 0, campo esforco NÃO deve estar presente', () async {
      controller.saveTreinoLog({}, esforco: 0);
      await Future.delayed(Duration.zero);

      final logs = await fakeFirestore.collection('logs_treino').get();
      expect(logs.docs.first.data().containsKey('esforco'), isFalse);
    });

    test('deve incrementar sessoesConcluidas na rotina e atualizar ultimoTreino no aluno', () async {
      // Setup documentos
      await fakeFirestore.collection('rotinas').doc(rotinaId).set({
        'sessoesConcluidas': 0,
      });
      await fakeFirestore.collection('usuarios').doc(alunoId).set({
        'ultimoTreino': Timestamp.fromDate(DateTime(2023, 1, 1)),
      });

      controller.saveTreinoLog({});
      await Future.delayed(Duration.zero);

      final rotinaDoc = await fakeFirestore.collection('rotinas').doc(rotinaId).get();
      expect(rotinaDoc.data()?['sessoesConcluidas'], 1);

      final alunoDoc = await fakeFirestore.collection('usuarios').doc(alunoId).get();
      final ultimoTreino = (alunoDoc.data()?['ultimoTreino'] as Timestamp).toDate();
      expect(ultimoTreino.year, DateTime.now().year);
    });
  });
}