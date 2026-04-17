import 'package:appfit/core/services/aluno_service.dart';
import 'package:appfit/features/alunos/shared/models/aluno_perfil_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/firestore_fixtures.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late AlunoService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    service = AlunoService(firestore: fakeFirestore, auth: mockAuth);
  });

  group('AlunoService - getAlunoPerfilCompletoStream', () {
    test('deve emitir AlunoPerfilData com aluno, rotinaAtiva e rotinaId corretos', () async {
      const alunoId = 'aluno_123';
      const personalId = 'personal_456';
      
      // Criar personal
      await fakeFirestore.collection('usuarios').doc(personalId).set(
        FirestoreFixtures.personal(nome: 'Rodrigo'),
      );

      // Criar aluno
      await fakeFirestore.collection('usuarios').doc(alunoId).set(
        FirestoreFixtures.aluno(personalId: personalId),
      );

      // Criar rotina ativa
      final rotinaRef = await fakeFirestore.collection('rotinas').add(
        FirestoreFixtures.rotina(alunoId: alunoId, ativa: true),
      );

      final stream = service.getAlunoPerfilCompletoStream(alunoId);
      
      expect(
        stream,
        emits(predicate<AlunoPerfilData>((data) {
          return data.aluno['nome'] == 'João' &&
                 data.rotinaAtiva?['nome'] == 'Treino de Hipertrofia' &&
                 data.rotinaId == rotinaRef.id &&
                 data.nomePersonal == 'Rodrigo Trainer';
        })),
      );
    });

    test('quando não há rotina ativa, rotinaAtiva deve ser null', () async {
      const alunoId = 'aluno_123';
      await fakeFirestore.collection('usuarios').doc(alunoId).set(
        FirestoreFixtures.aluno(),
      );

      final stream = service.getAlunoPerfilCompletoStream(alunoId);

      expect(
        stream,
        emits(predicate<AlunoPerfilData>((data) {
          return data.rotinaAtiva == null && data.rotinaId == null;
        })),
      );
    });

    test('quando ultimoTreino é atualizado, o stream emite novo evento com valor atualizado', () async {
      const alunoId = 'aluno_123';
      final dataInicial = DateTime(2023, 10, 1);
      final dataAtualizada = DateTime(2023, 10, 2);

      await fakeFirestore.collection('usuarios').doc(alunoId).set(
        FirestoreFixtures.aluno(ultimoTreino: dataInicial),
      );

      final stream = service.getAlunoPerfilCompletoStream(alunoId);

      // Captura os eventos do stream
      final expectations = [
        predicate<AlunoPerfilData>((data) => 
          (data.aluno['ultimoTreino'] as Timestamp).toDate() == dataInicial),
        predicate<AlunoPerfilData>((data) => 
          (data.aluno['ultimoTreino'] as Timestamp).toDate() == dataAtualizada),
      ];

      expect(stream, emitsInOrder(expectations));

      // Gatilho para a atualização
      await fakeFirestore.collection('usuarios').doc(alunoId).update({
        'ultimoTreino': Timestamp.fromDate(dataAtualizada),
      });
    });
  });
}