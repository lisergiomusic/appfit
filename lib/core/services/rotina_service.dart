// Ficheiro: lib/core/services/rotina_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RotinaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> criarRotina({
    String? alunoId,
    required String nome,
    required String objetivo,
    required List<Map<String, dynamic>> sessoes,
    int duracaoDias = 28, // <-- CORREÇÃO: O parâmetro que faltava!
  }) async {
    final personalId = _auth.currentUser?.uid;
    if (personalId == null) throw Exception('Personal não autenticado.');

    // 1. MÁGICA SÊNIOR: Se for para um aluno específico, vamos arquivar as rotinas ativas antigas dele!
    if (alunoId != null) {
      final rotinasAntigas = await _db
          .collection('rotinas')
          .where('alunoId', isEqualTo: alunoId)
          .where('ativa', isEqualTo: true)
          .get();

      // Desativa todas as antigas para não haver conflitos no Hero Card
      for (var doc in rotinasAntigas.docs) {
        await doc.reference.update({'ativa': false});
      }
    }

    // 2. Calcula a data de vencimento a partir de hoje
    final dataVencimento = DateTime.now().add(Duration(days: duracaoDias));

    // 3. Monta o pacote de dados
    final payload = {
      'personalId': personalId,
      'alunoId': alunoId,
      'nome': nome,
      'objetivo': objetivo,
      'dataCriacao': FieldValue.serverTimestamp(),
      'dataVencimento': Timestamp.fromDate(
        dataVencimento,
      ), // <-- Salva a data real
      'ativa': true,
      'sessoes': sessoes,
    };

    // 4. Dispara para o banco de dados
    await _db.collection('rotinas').add(payload);
  }
}
