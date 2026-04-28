import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';
import '../../features/alunos/shared/models/aluno_perfil_data.dart';

class AlunoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _currentPersonalId => _supabase.auth.currentUser?.id;

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
        'nome': nome,
        'email': email,
        'sobrenome': sobrenome,
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

  /// Atualiza dados de saúde e perfil do aluno
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

  /// Busca um aluno por ID (na tabela profiles)
  Future<Map<String, dynamic>> getAluno(String alunoId) async {
    try {
      final data = await _supabase.from('profiles').select().eq('id', alunoId).single();
      return data;
    } catch (e) {
      throw Exception('Erro ao buscar aluno: $e');
    }
  }

  /// Deleta um aluno (perfil)
  Future<void> deletarAluno(String alunoId) async {
    try {
      await _supabase.from('profiles').delete().eq('id', alunoId);
    } catch (e) {
      throw Exception('Erro ao deletar aluno: $e');
    }
  }

  /// Perfil completo do aluno (Dados + Rotina Ativa + Info do Personal)
  Stream<AlunoPerfilData> getAlunoPerfilCompletoStream(String alunoId) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', alunoId)
        .switchMap((alunoList) {
          if (alunoList.isEmpty) {
            return Stream.value(AlunoPerfilData(aluno: {}, rotinaAtiva: null));
          }

          final alunoMap = alunoList.first;
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
        });
  }

  /// Busca as planilhas de um aluno com normalização de campos
  Stream<List<Map<String, dynamic>>> getPlanilhasStream(String alunoId) {
    return _supabase
        .from('rotinas')
        .stream(primaryKey: ['id'])
        .eq('aluno_id', alunoId)
        .map((list) => list.map((r) => _normalizeRotina(r)).toList());
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

  Stream<List<Map<String, dynamic>>> getLogsDaSemanaStream(String alunoId) => Stream.value([]);
  Stream<List<Map<String, dynamic>>> getUltimoLogStream(String alunoId) => Stream.value([]);
  Stream<List<Map<String, dynamic>>> getHistoricoPesoStream(String alunoId) => Stream.value([]);

  Future<void> registrarPeso({required String alunoId, required double peso}) async {
    // TODO: Implementar registro de peso no Supabase
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