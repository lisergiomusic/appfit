import 'package:appfit/core/services/treino_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/firestore_fixtures.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late TreinoService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = TreinoService(firestore: fakeFirestore);
  });

  group('TreinoService - fetchLogsAluno', () {
    test('deve retornar logs ordenados por dataHora desc e filtrados por alunoId', () async {
      const alunoId = 'aluno_1';
      const outroAlunoId = 'aluno_2';

      final data1 = DateTime(2023, 10, 1, 10);
      final data2 = DateTime(2023, 10, 1, 11);

      await fakeFirestore.collection('logs_treino').add(
        FirestoreFixtures.logTreino(alunoId: alunoId, rotinaId: 'r1', dataHora: data1),
      );
      await fakeFirestore.collection('logs_treino').add(
        FirestoreFixtures.logTreino(alunoId: alunoId, rotinaId: 'r1', dataHora: data2),
      );
      await fakeFirestore.collection('logs_treino').add(
        FirestoreFixtures.logTreino(alunoId: outroAlunoId, rotinaId: 'r1'),
      );

      final result = await service.fetchLogsAluno(alunoId);

      expect(result.length, 2);
      expect((result[0]['dataHora'] as Timestamp).toDate(), data2);
      expect((result[1]['dataHora'] as Timestamp).toDate(), data1);
    });

    test('deve retornar lista vazia quando não há logs', () async {
      final result = await service.fetchLogsAluno('nenhum');
      expect(result, isEmpty);
    });
  });

  group('TreinoService - fetchLogsInterval', () {
    test('deve retornar apenas logs dentro do intervalo de datas', () async {
      const alunoId = 'aluno_1';
      final inicio = DateTime(2023, 10, 1);
      final fim = DateTime(2023, 10, 5);

      await fakeFirestore.collection('logs_treino').add(
        FirestoreFixtures.logTreino(alunoId: alunoId, rotinaId: 'r1', dataHora: DateTime(2023, 9, 30)),
      );
      await fakeFirestore.collection('logs_treino').add(
        FirestoreFixtures.logTreino(alunoId: alunoId, rotinaId: 'r1', dataHora: DateTime(2023, 10, 2)),
      );
      await fakeFirestore.collection('logs_treino').add(
        FirestoreFixtures.logTreino(alunoId: alunoId, rotinaId: 'r1', dataHora: DateTime(2023, 10, 5)),
      );
      await fakeFirestore.collection('logs_treino').add(
        FirestoreFixtures.logTreino(alunoId: alunoId, rotinaId: 'r1', dataHora: DateTime(2023, 10, 6)),
      );

      final result = await service.fetchLogsInterval(alunoId, inicio, fim);

      expect(result.length, 2);
    });
  });

  group('TreinoService - fetchLogsAlunoPage', () {
    test('deve respeitar o limit de logsPorPagina', () async {
      const alunoId = 'aluno_1';
      final totalLogs = TreinoService.logsPorPagina + 5;

      for (int i = 0; i < totalLogs; i++) {
        await fakeFirestore.collection('logs_treino').add(
          FirestoreFixtures.logTreino(
            alunoId: alunoId,
            rotinaId: 'r1',
            dataHora: DateTime(2023, 10, i + 1),
          ),
        );
      }

      final result = await service.fetchLogsAlunoPage(alunoId);

      expect(result.logs.length, TreinoService.logsPorPagina);
      expect(result.ultimoDoc, isNotNull);
    });
  });
}