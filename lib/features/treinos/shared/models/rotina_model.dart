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

      List<String> grupos = ['Geral'];
      final rawGrupo = ex['grupo_muscular'] ?? ex['grupoMuscular'];
      if (rawGrupo is String) {
        grupos = rawGrupo.split(',').map((e) => e.trim()).toList();
      } else if (rawGrupo is List) {
        grupos = List<String>.from(rawGrupo);
      }

      exerciciosList.add(
        ExercicioItem(
          nome: ex['nome'] ?? 'Exercício',
          grupoMuscular: grupos,
          imagemUrl: ex['imagem_url'] ?? ex['imagemUrl'],
          mediaUrl: ex['media_url'] ?? ex['mediaUrl'],
          tipoAlvo: ex['tipo_alvo'] ?? ex['tipoAlvo'] ?? 'Reps',
          personalId: ex['personal_id'] ?? ex['personalId'],
          instrucoes: ex['instrucoes'],
          instrucoesPersonalizadas: ex['instrucoes_personalizadas'] ?? ex['instrucoesPersonalizadas'],
          series: seriesList,
        ),
      );
    }
    return SessaoTreinoModel(
      nome: data['nome'] ?? '',
      diaSemana: data['dia_semana'] ?? data['diaSemana'],
      orientacoes: data['orientacoes'],
      exercicios: exerciciosList,
    );
  }

  static TipoSerie _parseTipoSerie(String? tipo) {
    if (tipo == 'aquecimento' || tipo == 'TipoSerie.aquecimento') {
      return TipoSerie.aquecimento;
    }
    if (tipo == 'feeder' || tipo == 'TipoSerie.feeder') return TipoSerie.feeder;
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