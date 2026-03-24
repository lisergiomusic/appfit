import 'dart:math';

enum TipoSerie { aquecimento, feeder, trabalho }

class SerieItem {
  final String id;
  TipoSerie tipo;
  String alvo;
  String carga;
  String descanso;

  SerieItem({
    String? id,
    this.tipo = TipoSerie.trabalho,
    this.alvo = '10',
    this.carga = '-',
    this.descanso = '60s',
  }) : id = id ?? _generateId();

  static String _generateId() {
    return '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  SerieItem clone() {
    return SerieItem(id: id, tipo: tipo, alvo: alvo, carga: carga, descanso: descanso);
  }
}

class ExercicioItem {
  String? id; // Adicionado ID para identificação única
  String nome;
  List<String> grupoMuscular;
  String tipoAlvo;
  String? imagemUrl;
  String? personalId;
  String? instrucoes;
  List<SerieItem> series;

  ExercicioItem({
    this.id,
    required this.nome,
    this.grupoMuscular = const ['Geral'],
    this.tipoAlvo = 'Reps',
    this.imagemUrl,
    this.personalId,
    this.instrucoes,
    required this.series,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'grupoMuscular': grupoMuscular,
      'imagemUrl': imagemUrl,
      'tipoAlvo': tipoAlvo,
      'personalId': personalId,
      'instrucoes': instrucoes,
    };
  }

  factory ExercicioItem.fromFirestore(Map<String, dynamic> data, [String? docId]) {
    // Lógica de migração: se grupoMuscular for String, converte para List<String>
    List<String> grupos = ['Geral'];
    final rawGrupo = data['grupoMuscular'];
    
    if (rawGrupo is String) {
      grupos = rawGrupo.split(',').map((e) => e.trim()).toList();
    } else if (rawGrupo is List) {
      grupos = List<String>.from(rawGrupo);
    }

    return ExercicioItem(
      id: docId,
      nome: data['nome'] ?? '',
      grupoMuscular: grupos,
      imagemUrl: data['imagemUrl'],
      tipoAlvo: data['tipoAlvo'] ?? 'Reps',
      personalId: data['personalId'],
      instrucoes: data['instrucoes'],
      series: [],
    );
  }

  ExercicioItem clone() {
    return ExercicioItem(
      id: id,
      nome: nome,
      grupoMuscular: List<String>.from(grupoMuscular),
      tipoAlvo: tipoAlvo,
      imagemUrl: imagemUrl,
      personalId: personalId,
      instrucoes: instrucoes,
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