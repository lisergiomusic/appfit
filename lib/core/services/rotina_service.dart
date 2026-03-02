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
  }) async {
    // 1. Garante que sabemos quem é o Personal Trainer que está a criar
    final personalId = _auth.currentUser?.uid;
    if (personalId == null) throw Exception('Personal não autenticado.');

    // 2. Monta o Payload (Pacote de Dados)
    final payload = {
      'personalId': personalId,
      'alunoId':
          alunoId, // Pode ser nulo se for uma rotina genérica da biblioteca
      'nome': nome,
      'objetivo': objetivo,
      'dataCriacao': FieldValue.serverTimestamp(),
      'ativa': true, // Por padrão, a rotina nasce ativa
      'sessoes': sessoes, // O Firebase aceita arrays de objetos diretamente!
    };

    // 3. Dispara para o Firestore na coleção 'rotinas'
    await _db.collection('rotinas').add(payload);
  }
}
