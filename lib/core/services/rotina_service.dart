import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class RotinaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> criarRotina({
    String? alunoId,
    required String nome,
    required String objetivo,
    required List<Map<String, dynamic>> sessoes,
    required String tipoVencimento,
    int? sessoesAlvo,
    DateTime? dataVencimento,
  }) async {
    final personalId = _supabase.auth.currentUser?.id;
    if (personalId == null) throw Exception('Personal não autenticado.');

    try {
      if (alunoId != null) {
        // Desativa rotinas anteriores
        await _supabase
            .from('rotinas')
            .update({'ativa': false})
            .eq('aluno_id', alunoId)
            .eq('ativa', true);
      }

      final Map<String, dynamic> payload = {
        'personal_id': personalId,
        'aluno_id': alunoId,
        'nome': nome,
        'objetivo': objetivo,
        'sessoes': sessoes,
        'ativa': alunoId != null,
        'tipo_vencimento': tipoVencimento,
        'data_criacao': DateTime.now().toIso8601String(),
      };

      if (tipoVencimento == 'sessoes') {
        payload['vencimento_sessoes'] = sessoesAlvo ?? 20;
        payload['sessoes_concluidas'] = 0;
      } else {
        payload['data_vencimento'] = (dataVencimento ?? DateTime.now().add(const Duration(days: 30))).toIso8601String();
      }

      final res = await _supabase.from('rotinas').insert(payload).select().single();
      return res['id'].toString();
    } catch (e) {
      throw Exception('Erro ao criar rotina: $e');
    }
  }

  Future<void> atualizarRotina({
    required String rotinaId,
    required String nome,
    required String objetivo,
    required List<Map<String, dynamic>> sessoes,
    String? tipoVencimento,
    int? sessoesAlvo,
    DateTime? dataVencimento,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'nome': nome,
        'objetivo': objetivo,
        'sessoes': sessoes,
      };

      if (tipoVencimento != null) {
        updateData['tipo_vencimento'] = tipoVencimento;
        if (tipoVencimento == 'sessoes') {
          updateData['vencimento_sessoes'] = sessoesAlvo;
        } else if (dataVencimento != null) {
          updateData['data_vencimento'] = dataVencimento.toIso8601String();
        }
      }

      await _supabase.from('rotinas').update(updateData).eq('id', rotinaId);
    } catch (e) {
      throw Exception('Erro ao atualizar rotina: $e');
    }
  }

  Future<void> renomearRotina(String rotinaId, String novoNome) async {
    await _supabase.from('rotinas').update({'nome': novoNome}).eq('id', rotinaId);
  }

  Future<void> excluirRotina(String rotinaId) async {
    await _supabase.from('rotinas').delete().eq('id', rotinaId);
  }
}