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
            final rawRotina = list.firstWhere((r) => r['ativa'] == true);
            return _normalizeRotina(rawRotina);
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

  /// Stream dos logs de treino da semana atual (para o Ritmo da Semana)
  Stream<List<Map<String, dynamic>>> getLogsDaSemanaStream(String alunoId) {
    return _resolveRealIdStream(alunoId).switchMap((realId) {
      if (realId == null) return Stream.value([]);

      // Ouvimos diretamente a tabela de logs.
      // O RLS deve garantir que o Aluno veja apenas seus logs e o Personal veja os dos alunos.
      return _supabase
          .from('logs_treino')
          .stream(primaryKey: ['id'])
          .eq('aluno_id', realId)
          .map((list) {
            final now = DateTime.now();
            // Segunda-feira como início da semana
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            final startOfDate =
                DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

            final filtrados = list
                .where((item) {
                  final dataHoraStr = item['data_hora']?.toString();
                  if (dataHoraStr == null) return false;
                  final dataHora = DateTime.tryParse(dataHoraStr);
                  // Compara se é após o início da segunda-feira
                  return dataHora != null && dataHora.isAfter(startOfDate);
                })
                .map((item) => {
                      'id': item['id'],
                      'dataHora': item['data_hora'],
                    })
                .toList();

            debugPrint(
                '>>> [AlunoService] Logs encontrados para a semana: ${filtrados.length}');
            return filtrados;
          });
    });
  }

  /// Stream do último log de treino (para calcular o próximo treino na sequência)
  Stream<List<Map<String, dynamic>>> getUltimoLogStream(String alunoId) {
    return _resolveRealIdStream(alunoId).switchMap((realId) {
      if (realId == null) return Stream.value([]);

      return _supabase
          .from('logs_treino')
          .stream(primaryKey: ['id'])
          .eq('aluno_id', realId)
          .order('data_hora', ascending: false)
          .limit(1)
          .map((list) => list
              .map((item) => {
                    'id': item['id'],
                    'sessaoNome': item['sessao_nome'],
                    'dataHora': item['data_hora'],
                  })
              .toList());
    });
  }

  /// Stream do histórico de peso do aluno (Resiliente a descompasso de ID)
  Stream<List<Map<String, dynamic>>> getHistoricoPesoStream(String alunoId) {
    return _resolveRealIdStream(alunoId).switchMap((realId) {
      if (realId == null) return Stream.value([]);

      return _supabase
          .from('historico_peso')
          .stream(primaryKey: ['id'])
          .eq('aluno_id', realId)
          .order('data_hora', ascending: false)
          .map((list) => list
              .map((item) => {
                    'id': item['id'],
                    'peso': item['peso'],
                    'dataHora': item['data_hora'],
                  })
              .toList());
    });
  }

  /// Resolve o ID real do banco (profiles), lidando com descompassos entre Auth ID e Profile ID
  Stream<String?> _resolveRealIdStream(String alunoId) {
    final user = _supabase.auth.currentUser;
    final isMe = user?.id == alunoId;

    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', alunoId)
        .switchMap((list) {
          if (list.isEmpty && isMe && user?.email != null) {
            // Se eu sou o aluno e meu ID de Auth não está no Profiles, busca pelo e-mail
            return _supabase
                .from('profiles')
                .stream(primaryKey: ['id'])
                .eq('email', user!.email!)
                .map((l) => l.isNotEmpty ? l.first['id'].toString() : null);
          }
          return Stream.value(list.isNotEmpty ? list.first['id'].toString() : null);
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