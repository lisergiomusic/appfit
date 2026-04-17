import 'package:flutter/foundation.dart';
import 'package:appfit/core/services/treino_service.dart';
import 'package:appfit/features/treinos/shared/models/historico_treino_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/rotina_model.dart';

/// Orquestra persistência de execução de treino e carregamento de histórico.
class ExecutarTreinoController {
  final SessaoTreinoModel sessao;
  final String rotinaId;
  final String alunoId;
  final FirebaseFirestore _firestore;
  final TreinoService _treinoService;

  Map<String, List<SerieHistorico>> ultimoHistorico = {};

  ExecutarTreinoController({
    required this.sessao,
    required this.rotinaId,
    required this.alunoId,
    FirebaseFirestore? firestore,
    TreinoService? treinoService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _treinoService = treinoService ?? TreinoService();

  /// Persiste o log da sessão em background (fire-and-forget).
  void saveTreinoLog(
    Map<String, dynamic> recordedData, {
    int duracaoMinutos = 0,
  }) {
    final logData = {
      'alunoId': alunoId,
      'rotinaId': rotinaId,
      'sessaoNome': sessao.nome,
      'dataHora': Timestamp.fromDate(DateTime.now()),
      'duracaoMinutos': duracaoMinutos,
      'exercicios': buildExerciciosLog(recordedData),
    };

    _firestore
        .collection('logs_treino')
        .doc()
        .set(logData)
        .catchError((e) => debugPrint('[TreinoLog] erro ao salvar log: $e'));
    _firestore
        .collection('rotinas')
        .doc(rotinaId)
        .update({'sessoesConcluidas': FieldValue.increment(1)})
        .catchError((e) => debugPrint('[TreinoLog] erro ao incrementar sessoes: $e'));
  }

  List<Map<String, dynamic>> buildExerciciosLog(
    Map<String, dynamic> recordedData,
  ) {
    final exercicios = <Map<String, dynamic>>[];

    // Serializa cada exercício com fallback seguro para campos ausentes na UI.
    for (var i = 0; i < sessao.exercicios.length; i++) {
      final exercise = sessao.exercicios[i];
      final key = 'exercicio_$i';
      final exercData = recordedData[key] ?? {};
      final series = (exercData is Map ? exercData['series'] : null) ?? [];

      exercicios.add({
        'nome': exercise.nome,
        'grupoMuscular': exercise.grupoMuscular,
        'series': List.generate(exercise.series.length, (sIndex) {
          final serieData = sIndex < (series is List ? series.length : 0)
              ? (series is List ? series[sIndex] : {})
              : {};
          final reps = (serieData is Map ? serieData['reps'] : null) ?? '';
          final peso = (serieData is Map ? serieData['peso'] : null) ?? '';
          final completa =
              (serieData is Map ? serieData['completa'] : null) ?? false;

          return {
            'tipo': exercise.series[sIndex].tipo.toString().split('.').last,
            'alvo': exercise.series[sIndex].alvo,
            'cargaAlvo': exercise.series[sIndex].carga,
            'repsRealizadas': reps,
            'pesoRealizado': peso,
            'concluida': completa,
          };
        }),
      });
    }

    return exercicios;
  }

  Future<void> carregarUltimoHistorico() async {
    try {
      ultimoHistorico = await _treinoService.fetchUltimoHistoricoSessao(
        alunoId: alunoId,
        sessaoNome: sessao.nome,
      );
    } catch (e) {
      // Histórico é opcional; em erro mantemos estado vazio para não bloquear.
      ultimoHistorico = {};
    }
  }

  void dispose() {}
}
