import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';
import '../../features/alunos/shared/models/aluno_perfil_data.dart';

class AlunoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Perfil completo do aluno (Dados + Rotina Ativa + Info do Personal)
  Stream<AlunoPerfilData> getAlunoPerfilCompletoStream(String alunoId) {
    // Pegamos o e-mail do usuário logado via Auth
    final userEmail = _supabase.auth.currentUser?.email;

    // Criamos um stream que tenta buscar pelo ID primeiro.
    // Se a lista vier vazia, fazemos o switch para buscar pelo E-mail.
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', alunoId)
        .switchMap<AlunoPerfilData>((alunoList) {
          if (alunoList.isNotEmpty) {
            return _buildFullProfileStream(alunoList.first);
          }

          // FALLBACK: Se pelo ID não veio nada, tentamos pelo e-mail
          if (userEmail != null) {

            // Usamos .from(...).select() em vez de .stream() para o fallback inicial
            // para evitar comportamentos estranhos de múltiplos streams abertos
            return _supabase
                .from('profiles')
                .select()
                .ilike('email', userEmail.trim())
                .eq('tipo_usuario', 'aluno')
                .asStream()
                .switchMap<AlunoPerfilData>((list) {
                  if (list.isNotEmpty) {
                    return _buildFullProfileStream(list.first);
                  }

                  return Stream.value(AlunoPerfilData(aluno: {}));
                });
          }

          return Stream.value(AlunoPerfilData(aluno: {}));
        }).asBroadcastStream();
  }

  Stream<AlunoPerfilData> _buildFullProfileStream(Map<String, dynamic> alunoMap) {
    final alunoId = alunoMap['id'].toString();
    final personalId = alunoMap['personal_id'];

    final rotinaStream = _supabase
        .from('rotinas')
        .stream(primaryKey: ['id'])
        .eq('aluno_id', alunoId)
        .map((list) {
          try {
            return list.firstWhere((r) => r['ativa'] == true);
          } catch (_) {
            return null;
          }
        });

    final personalStream = personalId != null
        ? _supabase
            .from('profiles')
            .stream(primaryKey: ['id'])
            .eq('id', personalId)
            .map((list) => list.isNotEmpty ? list.first : null)
        : Stream<Map<String, dynamic>?>.value(null);

    return Rx.combineLatest2<Map<String, dynamic>?, Map<String, dynamic>?, AlunoPerfilData>(
      rotinaStream,
      personalStream,
      (rotina, personal) {
        return AlunoPerfilData(
          aluno: alunoMap,
          rotinaAtiva: rotina,
          rotinaId: rotina?['id']?.toString(),
          nomePersonal: personal != null
              ? '${personal['nome']} ${personal['sobrenome'] ?? ''}'.trim()
              : null,
          especialidadePersonal: personal?['especialidade'],
          photoUrlPersonal: personal?['photoUrl'],
          telefonePersonal: personal?['telefone'],
        );
      },
    );
  }

  /// Busca as planilhas de um aluno com normalização de campos
  Stream<List<Map<String, dynamic>>> getPlanilhasStream(String alunoId) {
    return _supabase
        .from('rotinas')
        .stream(primaryKey: ['id'])
        .eq('aluno_id', alunoId)
        .map((list) => list.map((r) => _normalizeRotina(r)).toList())
        .asBroadcastStream();
  }

  Map<String, dynamic> _normalizeRotina(Map<String, dynamic> r) {
    return {
      ...r,
      'dataCriacao': r['data_criacao'],
      'dataVencimento': r['data_vencimento'],
      'tipoVencimento': r['tipo_vencimento'],
      'vencimentoSessoes': r['vencimento_sessoes'],
      'sessoesConcluidas': r['sessoes_concluidas'],
    };
  }

  Stream<List<Map<String, dynamic>>> getLogsDaSemanaStream(String alunoId) =>
      Stream.value(<Map<String, dynamic>>[]).asBroadcastStream();
  Stream<List<Map<String, dynamic>>> getUltimoLogStream(String alunoId) =>
      Stream.value(<Map<String, dynamic>>[]).asBroadcastStream();
  /// Stream do histórico de peso do aluno (Resiliente a descompasso de ID)
  Stream<List<Map<String, dynamic>>> getHistoricoPesoStream(String alunoId) {
    final email = _supabase.auth.currentUser?.email;

    // 1. Primeiro buscamos o perfil para garantir que temos o ID correto (o que está no banco)
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('email', email ?? '')
        .switchMap((profiles) {
          if (profiles.isEmpty) return Stream.value([]);

          // 2. Agora que temos o ID real do banco, ouvimos o histórico dele
          final realId = profiles.first['id'];
          
          return _supabase
              .from('historico_peso')
              .stream(primaryKey: ['id'])
              .eq('aluno_id', realId)
              .order('data_hora', ascending: false)
              .map((list) => list.map((item) => {
                    'id': item['id'],
                    'peso': item['peso'],
                    'dataHora': item['data_hora'],
                  }).toList());
        });
  }

  /// Registra um novo peso: atualiza o perfil e insere no histórico
  Future<void> registrarPeso({required String alunoId, required double peso}) async {
    try {
      final user = _supabase.auth.currentUser;
      final email = user?.email;

      if (email == null) throw Exception('Usuário não autenticado.');

      // 1. Busca o ID interno que já existe no banco para este e-mail
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .ilike('email', email.trim())
          .maybeSingle();

      if (profile == null) throw Exception('Perfil não encontrado.');
      final String targetId = profile['id'].toString();

      // 2. Tenta sincronizar o ID do banco com o do Auth em background
      // (Não esperamos o resultado para não travar o usuário)
      if (targetId != user!.id) {
        _supabase.from('profiles').update({'id': user!.id}).eq('email', email.trim()).then((_) {
          debugPrint('>>> [AlunoService] ID sincronizado com sucesso.');
        }).catchError((e) {
          debugPrint('>>> [AlunoService] Falha silenciosa ao sincronizar ID: $e');
        });
      }

      // 3. Atualiza o peso_atual no perfil
      await _supabase.from('profiles').update({
        'peso_atual': peso,
      }).eq('id', targetId);

      // 4. Insere no histórico de peso
      await _supabase.from('historico_peso').insert({
        'aluno_id': targetId,
        'peso': peso,
        'data_hora': DateTime.now().toIso8601String(),
      });

      debugPrint('>>> [AlunoService] Peso registrado com sucesso.');
    } catch (e) {
      debugPrint('>>> [AlunoService] Erro ao registrar peso: $e');
      rethrow;
    }
  }
}

class AtividadeRecenteItem {
  final String logId;
  final String alunoId;
  final String alunoNome;
  final String? alunoPhotoUrl;
  final String sessaoNome;
  final DateTime dataHora;
  final int duracaoMinutos;
  final int? esforco;
  final String? observacoes;
  final List<Map<String, dynamic>> exercicios;

  const AtividadeRecenteItem({
    required this.logId,
    required this.alunoId,
    required this.alunoNome,
    this.alunoPhotoUrl,
    required this.sessaoNome,
    required this.dataHora,
    required this.duracaoMinutos,
    this.esforco,
    this.observacoes,
    required this.exercicios,
  });
}