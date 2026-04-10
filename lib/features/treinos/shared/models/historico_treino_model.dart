import 'package:appfit/features/treinos/shared/models/exercicio_model.dart';

class SerieHistorico {
  final TipoSerie tipo;
  final int indexDentroDoTipo;
  final String? pesoRealizado;
  final String? repsRealizadas;

  SerieHistorico({
    required this.tipo,
    required this.indexDentroDoTipo,
    this.pesoRealizado,
    this.repsRealizadas,
  });

  @override
  String toString() =>
      'SerieHistorico(tipo: $tipo, index: $indexDentroDoTipo, peso: $pesoRealizado, reps: $repsRealizadas)';
}
