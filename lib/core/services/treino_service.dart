import 'package:appfit/features/treinos/shared/models/historico_treino_model.dart';
import 'package:appfit/features/treinos/shared/models/exercicio_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TreinoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<void> saveTreinoLog({
    required String alunoId,
    required String rotinaId,
    required String sessaoNome,
    required List<Map<String, dynamic>> exercicios,
  }) async {
    try {
      final logData = {
        'alunoId': alunoId,
        'rotinaId': rotinaId,
        'sessaoNome': sessaoNome,
        'dataHora': Timestamp.now(),
        'duracaoMinutos': 0,
        'exercicios': exercicios,
      };

      await _firestore.collection('logs_treino').add(logData);

      // Atualiza o contador na rotina
      await _firestore.collection('rotinas').doc(rotinaId).update({
        'sessoesConcluidas': FieldValue.increment(1),
      });

      // CORREÇÃO: Atualiza a data do último treino no perfil do aluno
      // Isso tira o aluno do status de "Risco" no dashboard do Personal
      await _firestore.collection('usuarios').doc(alunoId).update({
        'ultimoTreino': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchLogsAluno(String alunoId) async {
    try {
      final snapshot = await _firestore
          .collection('logs_treino')
          .where('alunoId', isEqualTo: alunoId)
          .orderBy('dataHora', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      rethrow;
    }
  }

  static const int logsPorPagina = 15;

  Future<({List<Map<String, dynamic>> logs, DocumentSnapshot? ultimoDoc})>
  fetchLogsAlunoPage(
    String alunoId, {
    DocumentSnapshot? aposDoc,
  }) async {
    try {
      var query = _firestore
          .collection('logs_treino')
          .where('alunoId', isEqualTo: alunoId)
          .orderBy('dataHora', descending: true)
          .limit(logsPorPagina);

      if (aposDoc != null) {
        query = query.startAfterDocument(aposDoc);
      }

      final snapshot = await query.get();
      final logs = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      final ultimoDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      return (logs: logs, ultimoDoc: ultimoDoc);
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getLogsRotinaStream(String rotinaId) {
    return _firestore
        .collection('logs_treino')
        .where('rotinaId', isEqualTo: rotinaId)
        .orderBy('dataHora', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<List<Map<String, dynamic>>> fetchLogsInterval(
    String alunoId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('logs_treino')
          .where('alunoId', isEqualTo: alunoId)
          .where(
            'dataHora',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('dataHora', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('dataHora', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTrainingStats(String alunoId) async {
    try {
      final logs = await fetchLogsAluno(alunoId);

      int totalSessions = logs.length;
      int totalExercises = 0;

      for (var log in logs) {
        final exercicios = log['exercicios'] as List? ?? [];
        totalExercises += exercicios.length;
      }

      return {
        'totalSessions': totalSessions,
        'totalExercises': totalExercises,
        'averageExercisesPerSession': totalSessions > 0
            ? totalExercises / totalSessions
            : 0,
        'lastTrainingDate': logs.isNotEmpty
            ? (logs.first['dataHora'] as Timestamp?)?.toDate()
            : null,
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, List<SerieHistorico>>> fetchUltimoHistoricoSessao({
    required String alunoId,
    required String sessaoNome,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('logs_treino')
          .where('alunoId', isEqualTo: alunoId)
          .where('sessaoNome', isEqualTo: sessaoNome)
          .orderBy('dataHora', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return {};
      }

      final logData = snapshot.docs.first.data();
      final exercicios = logData['exercicios'] as List? ?? [];
      final Map<String, List<SerieHistorico>> resultado = {};

      for (final ex in exercicios) {
        final nomeExercicio = ex['nome'] as String? ?? '';
        if (nomeExercicio.isEmpty) continue;

        final series = ex['series'] as List? ?? [];
        final historicoExercicio = <SerieHistorico>[];

        final seriesPorTipo = <TipoSerie, List<Map<String, dynamic>>>{};
        for (final serie in series) {
          final tipoStr = serie['tipo'] as String? ?? 'trabalho';
          final tipo = _parsetipoSerie(tipoStr);
          seriesPorTipo.putIfAbsent(tipo, () => []).add(serie);
        }

        for (final tipo in seriesPorTipo.keys) {
          final seriesDoTipo = seriesPorTipo[tipo]!;
          for (int i = 0; i < seriesDoTipo.length; i++) {
            final serie = seriesDoTipo[i];
            final concluida = serie['concluida'] as bool? ?? false;

            historicoExercicio.add(
              SerieHistorico(
                tipo: tipo,
                indexDentroDoTipo: i,
                pesoRealizado: concluida
                    ? (serie['pesoRealizado'] as String?)
                    : null,
                repsRealizadas: concluida
                    ? (serie['repsRealizadas'] as String?)
                    : null,
              ),
            );
          }
        }

        resultado[nomeExercicio] = historicoExercicio;
      }

      return resultado;
    } catch (e) {
      rethrow;
    }
  }

  TipoSerie _parsetipoSerie(String tipoStr) {
    return switch (tipoStr.toLowerCase().trim()) {
      'aquecimento' => TipoSerie.aquecimento,
      'feeder' => TipoSerie.feeder,
      _ => TipoSerie.trabalho,
    };
  }
}