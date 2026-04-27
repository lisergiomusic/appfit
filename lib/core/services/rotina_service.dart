import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Serviço responsável por criação, atualização e ciclo de vida de rotinas.
///
/// Writes são serializados por [rotinaId]: um segundo [atualizarRotina] para o
/// mesmo documento só começa depois que o anterior terminar, evitando o
/// deadlock no canal gRPC do Firestore Android SDK causado por writes
/// concorrentes no mesmo doc.
class RotinaService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  // Fila de serialização por rotinaId → garante no máximo 1 write simultâneo
  // por documento, evitando deadlock no canal gRPC do Android.
  final Map<String, Future<void>> _writeQueue = {};

  RotinaService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  Future<String> criarRotina({
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
    return novaRotinaRef.id;
  }

  /// Atualiza uma rotina existente, serializando writes para evitar deadlock
  /// no canal gRPC do Firestore quando múltiplos saves são disparados
  /// em sequência rápida no mesmo documento.
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

    // Padrão staff: Serialização de escrita.
    // Garante que o write anterior para ESTE rotinaId terminou antes de iniciar o próximo.
    final Completer<void> writeCompleter = Completer<void>();
    final Future<void>? previousWrite = _writeQueue[rotinaId];
    _writeQueue[rotinaId] = writeCompleter.future;

    if (previousWrite != null) {
      debugPrint('[RotinaService] Aguardando write anterior de $rotinaId...');
      await previousWrite.catchError((_) {}); // Ignora erro do anterior
    }

    try {
      debugPrint('[RotinaService] Iniciando write de $rotinaId...');
      // Safety Timeout de 20s: impede que o gRPC trave a fila para sempre se a identidade falhar.
      // O Firestore continuará tentando em background, mas a fila do app é liberada.
      await _db
          .collection('rotinas')
          .doc(rotinaId)
          .set(updateData, SetOptions(merge: true))
          .timeout(const Duration(seconds: 20));
      debugPrint('[RotinaService] Write de $rotinaId finalizado com sucesso.');
    } catch (e) {
      debugPrint('[RotinaService] Alerta no write de $rotinaId (Pode ser latência ou gRPC): $e');
      // Não damos rethrow em caso de timeout para não quebrar o fluxo da UI,
      // pois o dado já está no cache local do Firestore e subirá assim que gRPC estabilizar.
      if (e is! TimeoutException) rethrow;
    } finally {
      writeCompleter.complete();
      // Limpa a fila se formos o último
      if (_writeQueue[rotinaId] == writeCompleter.future) {
        _writeQueue.remove(rotinaId);
      }
    }
  }

  Future<void> renomearRotina(String rotinaId, String novoNome) async {
    await _db
        .collection('rotinas')
        .doc(rotinaId)
        .set({'nome': novoNome}, SetOptions(merge: true));
  }

  Future<void> excluirRotina(String rotinaId) async {
    await _db.collection('rotinas').doc(rotinaId).delete();
  }
}