import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/alunos/shared/models/aluno_perfil_data.dart';

class PaginatedAlunos {
  final List<dynamic> docs;
  final dynamic lastDoc;
  final bool hasMore;

  PaginatedAlunos({required this.docs, this.lastDoc, required this.hasMore});
}

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

class AlunoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _currentPersonalId => _supabase.auth.currentUser?.id;

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
        'nome': nome,
        'email': email,
        'sobrenome': sobrenome, // Adicionado campo sobrenome que faltava
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

  Future<void> atualizarAluno({
    required String alunoId,
    required String nome,
    required String sobrenome,
    required String email,
    String? telefone,
    double? peso,
    double? altura,
    DateTime? dataNascimento,
    String? genero,
    String? recadoPersonal,
  }) async {
    try {
      await _supabase.from('profiles').update({
        'nome': nome,
        'sobrenome': sobrenome,
        'email': email,
        'telefone': telefone,
        'data_nascimento': dataNascimento?.toIso8601String(),
        'genero': genero,
      }).eq('id', alunoId);
    } catch (e) {
      throw Exception('Erro ao atualizar: $e');
    }
  }

  Future<Map<String, dynamic>> getAluno(String alunoId) async {
    final data = await _supabase.from('profiles').select().eq('id', alunoId).single();
    return data;
  }

  Future<void> deletarAluno(String alunoId) async {
    await _supabase.from('profiles').delete().eq('id', alunoId);
  }

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
        risco: 0,
      );
    } catch (e) {
      return ContagemAlunos(total: 0, ativos: 0, inativos: 0, risco: 0);
    }
  }

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

    final List<dynamic> data = await query.order('nome').limit(limit);
    return PaginatedAlunos(
      docs: data,
      lastDoc: null,
      hasMore: data.length == limit,
    );
  }

  Stream<List<AtividadeRecenteItem>> getAtividadeRecenteStream({int limit = 10}) => Stream.value([]);
  Stream<AlunoPerfilData> getAlunoPerfilCompletoStream(String alunoId) => Stream.value(AlunoPerfilData(aluno: {}, rotinaAtiva: null));
  Stream<List<Map<String, dynamic>>> getLogsDaSemanaStream(String alunoId) => Stream.value([]);
  Stream<List<Map<String, dynamic>>> getUltimoLogStream(String alunoId) => Stream.value([]);
  Stream<List<Map<String, dynamic>>> getRotinasTemplates() => Stream.value([]);
  Stream<List<Map<String, dynamic>>> getPlanilhasStream(String alunoId) => Stream.value([]);
  Stream<List<Map<String, dynamic>>> getHistoricoPesoStream(String alunoId) => Stream.value([]);
  
  Future<void> registrarPeso({required String alunoId, required double peso}) async {}
  
  // Corrigido o nome do parâmetro para bater com a UI
  Future<void> atribuirTreinoAoAluno({
    required String alunoId, 
    required String templateId, 
    String? tipoVencimento,
    int? sessoesAlvo,
    DateTime? dataVencimento,
  }) async {}

  Future<dynamic> fetchAtividadePage({int limit = 20, dynamic startAfter}) async => (items: [], lastDoc: null);
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