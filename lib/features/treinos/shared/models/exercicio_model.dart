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
    this.carga = '',
    this.descanso = '60s',
  }) : id = id ?? _generateId();

  static String _generateId() {
    return '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  SerieItem clone({bool sameId = true}) {
    return SerieItem(
      id: sameId ? id : null,
      tipo: tipo,
      alvo: alvo,
      carga: carga,
      descanso: descanso,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SerieItem &&
          runtimeType == other.runtimeType &&
          tipo == other.tipo &&
          alvo == other.alvo &&
          carga == other.carga &&
          descanso == other.descanso;

  @override
  int get hashCode =>
      tipo.hashCode ^ alvo.hashCode ^ carga.hashCode ^ descanso.hashCode;
}

class ExercicioItem {
  String? id;
  String nome;
  List<String> grupoMuscular;
  String tipoAlvo;
  String? imagemUrl;
  String? mediaUrl;
  String? personalId;
  String? instrucoes;
  String? instrucoesPersonalizadas;
  List<SerieItem> series;

  ExercicioItem({
    this.id,
    required this.nome,
    this.grupoMuscular = const ['Geral'],
    this.tipoAlvo = 'Reps',
    this.imagemUrl,
    this.mediaUrl,
    this.personalId,
    this.instrucoes,
    this.instrucoesPersonalizadas,
    required this.series,
  });

  String? get instrucoesPadraoTexto => _normalizeOptionalText(instrucoes);
  String? get instrucoesPersonalizadasTexto =>
      _normalizeOptionalText(instrucoesPersonalizadas);
  bool get hasInstrucoesPadrao => instrucoesPadraoTexto != null;
  bool get hasInstrucoesPersonalizadas => instrucoesPersonalizadasTexto != null;
  String? get instrucoesParaExibicao =>
      instrucoesPersonalizadasTexto;

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'grupoMuscular': grupoMuscular,
      'imagemUrl': imagemUrl,
      'mediaUrl': mediaUrl,
      'tipoAlvo': tipoAlvo,
      'personalId': personalId,
      'instrucoes': instrucoes,
      'instrucoesPersonalizadas': instrucoesPersonalizadas,
    };
  }

  factory ExercicioItem.fromFirestore(
    Map<String, dynamic> data, [
    String? docId,
  ]) {
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
      mediaUrl: data['mediaUrl'],
      tipoAlvo: data['tipoAlvo'] ?? 'Reps',
      personalId: data['personalId'],
      instrucoes: data['instrucoes'],
      instrucoesPersonalizadas: data['instrucoesPersonalizadas'],
      series: [],
    );
  }

  /// Novo: Factory para criar o objeto a partir do Supabase (SQL)
  factory ExercicioItem.fromSupabase(Map<String, dynamic> data) {
    // No SQL, o array vem como List<dynamic> ou List<String>
    final rawGrupo = data['grupo_muscular'];
    List<String> grupos = ['Geral'];
    
    if (rawGrupo is List) {
      grupos = List<String>.from(rawGrupo);
    }

    return ExercicioItem(
      id: data['id'].toString(), // UUID do Supabase
      nome: data['nome'] ?? '',
      grupoMuscular: grupos,
      imagemUrl: data['imagem_url'],
      mediaUrl: data['media_url'],
      tipoAlvo: data['tipo_alvo'] ?? 'Reps',
      personalId: data['personal_id']?.toString(),
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
      mediaUrl: mediaUrl,
      personalId: personalId,
      instrucoes: instrucoes,
      instrucoesPersonalizadas: instrucoesPersonalizadas,
      series: series.map((s) => s.clone()).toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExercicioItem &&
          runtimeType == other.runtimeType &&
          nome == other.nome &&
          tipoAlvo == other.tipoAlvo &&
          _listEquals(grupoMuscular, other.grupoMuscular) &&
          _listEquals(series, other.series);

  @override
  int get hashCode =>
      nome.hashCode ^
      tipoAlvo.hashCode ^
      grupoMuscular.length.hashCode ^
      series.length.hashCode;

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String? _normalizeOptionalText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}