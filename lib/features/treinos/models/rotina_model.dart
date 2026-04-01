import 'package:cloud_firestore/cloud_firestore.dart';
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

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'diaSemana': diaSemana ?? '',
      'orientacoes': orientacoes ?? '',
      'exercicios': exercicios.map((ex) {
        return {
          'nome': ex.nome,
          'grupoMuscular': ex.grupoMuscular,
          'tipoAlvo': ex.tipoAlvo,
          'series': ex.series.map((s) {
            return {
              'tipo': s.tipo.name,
              'alvo': s.alvo,
              'carga': s.carga,
              'descanso': s.descanso,
            };
          }).toList(),
        };
      }).toList(),
    };
  }

  factory SessaoTreinoModel.fromFirestore(Map<String, dynamic> data) {
    List<ExercicioItem> exerciciosList = [];
    for (var ex in (data['exercicios'] ?? [])) {
      List<SerieItem> seriesList = [];
      for (var s in (ex['series'] ?? [])) {
        seriesList.add(
          SerieItem(
            tipo: _parseTipoSerie(s['tipo']),
            alvo: s['alvo'] ?? '10',
            carga: s['carga'] ?? '',
            descanso: s['descanso'] ?? '60s',
          ),
        );
      }

      List<String> grupos = ['Geral'];
      final rawGrupo = ex['grupoMuscular'];
      if (rawGrupo is String) {
        grupos = rawGrupo.split(',').map((e) => e.trim()).toList();
      } else if (rawGrupo is List) {
        grupos = List<String>.from(rawGrupo);
      }

      exerciciosList.add(
        ExercicioItem(
          nome: ex['nome'] ?? 'Exercício',
          grupoMuscular: grupos,
          tipoAlvo: ex['tipoAlvo'] ?? 'Reps',
          series: seriesList,
        ),
      );
    }
    return SessaoTreinoModel(
      nome: data['nome'] ?? '',
      diaSemana: data['diaSemana'],
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

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'objetivo': objetivo,
      'tipoVencimento': tipoVencimento,
      'vencimentoSessoes': vencimentoSessoes,
      'dataVencimento': dataVencimento != null ? Timestamp.fromDate(dataVencimento!) : null,
      'sessoes': sessoes.map((s) => s.toFirestore()).toList(),
    };
  }

  factory RotinaModel.fromFirestore(Map<String, dynamic> data, [String? docId]) {
    List<SessaoTreinoModel> sessoesList = [];
    if (data['sessoes'] != null) {
      sessoesList = (data['sessoes'] as List)
          .map((s) => SessaoTreinoModel.fromFirestore(s as Map<String, dynamic>))
          .toList();
    }

    DateTime? dataVenc;
    if (data['dataVencimento'] != null) {
      dataVenc = (data['dataVencimento'] as Timestamp).toDate();
    }

    return RotinaModel(
      id: docId,
      nome: data['nome'] ?? '',
      objetivo: data['objetivo'] ?? '',
      tipoVencimento: data['tipoVencimento'] ?? 'data',
      vencimentoSessoes: data['vencimentoSessoes'],
      dataVencimento: dataVenc,
      sessoes: sessoesList,
    );
  }
}
