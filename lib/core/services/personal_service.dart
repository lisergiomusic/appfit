import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/aluno_service.dart';

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

      return ContagemAlunos(
        total: list.length,
        ativos: ativos,
        inativos: list.length - ativos,
        risco: 0, // TODO: Implementar lógica de risco baseada no último treino
      );
    } catch (e) {
      return ContagemAlunos(total: 0, ativos: 0, inativos: 0, risco: 0);
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
    if (personalId == null) return Stream.value([]);

    return _supabase
        .from('rotinas')
        .stream(primaryKey: ['id'])
        .eq('personal_id', personalId)
        .map((list) => list.where((r) => r['aluno_id'] == null).toList());
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

  /// Busca o feed de atividade recente (logs de treino)
  Stream<List<AtividadeRecenteItem>> getAtividadeRecenteStream({int limit = 10}) {
    // TODO: Implementar stream real da tabela logs_treino
    return Stream.value(<AtividadeRecenteItem>[]);
  }

  /// Busca atividade recente paginada
  Future<({List<AtividadeRecenteItem> items, dynamic lastDoc})> fetchAtividadePage({
    int limit = 20,
    dynamic startAfter,
  }) async {
    // TODO: Implementar fetch real
    return (items: <AtividadeRecenteItem>[], lastDoc: null);
  }
}