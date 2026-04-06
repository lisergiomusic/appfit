import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rotina_model.dart';

class ExecutarTreinoController {
  final SessaoTreinoModel sessao;
  final String rotinaId;
  final String alunoId;
  final FirebaseFirestore _firestore;

  ExecutarTreinoController({
    required this.sessao,
    required this.rotinaId,
    required this.alunoId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveTreinoLog(Map<String, dynamic> recordedData) async {
    try {
      final dataHora = DateTime.now();

      // Calcula duração em minutos (assumindo que é calculado depois)
      final duracao = 0; // Será atualizado se necessário

      // Constrói o documento de log
      final logData = {
        'alunoId': alunoId,
        'rotinaId': rotinaId,
        'sessaoNome': sessao.nome,
        'dataHora': Timestamp.fromDate(dataHora),
        'duracaoMinutos': duracao,
        'exercicios': buildExerciciosLog(recordedData),
      };

      // Salva o log de treino
      await _firestore.collection('logs_treino').add(logData);

      // Incrementa sessoesConcluidas na rotina
      await _firestore.collection('rotinas').doc(rotinaId).update({
        'sessoesConcluidas': FieldValue.increment(1),
      });
    } catch (e) {
      rethrow;
    }
  }

  List<Map<String, dynamic>> buildExerciciosLog(Map<String, dynamic> recordedData) {
    final exercicios = <Map<String, dynamic>>[];

    for (var i = 0; i < sessao.exercicios.length; i++) {
      final exercise = sessao.exercicios[i];
      final key = 'exercicio_$i';
      final exercData = recordedData[key] ?? {};
      final series = (exercData is Map ? exercData['series'] : null) ?? [];

      exercicios.add({
        'nome': exercise.nome,
        'grupoMuscular': exercise.grupoMuscular,
        'series': List.generate(
          exercise.series.length,
          (sIndex) {
            final serieData = sIndex < (series is List ? series.length : 0)
                ? (series is List ? series[sIndex] : {})
                : {};
            final reps = (serieData is Map ? serieData['reps'] : null) ?? '';
            final peso = (serieData is Map ? serieData['peso'] : null) ?? '';
            final completa = (serieData is Map ? serieData['completa'] : null) ?? false;

            return {
              'alvo': exercise.series[sIndex].alvo,
              'cargaAlvo': exercise.series[sIndex].carga,
              'repsRealizadas': reps,
              'pesoRealizado': peso,
              'concluida': completa,
            };
          },
        ),
      });
    }

    return exercicios;
  }

  void dispose() {
    // Cleanup if needed
  }
}
