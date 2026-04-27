import 'package:flutter/foundation.dart';
import 'package:appfit/core/services/treino_service.dart';
import 'package:appfit/features/treinos/shared/models/historico_treino_model.dart';
import '../../shared/models/rotina_model.dart';

/// Orquestra persistência de execução de treino e carregamento de histórico.
class ExecutarTreinoController {
  final SessaoTreinoModel sessao;
  final String rotinaId;
  final String alunoId;
  final TreinoService _treinoService;

  Map<String, List<SerieHistorico>> ultimoHistorico = {};

  ExecutarTreinoController({
    required this.sessao,
    required this.rotinaId,
    required this.alunoId,
    TreinoService? treinoService,
  }) : _treinoService = treinoService ?? TreinoService();

  /// Persiste o log da sessão em background (fire-and-forget).
  void saveTreinoLog(
    Map<String, dynamic> recordedData, {
    int duracaoMinutos = 0,
    int esforco = 0,
    String observacoes = '',
  }) {
    _treinoService.saveTreinoLog(
      alunoId: alunoId,
      rotinaId: rotinaId,
      sessaoNome: sessao.nome,
      exercicios: buildExerciciosLog(recordedData),
      duracaoMinutos: duracaoMinutos,
      esforco: esforco,
      observacoes: observacoes,
    ).catchError((e) => debugPrint('[TreinoLog] erro ao salvar log: $e'));
  }

  List<Map<String, dynamic>> buildExerciciosLog(
    Map<String, dynamic> recordedData,
  ) {
    final exercicios = <Map<String, dynamic>>[];

    // Serializa cada exercício com fallback seguro para campos ausentes na UI.
    for (var i = 0; i < sessao.exercicios.length; i++) {
      final exercise = sessao.exercicios[i];
      final key = 'exercicio_$i';
      final Map<String, dynamic> exercData = Map<String, dynamic>.from(recordedData[key] ?? {});
      final List series = exercData['series'] ?? [];

      exercicios.add({
        'nome': exercise.nome,
        'grupo_muscular': exercise.grupoMuscular,
        'series': List.generate(exercise.series.length, (sIndex) {
          final Map serieData = Map<String, dynamic>.from(sIndex < series.length ? series[sIndex] : {});
          final reps = serieData['reps']?.toString() ?? '';
          final peso = serieData['peso']?.toString() ?? '';
          final completa = serieData['completa'] == true;

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