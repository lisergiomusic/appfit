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
  String? id; // Adicionado ID para identificação única
  String nome;
  String grupoMuscular;
  String tipoAlvo;
  String? imagemUrl;
  String? personalId;
  List<SerieItem> series;

  ExercicioItem({
    this.id,
    required this.nome,
    this.grupoMuscular = 'Geral',
    this.tipoAlvo = 'Reps',
    this.imagemUrl,
    this.personalId,
    required this.series,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'grupoMuscular': grupoMuscular,
      'imagemUrl': imagemUrl,
      'tipoAlvo': tipoAlvo,
      'personalId': personalId,
    };
  }

  factory ExercicioItem.fromFirestore(Map<String, dynamic> data, [String? docId]) {
    return ExercicioItem(
      id: docId,
      nome: data['nome'] ?? '',
      grupoMuscular: data['grupoMuscular'] ?? 'Geral',
      imagemUrl: data['imagemUrl'],
      tipoAlvo: data['tipoAlvo'] ?? 'Reps',
      personalId: data['personalId'],
      series: [],
    );
  }

  ExercicioItem clone() {
    return ExercicioItem(
      id: id,
      nome: nome,
      grupoMuscular: grupoMuscular,
      tipoAlvo: tipoAlvo,
      imagemUrl: imagemUrl,
      personalId: personalId,
      series: series.map((s) => s.clone()).toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExercicioItem &&
          runtimeType == other.runtimeType &&
          (id != null && other.id != null ? id == other.id : nome == other.nome && personalId == other.personalId);

  @override
  int get hashCode => id != null ? id.hashCode : nome.hashCode ^ personalId.hashCode;
}
