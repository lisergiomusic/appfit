
class AlunoPerfilData {
  final Map<String, dynamic> aluno;
  final Map<String, dynamic>? rotinaAtiva;
  final String? rotinaId;
  final String? nomePersonal;

  AlunoPerfilData({
    required this.aluno,
    this.rotinaAtiva,
    this.rotinaId,
    this.nomePersonal,
  });
}
