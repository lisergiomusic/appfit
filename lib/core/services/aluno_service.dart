import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../../features/alunos/models/aluno_perfil_data.dart';

class AlunoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot> getAlunoStream(String alunoId) {
    return _firestore
        .collection('usuarios')
        .doc(alunoId)
        .snapshots();
  }

  /// Combina os dados do aluno e sua rotina ativa em um único Stream
  Stream<AlunoPerfilData> getAlunoPerfilCompletoStream(String alunoId) {
    final alunoStream = getAlunoStream(alunoId);
    
    final rotinaStream = _firestore
        .collection('rotinas')
        .where('alunoId', isEqualTo: alunoId)
        .where('ativa', isEqualTo: true)
        .limit(1)
        .snapshots();

    return Rx.combineLatest2<DocumentSnapshot, QuerySnapshot, AlunoPerfilData>(
      alunoStream,
      rotinaStream,
      (alunoSnap, rotinaSnap) {
        final alunoMap = alunoSnap.data() as Map<String, dynamic>? ?? {};
        final rotinaMap = rotinaSnap.docs.isNotEmpty 
            ? rotinaSnap.docs.first.data() as Map<String, dynamic>? 
            : null;
        final rotinaId = rotinaSnap.docs.isNotEmpty ? rotinaSnap.docs.first.id : null;

        return AlunoPerfilData(
          aluno: alunoMap,
          rotinaAtiva: rotinaMap,
          rotinaId: rotinaId,
        );
      },
    );
  }

  Stream<QuerySnapshot> getRotinasTemplates(String personalId) {
    return _firestore
        .collection('rotinas')
        .where('personalId', isEqualTo: personalId)
        .where('alunoId', isNull: true)
        .snapshots();
  }

  Future<void> atribuirTreinoAoAluno({
    required String alunoId,
    required String templateId,
    required int duracaoSemanas,
  }) async {
    final templateDoc = await _firestore.collection('rotinas').doc(templateId).get();
    if (!templateDoc.exists) return;

    final rotinasAntigas = await _firestore
        .collection('rotinas')
        .where('alunoId', isEqualTo: alunoId)
        .where('ativa', isEqualTo: true)
        .get();

    for (var doc in rotinasAntigas.docs) {
      await doc.reference.update({'ativa': false});
    }

    final rotinaData = templateDoc.data() as Map<String, dynamic>;
    rotinaData['alunoId'] = alunoId;
    rotinaData['ativa'] = true;
    rotinaData['dataCriacao'] = FieldValue.serverTimestamp();
    rotinaData['dataVencimento'] = Timestamp.fromDate(
      DateTime.now().add(Duration(days: duracaoSemanas * 7)),
    );

    await _firestore.collection('rotinas').add(rotinaData);
  }
}