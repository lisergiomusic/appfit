import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/aluno_service.dart';
import '../models/atencao_item.dart';

class ContagemAlunos {
  final int total;
  final int ativos;
  final int inativos;
  final int risco;

  ContagemAlunos({
    required this.total,
    required this.ativos,
    required this.inativos,
    required this.risco,
  });
}

class PaginatedAlunos {
  final List<dynamic> docs;
  final dynamic lastDoc;
  final bool hasMore;

  PaginatedAlunos({required this.docs, this.lastDoc, required this.hasMore});
}

class PersonalService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _currentPersonalId => _supabase.auth.currentUser?.id;

  /// Busca as métricas do dashboard do personal
  Future<ContagemAlunos> fetchContagens() async {
    final personalId = _currentPersonalId;
    if (personalId == null) return ContagemAlunos(total: 0, ativos: 0, inativos: 0, risco: 0);

    try {
      final res = await _supabase
          .from('profiles')
          .select('id, status')
          .eq('personal_id', personalId)
          .eq('tipo_usuario', 'aluno');

      final list = res as List;
      final ativos = list.where((a) => a['status'] == 'ativo').length;

      // Busca contagem de itens de atenção para o campo 'risco'
      final itensAtencao = await fetchAtencaoItems();

      return ContagemAlunos(
        total: list.length,
        ativos: ativos,
        inativos: list.length - ativos,
        risco: itensAtencao.length,
      );
    } catch (e) {
      return ContagemAlunos(total: 0, ativos: 0, inativos: 0, risco: 0);
    }
  }

  /// Busca itens que precisam de atenção do personal
  Future<List<AtencaoItem>> fetchAtencaoItems() async {
    final personalId = _currentPersonalId;
    if (personalId == null) return [];

    try {
      final items = <AtencaoItem>[];
      final agora = DateTime.now();

      // 1. Busca alunos ativos
      final alunosRes = await _supabase
          .from('profiles')
          .select('id, nome, sobrenome, photo_url, ultimo_treino, status')
          .eq('personal_id', personalId)
          .eq('tipo_usuario', 'aluno')
          .eq('status', 'ativo');

      final alunos = alunosRes as List;

      // 2. Busca rotinas ativas para checar vencimento e falta de planejamento
      final rotinasRes = await _supabase
          .from('rotinas')
          .select('id, aluno_id, data_vencimento, ativa')
          .eq('personal_id', personalId)
          .eq('ativa', true)
          .not('aluno_id', 'is', null);

      final rotinasAtivas = rotinasRes as List;

      for (var aluno in alunos) {
        final alunoId = aluno['id'];
        final nomeCompleto = '${aluno['nome']} ${aluno['sobrenome'] ?? ''}'.trim();
        final photoUrl = aluno['photo_url'];

        // Checar Inatividade (> 7 dias)
        if (aluno['ultimo_treino'] != null) {
          final ultimoTreino = DateTime.parse(aluno['ultimo_treino']);
          final diffDias = agora.difference(ultimoTreino).inDays;
          if (diffDias >= 7) {
            items.add(AtencaoItem(
              alunoId: alunoId,
              alunoNome: nomeCompleto,
              alunoPhotoUrl: photoUrl,
              tipo: TipoAtencao.inatividade,
              descricao: 'Sem treinar há $diffDias dias',
              dataReferencia: ultimoTreino,
            ));
          }
        }

        // Checar Falta de Planejamento (Ativo sem rotina ativa)
        final temRotinaAtiva = rotinasAtivas.any((r) => r['aluno_id'] == alunoId);
        if (!temRotinaAtiva) {
          items.add(AtencaoItem(
            alunoId: alunoId,
            alunoNome: nomeCompleto,
            alunoPhotoUrl: photoUrl,
            tipo: TipoAtencao.semPlanejamento,
            descricao: 'Não possui treino ativo atribuído',
            dataReferencia: agora,
          ));
        } else {
          // Checar Vencimento Próximo (< 5 dias)
          final rotina = rotinasAtivas.firstWhere((r) => r['aluno_id'] == alunoId);
          if (rotina['data_vencimento'] != null) {
            final dataVencimento = DateTime.parse(rotina['data_vencimento']);
            final diffVencimento = dataVencimento.difference(agora).inDays;

            if (diffVencimento <= 5) {
              final jaVenceu = diffVencimento < 0;
              items.add(AtencaoItem(
                alunoId: alunoId,
                alunoNome: nomeCompleto,
                alunoPhotoUrl: photoUrl,
                tipo: TipoAtencao.vencimento,
                descricao: jaVenceu ? 'Treino vencido' : 'Vence em $diffVencimento dias',
                dataReferencia: dataVencimento,
              ));
            }
          }
        }
      }

      // 3. Feedback Crítico (últimos logs com esforço >= 9)
      final logsRes = await _supabase
          .from('logs_treino')
          .select('id, aluno_id, esforco, data_hora, profiles:profiles!logs_treino_aluno_id_fkey(nome, sobrenome, photo_url)')
          .eq('personal_id', personalId)
          .gte('esforco', 9)
          .order('data_hora', ascending: false)
          .limit(10);

      final logsCriticos = logsRes as List;
      for (var log in logsCriticos) {
        final profile = log['profiles'];
        final dataHora = DateTime.parse(log['data_hora']);

        // Só adicionar se for recente (últimos 3 dias) para não poluir
        if (agora.difference(dataHora).inDays <= 3) {
          items.add(AtencaoItem(
            alunoId: log['aluno_id'],
            alunoNome: '${profile['nome']} ${profile['sobrenome'] ?? ''}'.trim(),
            alunoPhotoUrl: profile['photo_url'],
            tipo: TipoAtencao.feedbackCritico,
            descricao: 'Relatou esforço nível ${log['esforco']}',
            dataReferencia: dataHora,
          ));
        }
      }

      // Ordenar por data de referência (mais recentes/urgentes primeiro)
      items.sort((a, b) => b.dataReferencia.compareTo(a.dataReferencia));

      return items;
    } catch (e) {
      return [];
    }
  }

  /// Busca a lista paginada de alunos
  Future<PaginatedAlunos> fetchAlunosPaginado({
    required String statusFilter,
    required String searchQuery,
    dynamic lastDoc,
    int limit = 20,
  }) async {
    final personalId = _currentPersonalId;
    if (personalId == null) throw Exception('Personal não autenticado');

    var query = _supabase
        .from('profiles')
        .select()
        .eq('personal_id', personalId)
        .eq('tipo_usuario', 'aluno');

    if (searchQuery.isNotEmpty) {
      query = query.ilike('nome', '%$searchQuery%');
    }

    if (statusFilter != 'todos') {
      query = query.eq('status', statusFilter);
    }

    final List<dynamic> data = await query.order('nome').limit(limit);
    return PaginatedAlunos(
      docs: data,
      lastDoc: null,
      hasMore: data.length == limit,
    );
  }

  /// Busca os modelos de rotinas (biblioteca do personal)
  Stream<List<Map<String, dynamic>>> getRotinasTemplates() {
    final personalId = _currentPersonalId;
    if (personalId == null) return Stream.value(<Map<String, dynamic>>[]);

    return _supabase
        .from('rotinas')
        .stream(primaryKey: ['id'])
        .eq('personal_id', personalId)
        .map((list) => list.where((r) => r['aluno_id'] == null).toList())
        .asBroadcastStream();
  }

  /// Atribui um treino da biblioteca a um aluno específico
  Future<void> atribuirTreinoAoAluno({
    required String alunoId,
    required String templateId,
    String? tipoVencimento,
    int? sessoesAlvo,
    DateTime? dataVencimento,
  }) async {
    try {
      final template = await _supabase
          .from('rotinas')
          .select()
          .eq('id', templateId)
          .single();

      // Desativa rotinas anteriores
      await _supabase
          .from('rotinas')
          .update({'ativa': false})
          .eq('aluno_id', alunoId)
          .eq('ativa', true);

      final novaRotina = {
        'aluno_id': alunoId,
        'personal_id': _currentPersonalId,
        'nome': template['nome'],
        'objetivo': template['objetivo'],
        'sessoes': template['sessoes'],
        'ativa': true,
        'tipo_vencimento': tipoVencimento ?? template['tipo_vencimento'] ?? 'data',
        'vencimento_sessoes': sessoesAlvo ?? template['vencimento_sessoes'],
        'data_vencimento': dataVencimento?.toIso8601String() ?? template['data_vencimento'],
        'data_criacao': DateTime.now().toIso8601String(),
      };

      await _supabase.from('rotinas').insert(novaRotina);
    } catch (e) {
      throw Exception('Erro ao atribuir treino: $e');
    }
  }

  /// Cadastro de novo aluno pelo personal
  Future<void> salvarAluno(
    String nome,
    String sobrenome,
    String email, {
    String? whatsapp,
    String? genero,
    DateTime? dataNascimento,
  }) async {
    final personalId = _currentPersonalId;
    if (personalId == null) throw Exception('Personal não autenticado');

    try {
      await _supabase.from('profiles').insert({
        'nome': nome.trim(),
        'email': email.trim().toLowerCase(),
        'sobrenome': sobrenome.trim(),
        'tipo_usuario': 'aluno',
        'personal_id': personalId,
        'telefone': whatsapp,
        'genero': genero,
        'data_nascimento': dataNascimento?.toIso8601String(),
        'status': 'ativo',
      });
    } catch (e) {
      throw Exception('Erro ao salvar aluno: $e');
    }
  }

  /// Remove um aluno definitivamente
  Future<void> deletarAluno(String alunoId) async {
    try {
      await _supabase.from('profiles').delete().eq('id', alunoId);
    } catch (e) {
      throw Exception('Erro ao deletar aluno: $e');
    }
  }

  /// Atualiza os dados de um aluno (Visão do Personal)
  Future<void> atualizarDadosAluno({
    required String alunoId,
    required String nome,
    required String sobrenome,
    required String email,
    String? telefone,
    double? peso,
    DateTime? dataNascimento,
    String? genero,
  }) async {
    try {
      await _supabase.from('profiles').update({
        'nome': nome,
        'sobrenome': sobrenome,
        'email': email,
        'telefone': telefone,
        'peso_atual': peso,
        'data_nascimento': dataNascimento?.toIso8601String(),
        'genero': genero,
      }).eq('id', alunoId);
    } catch (e) {
      throw Exception('Erro ao atualizar aluno: $e');
    }
  }

  /// Busca o feed de atividade recente (logs de treino)
  Stream<List<AtividadeRecenteItem>> getAtividadeRecenteStream({int limit = 10}) {
    final personalId = _currentPersonalId;
    if (personalId == null) return Stream.value(<AtividadeRecenteItem>[]);

    return _supabase
        .from('logs_treino')
        .stream(primaryKey: ['id'])
        .eq('personal_id', personalId)
        .order('data_hora', ascending: false)
        .limit(limit)
        .asyncMap<List<AtividadeRecenteItem>>((logs) async {
          if (logs.isEmpty) return <AtividadeRecenteItem>[];

          // Buscamos os perfis dos alunos envolvidos para evitar N+1 queries
          final alunoIds = logs.map((l) => l['aluno_id'] as String).toSet().toList();
          final profilesRes = await _supabase
              .from('profiles')
              .select('id, nome, sobrenome, photo_url')
              .filter('id', 'in', '(${alunoIds.join(',')})');

          final profilesMap = {
            for (var p in profilesRes as List) p['id']: p
          };

          return logs.map((log) {
            final profile = profilesMap[log['aluno_id']];
            return AtividadeRecenteItem(
              logId: log['id'].toString(),
              alunoId: log['aluno_id'].toString(),
              alunoNome: profile != null
                  ? '${profile['nome']} ${profile['sobrenome'] ?? ''}'.trim()
                  : 'Aluno',
              alunoPhotoUrl: profile?['photo_url'],
              sessaoNome: log['nome_sessao'] ?? 'Treino Concluído',
              dataHora: DateTime.parse(log['data_hora']),
              duracaoMinutos: log['duracao_minutos'] ?? 0,
              esforco: log['esforco'],
              observacoes: log['observacoes'],
              exercicios: <Map<String, dynamic>>[],
            );
          }).toList();
        }).asBroadcastStream();
  }

  /// Busca atividade recente paginada
  Future<({List<AtividadeRecenteItem> items, dynamic lastDoc})> fetchAtividadePage({
    int limit = 20,
    dynamic startAfter,
  }) async {
    final personalId = _currentPersonalId;
    if (personalId == null) return (items: <AtividadeRecenteItem>[], lastDoc: null);

    var query = _supabase
        .from('logs_treino')
        .select('*, profiles:profiles!logs_treino_aluno_id_fkey(nome, sobrenome, photo_url)')
        .eq('personal_id', personalId);

    if (startAfter != null) {
      query = query.filter('data_hora', 'lt', startAfter);
    }

    try {
      final res = await query.order('data_hora', ascending: false).limit(limit);
      final logs = res as List;

      final items = logs.map((log) {
        final profile = log['profiles'];
        return AtividadeRecenteItem(
          logId: log['id'].toString(),
          alunoId: log['aluno_id'].toString(),
          alunoNome: profile != null
              ? '${profile['nome']} ${profile['sobrenome'] ?? ''}'.trim()
              : 'Aluno',
          alunoPhotoUrl: profile?['photo_url'],
          sessaoNome: log['nome_sessao'] ?? 'Treino Concluído',
          dataHora: DateTime.parse(log['data_hora']),
          duracaoMinutos: log['duracao_minutos'] ?? 0,
          esforco: log['esforco'],
          observacoes: log['observacoes'],
          exercicios: <Map<String, dynamic>>[],
        );
      }).toList();

      return (
        items: items,
        lastDoc: items.isNotEmpty ? items.last.dataHora.toIso8601String() : null,
      );
    } catch (e) {
      return (items: <AtividadeRecenteItem>[], lastDoc: null);
    }
  }
}