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

  SerieItem clone() {
    return SerieItem(tipo: tipo, alvo: alvo, carga: carga, descanso: descanso);
  }
}

class ExercicioItem {
  String nome;
  String grupoMuscular;
  String observacao;
  String tipoAlvo;
  String? imagemUrl;
  List<SerieItem> series;

  factory ExercicioItem.fromApi(Map<String, dynamic> json) {
    return ExercicioItem(
      nome: json['name'] ?? 'Exercício sem nome',
      observacao: (json['instructions'] as List?)?.join('\n') ?? '',
      grupoMuscular: (json['targetMuscles'] as List?)?.first ?? 'Geral',
      imagemUrl: json['gifUrl'],
      series: [],
    );
  }

  ExercicioItem({
    required this.nome,
    this.grupoMuscular = 'Peito',
    this.observacao = '',
    this.tipoAlvo = 'Reps',
    this.imagemUrl,
    required this.series,
  });

  ExercicioItem clone() {
    return ExercicioItem(
      nome: nome,
      grupoMuscular: grupoMuscular,
      observacao: observacao,
      tipoAlvo: tipoAlvo,
      imagemUrl: imagemUrl,
      series: series.map((s) => s.clone()).toList(),
    );
  }
}
