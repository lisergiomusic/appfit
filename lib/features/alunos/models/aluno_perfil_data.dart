
class AlunoPerfilData {
  final Map<String, dynamic> aluno;
  final Map<String, dynamic>? rotinaAtiva;
  final String? rotinaId;

  AlunoPerfilData({
    required this.aluno,
    this.rotinaAtiva,
    this.rotinaId,
  });
}