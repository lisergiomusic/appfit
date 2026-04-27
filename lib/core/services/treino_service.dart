import 'package:appfit/features/treinos/shared/models/historico_treino_model.dart';
import 'package:appfit/features/treinos/shared/models/exercicio_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TreinoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> saveTreinoLog({
    required String alunoId,
    required String rotinaId,
    required String sessaoNome,
    required List<Map<String, dynamic>> exercicios,
    int? esforco,
    String? observacoes,
    int duracaoMinutos = 0,
  }) async {
    try {
      final logData = {
        'aluno_id': alunoId,
        'rotina_id': rotinaId,
        'sessao_nome': sessaoNome,
        'data_hora': DateTime.now().toIso8601String(),
        'duracao_minutos': duracaoMinutos,
        'esforco': esforco,
        'observacoes': observacoes,
        'exercicios': exercicios,
        'personal_id': _supabase.auth.currentUser?.id,
      };

      await _supabase.from('logs_treino').insert(logData);

      // Atualiza o contador na rotina (SQL Update com incremento)
      // Nota: No SQL fazemos isso via RPC ou buscando e salvando.
      // Simplificado por enquanto:
      try {
        final rotina = await _supabase.from('rotinas').select('sessoes_concluidas').eq('id', rotinaId).maybeSingle();
        if (rotina != null) {
          int concluidas = (rotina['sessoes_concluidas'] as int? ?? 0) + 1;
          await _supabase.from('rotinas').update({'sessoes_concluidas': concluidas}).eq('id', rotinaId);
        }
      } catch (_) {}

      // Atualiza o perfil do aluno
      await _supabase.from('profiles').update({
        'ultimo_treino': DateTime.now().toIso8601String()
      }).eq('id', alunoId);
      
    } catch (e) {
      throw Exception('Erro ao salvar log de treino: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchLogsAluno(String alunoId) async {
    try {
      final data = await _supabase
          .from('logs_treino')
          .select()
          .eq('aluno_id', alunoId)
          .order('data_hora', ascending: false)
          .limit(50);

      // Normaliza para CamelCase se necessário na UI
      return (data as List).map((log) => _normalizeLog(log)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar logs: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchLogsInterval(
    String alunoId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final data = await _supabase
          .from('logs_treino')
          .select()
          .eq('aluno_id', alunoId)
          .gte('data_hora', startDate.toIso8601String())
          .lte('data_hora', endDate.toIso8601String())
          .order('data_hora', ascending: false);

      return (data as List).map((log) => _normalizeLog(log)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar logs por intervalo: $e');
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
        'averageExercisesPerSession': totalSessions > 0 ? totalExercises / totalSessions : 0,
        'lastTrainingDate': logs.isNotEmpty ? DateTime.tryParse(logs.first['dataHora'].toString()) : null,
      };
    } catch (e) {
      return {'totalSessions': 0, 'totalExercises': 0};
    }
  }

  Future<Map<String, List<SerieHistorico>>> fetchUltimoHistoricoSessao({
    required String alunoId,
    required String sessaoNome,
  }) async {
    try {
      final data = await _supabase
          .from('logs_treino')
          .select()
          .eq('aluno_id', alunoId)
          .eq('sessao_nome', sessaoNome)
          .order('data_hora', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return {};

      final exercicios = data['exercicios'] as List? ?? [];
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
          seriesPorTipo.putIfAbsent(tipo, () => []).add(Map<String, dynamic>.from(serie));
        }

        for (final tipo in seriesPorTipo.keys) {
          final seriesDoTipo = seriesPorTipo[tipo]!;
          for (int i = 0; i < seriesDoTipo.length; i++) {
            final serie = seriesDoTipo[i];
            final concluida = serie['concluida'] == true;

            historicoExercicio.add(
              SerieHistorico(
                tipo: tipo,
                indexDentroDoTipo: i,
                pesoRealizado: concluida ? (serie['pesoRealizado']?.toString()) : null,
                repsRealizadas: concluida ? (serie['repsRealizadas']?.toString()) : null,
              ),
            );
          }
        }
        resultado[nomeExercicio] = historicoExercicio;
      }
      return resultado;
    } catch (e) {
      return {};
    }
  }

  Map<String, dynamic> _normalizeLog(Map<String, dynamic> log) {
    return {
      'id': log['id'],
      'alunoId': log['aluno_id'],
      'rotinaId': log['rotina_id'],
      'sessaoNome': log['sessao_nome'],
      'dataHora': log['data_hora'],
      'duracaoMinutos': log['duracao_minutos'],
      'esforco': log['esforco'],
      'observacoes': log['observacoes'],
      'exercicios': log['exercicios'],
    };
  }

  TipoSerie _parsetipoSerie(String tipoStr) {
    return switch (tipoStr.toLowerCase().trim()) {
      'aquecimento' => TipoSerie.aquecimento,
      'feeder' => TipoSerie.feeder,
      _ => TipoSerie.trabalho,
    };
  }
}