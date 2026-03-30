import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RotinaService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  RotinaService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // --- CRIAÇÃO DE NOVA ROTINA ---
  Future<void> criarRotina({
    String? alunoId,
    required String nome,
    required String objetivo,
    required List<Map<String, dynamic>> sessoes,
    required String tipoVencimento, // 'sessoes' ou 'data'
    int? sessoesAlvo,               // Ex: 20
    DateTime? dataVencimento,       // Ex: 20/12/2024
  }) async {
    final personalId = _auth.currentUser?.uid;
    if (personalId == null) throw Exception('Personal não autenticado.');

    // 1. Desativar rotinas antigas do aluno
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

    // 2. Montar o Payload baseado na escolha do usuário
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
      payload['sessoesConcluidas'] = 0; // Inicia o contador
    } else {
      // Se for data, usamos a data passada ou um padrão de 30 dias
      payload['dataVencimento'] = dataVencimento != null
          ? Timestamp.fromDate(dataVencimento)
          : Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)));
    }

    // 3. Gravar no Firestore
    final novaRotinaRef = _db.collection('rotinas').doc();
    await novaRotinaRef.set(payload);
  }

  // --- ATUALIZAÇÃO DE ROTINA EXISTENTE ---
  // (Ajustado para aceitar as mudanças de vencimento também)
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

    await _db.collection('rotinas').doc(rotinaId).update(updateData);
  }

  Future<void> excluirRotina(String rotinaId) async {
    await _db.collection('rotinas').doc(rotinaId).delete();
  }
}
