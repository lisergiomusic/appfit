
class AlunoPerfilData {
  final Map<String, dynamic> aluno;
  final Map<String, dynamic>? rotinaAtiva;
  final String? rotinaId;
  final String? nomePersonal;
  final String? especialidadePersonal;
  final String? photoUrlPersonal;
  final String? telefonePersonal;

  AlunoPerfilData({
    required this.aluno,
    this.rotinaAtiva,
    this.rotinaId,
    this.nomePersonal,
    this.especialidadePersonal,
    this.photoUrlPersonal,
    this.telefonePersonal,
  });
}
