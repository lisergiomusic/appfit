import 'exercicio_model.dart';

class SessaoTreinoModel {
  String nome;
  String? diaSemana;
  String? orientacoes;
  List<ExercicioItem> exercicios;

  SessaoTreinoModel({
    required this.nome,
    this.diaSemana,
    this.orientacoes,
    List<ExercicioItem>? exercicios,
  }) : exercicios = exercicios ?? [];

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'dia_semana': diaSemana ?? '',
      'orientacoes': orientacoes ?? '',
      'exercicios': exercicios.map((ex) => ex.toMap()).toList(),
    };
  }

  factory SessaoTreinoModel.fromMap(Map<String, dynamic> data) {
    List<ExercicioItem> exerciciosList = [];
    for (var ex in (data['exercicios'] ?? [])) {
      List<SerieItem> seriesList = [];
      for (var s in (ex['series'] ?? [])) {
        seriesList.add(
          SerieItem(
            id: s['id']?.toString(),
            tipo: _parseTipoSerie(s['tipo']),
            alvo: s['alvo'] ?? '10',
            carga: s['carga'] ?? '',
            descanso: s['descanso'] ?? '60s',
          ),
        );
      }

      final rawGrupo = ex['grupo_muscular'] ?? ex['grupoMuscular'];
      if (rawGrupo is String) {
      } else if (rawGrupo is List) {
      }

      exerciciosList.add(
        ExercicioItem.fromMap(ex),
      );
    }
    return SessaoTreinoModel(
      nome: data['nome'] ?? '',
      diaSemana: data['dia_semana'] ?? data['diaSemana'],
      orientacoes: data['orientacoes'],
      exercicios: exerciciosList,
    );
  }

  String calcularTempoEstimado() {
    int totalSegundos = 0;
    const int kSecondsPerRep = 4;
    const int kTransitionSeconds = 120;

    for (final exercicio in exercicios) {
      // Tempo de transição entre exercícios
      totalSegundos += kTransitionSeconds;

      for (final serie in exercicio.series) {
        // Tempo de execução (Reps * 4s ou Tempo direto)
        final execTime = exercicio.tipoAlvo == 'Tempo'
            ? _parseDurationString(serie.alvo)
            : (int.tryParse(serie.alvo) ?? 0) * kSecondsPerRep;

        // Tempo de descanso
        final restTime = _parseDurationString(serie.descanso);

        totalSegundos += execTime + restTime;
      }
    }

    final d = Duration(seconds: totalSegundos);
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  static int _parseDurationString(String value) {
    final v = value.trim().toLowerCase();
    final mMatch = RegExp(r'^(\d+)m$').firstMatch(v);
    if (mMatch != null) return int.parse(mMatch.group(1)!) * 60;
    final sMatch = RegExp(r'^(\d+)s$').firstMatch(v);
    if (sMatch != null) return int.parse(sMatch.group(1)!);
    final msMatch = RegExp(r'^(\d+)m(\d+)s$').firstMatch(v);
    if (msMatch != null) {
      return int.parse(msMatch.group(1)!) * 60 + int.parse(msMatch.group(2)!);
    }
    final plainNumber = RegExp(r'^(\d+)$').firstMatch(v);
    if (plainNumber != null) return int.parse(plainNumber.group(1)!);
    return 0;
  }

  static TipoSerie _parseTipoSerie(String? tipo) {
    if (tipo == 'aquecimento' || tipo == 'TipoSerie.aquecimento') {
      return TipoSerie.aquecimento;
    }
    return TipoSerie.trabalho;
  }
}

class RotinaModel {
  final String? id;
  final String nome;
  final String objetivo;
  final String tipoVencimento;
  final int? vencimentoSessoes;
  final DateTime? dataVencimento;
  final List<SessaoTreinoModel> sessoes;

  RotinaModel({
    this.id,
    required this.nome,
    required this.objetivo,
    required this.tipoVencimento,
    this.vencimentoSessoes,
    this.dataVencimento,
    required this.sessoes,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'objetivo': objetivo,
      'tipo_vencimento': tipoVencimento,
      'vencimento_sessoes': vencimentoSessoes,
      'data_vencimento': dataVencimento?.toIso8601String(),
      'sessoes': sessoes.map((s) => s.toMap()).toList(),
    };
  }

  factory RotinaModel.fromMap(
    Map<String, dynamic> data, [
    String? docId,
  ]) {
    List<SessaoTreinoModel> sessoesList = [];
    if (data['sessoes'] != null) {
      sessoesList = (data['sessoes'] as List)
          .map(
            (s) => SessaoTreinoModel.fromMap(s as Map<String, dynamic>),
          )
          .toList();
    }

    DateTime? dataVenc;
    final dataVencRaw = data['data_vencimento'] ?? data['dataVencimento'];
    if (dataVencRaw != null) {
      dataVenc = DateTime.tryParse(dataVencRaw.toString());
    }

    return RotinaModel(
      id: docId,
      nome: data['nome'] ?? '',
      objetivo: data['objetivo'] ?? '',
      tipoVencimento: data['tipo_vencimento'] ?? data['tipoVencimento'] ?? 'data',
      vencimentoSessoes: data['vencimento_sessoes'] ?? data['vencimentoSessoes'],
      dataVencimento: dataVenc,
      sessoes: sessoesList,
    );
  }
}