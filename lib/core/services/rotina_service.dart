import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RotinaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- CRIAÇÃO DE NOVA ROTINA ---
  Future<void> criarRotina({
    String? alunoId,
    required String nome,
    required String objetivo,
    required List<Map<String, dynamic>> sessoes,
    int duracaoDias = 28,
  }) async {
    final personalId = _auth.currentUser?.uid;
    if (personalId == null) throw Exception('Personal não autenticado.');

    // 1. Desativar rotinas antigas usando BATCH (Muito mais rápido e à prova de falhas)
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
        await batch.commit(); // Executa todas as desativações num único milissegundo
      }
    }

    final dataVencimento = DateTime.now().add(Duration(days: duracaoDias));

    final payload = {
      'personalId': personalId,
      'alunoId': alunoId,
      'nome': nome,
      'objetivo': objetivo,
      'dataCriacao': FieldValue.serverTimestamp(),
      'dataVencimento': Timestamp.fromDate(dataVencimento),
      'ativa': true,
      'sessoes': sessoes,
    };

    // 2. Gravar usando .set() num documento novo para persistência offline imediata
    final novaRotinaRef = _db.collection('rotinas').doc();
    await novaRotinaRef.set(payload);
  }

  // --- ATUALIZAÇÃO DE ROTINA EXISTENTE ---
  Future<void> atualizarRotina({
    required String rotinaId,
    required String nome,
    required String objetivo,
    required List<Map<String, dynamic>> sessoes,
    required int duracaoDias,
    Timestamp? dataCriacaoOriginal,
  }) async {

    await FirebaseFirestore.instance
        .collection('rotinas')
        .doc(rotinaId)
        .set({
      'nome': nome,
      'objetivo': objetivo,
      'sessoes': sessoes,
      'duracaoDias': duracaoDias,
      'dataUltimaAlteracao': FieldValue.serverTimestamp(),
      'dataCriacao': ?dataCriacaoOriginal,
    }, SetOptions(merge: true));
  }
}