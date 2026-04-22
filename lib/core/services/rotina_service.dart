import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Serviço responsável por criação, atualização e ciclo de vida de rotinas.
class RotinaService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  RotinaService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  Future<void> criarRotina({
    String? alunoId,
    required String nome,
    required String objetivo,
    required List<Map<String, dynamic>> sessoes,
    required String tipoVencimento,
    int? sessoesAlvo,
    DateTime? dataVencimento,
  }) async {
    final personalId = _auth.currentUser?.uid;
    if (personalId == null) throw Exception('Personal não autenticado.');

    if (alunoId != null) {
      final rotinasAntigas = await _db
          .collection('rotinas')
          .where('alunoId', isEqualTo: alunoId)
          .where('ativa', isEqualTo: true)
          .get();

      if (rotinasAntigas.docs.isNotEmpty) {
        final batch = _db.batch();
        for (var doc in rotinasAntigas.docs) {
          batch.update(doc.reference, {'ativa': false});
        }
        await batch.commit();
      }
    }

    final Map<String, dynamic> payload = {
      'personalId': personalId,
      'alunoId': alunoId,
      'nome': nome,
      'objetivo': objetivo,
      'sessoes': sessoes,
      'ativa': true,
      'dataCriacao': FieldValue.serverTimestamp(),
      'tipoVencimento': tipoVencimento,
    };

    if (tipoVencimento == 'sessoes') {
      payload['vencimentoSessoes'] = sessoesAlvo ?? 20;
      payload['sessoesConcluidas'] = 0;
    } else {
      payload['dataVencimento'] = dataVencimento != null
          ? Timestamp.fromDate(dataVencimento)
          : Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)));
    }

    final novaRotinaRef = _db.collection('rotinas').doc();
    await novaRotinaRef.set(payload);
  }

  Future<void> atualizarRotina({
    required String rotinaId,
    required String nome,
    required String objetivo,
    required List<Map<String, dynamic>> sessoes,
    String? tipoVencimento,
    int? sessoesAlvo,
    DateTime? dataVencimento,
  }) async {
    final Map<String, dynamic> updateData = {
      'nome': nome,
      'objetivo': objetivo,
      'sessoes': sessoes,
    };

    if (tipoVencimento != null) {
      updateData['tipoVencimento'] = tipoVencimento;
      if (tipoVencimento == 'sessoes') {
        updateData['vencimentoSessoes'] = sessoesAlvo;
      } else if (dataVencimento != null) {
        updateData['dataVencimento'] = Timestamp.fromDate(dataVencimento);
      }
    }

    await _db.collection('rotinas').doc(rotinaId).set(updateData, SetOptions(merge: true));
  }

  Future<void> renomearRotina(String rotinaId, String novoNome) async {
    await _db.collection('rotinas').doc(rotinaId).set({'nome': novoNome}, SetOptions(merge: true));
  }

  Future<void> excluirRotina(String rotinaId) async {
    await _db.collection('rotinas').doc(rotinaId).delete();
  }
}
