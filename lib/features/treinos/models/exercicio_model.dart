enum TipoSerie { aquecimento, feeder, trabalho }

class SerieItem {
  TipoSerie tipo;
  String alvo;
  String carga;
  String descanso;

  SerieItem({
    this.tipo = TipoSerie.trabalho,
    this.alvo = '10',
    this.carga = '-',
    this.descanso = '60s',
  });
}

class ExercicioItem {
  String nome;
  String grupoMuscular;
  String observacao;
  String tipoAlvo;
  String? imagemUrl;
  List<SerieItem> series;

  ExercicioItem({
    required this.nome,
    this.grupoMuscular = 'Peito',
    this.observacao = '',
    this.tipoAlvo = 'Reps',
    this.imagemUrl,
    required this.series,
  });
}
