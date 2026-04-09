import 'package:cloud_firestore/cloud_firestore.dart';

class TreinoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Salva um log de execução de treino na collection 'logs_treino'
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

      // Incrementa sessoesConcluidas na rotina
      await _firestore.collection('rotinas').doc(rotinaId).update({
        'sessoesConcluidas': FieldValue.increment(1),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Busca todos os logs de treino de um aluno
  Future<List<Map<String, dynamic>>> fetchLogsAluno(String alunoId) async {
    try {
      final snapshot = await _firestore
          .collection('logs_treino')
          .where('alunoId', isEqualTo: alunoId)
          .orderBy('dataHora', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream de logs de treino para uma rotina específica
  Stream<List<Map<String, dynamic>>> getLogsRotinaStream(String rotinaId) {
    return _firestore
        .collection('logs_treino')
        .where('rotinaId', isEqualTo: rotinaId)
        .orderBy('dataHora', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  /// Busca logs por intervalo de datas
  Future<List<Map<String, dynamic>>> fetchLogsInterval(
    String alunoId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('logs_treino')
          .where('alunoId', isEqualTo: alunoId)
          .where('dataHora',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('dataHora', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('dataHora', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Calcula estatísticas de treino para um aluno
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
        'averageExercisesPerSession':
            totalSessions > 0 ? totalExercises / totalSessions : 0,
        'lastTrainingDate':
            logs.isNotEmpty ? (logs.first['dataHora'] as Timestamp?)?.toDate() : null,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Calcula os recordes pessoais de um aluno para um exercício específico.
  Future<Map<String, double?>> calcularRecordesPessoais({
    required String alunoId,
    required String exercicioNome,
  }) async {
    final logs = await fetchLogsAluno(alunoId);

    double? maiorPeso;
    double? melhorUmRM;
    double? melhorVolumeSerie;
    double? melhorVolumeSessao;

    final nomeAlvo = exercicioNome.trim().toLowerCase();

    for (final log in logs) {
      final exercicios = log['exercicios'] as List? ?? [];
      double volumeSessao = 0;
      bool sessaoTemDados = false;

      for (final ex in exercicios) {
        final nomeEx = ((ex['nome'] ?? '') as String).trim().toLowerCase();
        if (nomeEx != nomeAlvo) continue;

        final series = ex['series'] as List? ?? [];
        for (final s in series) {
          final concluida = s['concluida'] as bool? ?? false;
          if (!concluida) continue;

          final peso = double.tryParse((s['pesoRealizado'] ?? '').toString()) ?? 0.0;
          final reps = double.tryParse((s['repsRealizadas'] ?? '').toString()) ?? 0.0;
          if (peso <= 0 || reps <= 0) continue;

          sessaoTemDados = true;

          if (maiorPeso == null || peso > maiorPeso) maiorPeso = peso;

          final umRM = peso * (1 + reps / 30);
          if (melhorUmRM == null || umRM > melhorUmRM) melhorUmRM = umRM;

          final volSerie = peso * reps;
          if (melhorVolumeSerie == null || volSerie > melhorVolumeSerie) {
            melhorVolumeSerie = volSerie;
          }

          volumeSessao += volSerie;
        }
      }

      if (sessaoTemDados) {
        if (melhorVolumeSessao == null || volumeSessao > melhorVolumeSessao) {
          melhorVolumeSessao = volumeSessao;
        }
      }
    }

    return {
      'maiorPeso': maiorPeso,
      'melhorUmRM': melhorUmRM,
      'melhorVolumeSerie': melhorVolumeSerie,
      'melhorVolumeSessao': melhorVolumeSessao,
    };
  }
}
