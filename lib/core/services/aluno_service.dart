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
  Stream<List<Map<String, dynamic>>> getHistoricoPesoStream(String alunoId) =>
      Stream.value(<Map<String, dynamic>>[]).asBroadcastStream();

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