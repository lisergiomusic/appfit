// Ficheiro: lib/core/services/rotina_service.dart
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

    if (alunoId != null) {
      final rotinasAntigas = await _db
          .collection('rotinas')
          .where('alunoId', isEqualTo: alunoId)
          .where('ativa', isEqualTo: true)
          .get();

      for (var doc in rotinasAntigas.docs) {
        await doc.reference.update({'ativa': false});
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

    await _db.collection('rotinas').add(payload);
  }

  // --- NOVO: ATUALIZAÇÃO DE ROTINA EXISTENTE ---
  Future<void> atualizarRotina({
    required String rotinaId,
    required String nome,
    required String objetivo,
    required List<Map<String, dynamic>> sessoes,
    int duracaoDias = 28,
    Timestamp? dataCriacaoOriginal, // Recebemos para não alterar o histórico
  }) async {
    // Calcula a nova data de vencimento a partir da data em que a rotina foi criada
    final baseDate = dataCriacaoOriginal?.toDate() ?? DateTime.now();
    final dataVencimento = baseDate.add(Duration(days: duracaoDias));

    await _db.collection('rotinas').doc(rotinaId).update({
      'nome': nome,
      'objetivo': objetivo,
      'dataVencimento': Timestamp.fromDate(dataVencimento),
      'sessoes': sessoes,
    });
  }
}
