import 'package:appfit/features/treinos/shared/models/historico_treino_model.dart';
import 'package:appfit/features/treinos/shared/models/exercicio_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TreinoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Operações de log de treino e estatísticas associadas a um aluno.
  ///
  /// Todos os métodos aqui acessam o Firestore diretamente e retornam dados
  /// formatados para uso nas telas de treino.

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

      await _firestore.collection('rotinas').doc(rotinaId).update({
        'sessoesConcluidas': FieldValue.increment(1),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Retorna os últimos 50 logs de treino de um aluno ordenados pela data.
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

  /// Fornece um stream em tempo real de logs de treino para uma rotina.
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

  /// Busca logs de treino de um aluno dentro de um intervalo de datas.
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

  /// Gera estatísticas básicas de treino para um aluno usando seus logs.
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

  /// Busca o último log de uma sessão e monta o histórico de cada exercício.
  ///
  /// O resultado tem chave igual ao nome do exercício e valor com a lista de
  /// séries em ordem, agrupadas pelo tipo de série.
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
