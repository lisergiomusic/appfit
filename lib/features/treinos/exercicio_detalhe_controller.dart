import 'models/exercicio_model.dart';

class ExercicioDetalheController {
  final ExercicioItem exercicio;

  ExercicioDetalheController(this.exercicio);

  List<MapEntry<int, SerieItem>> entriesForTipo(TipoSerie tipo) {
    final list = <MapEntry<int, SerieItem>>[];
    for (var i = 0; i < exercicio.series.length; i++) {
      final s = exercicio.series[i];
      if (s.tipo == tipo) {
        list.add(MapEntry(i, s));
      }
    }
    return list;
  }

  int computeInsertRealIndex(TipoSerie tipo) {
    int insertRealIndex = exercicio.series.lastIndexWhere(
      (s) => s.tipo == tipo,
    );
    if (insertRealIndex == -1) {
      return exercicio.series.length;
    }
    return insertRealIndex + 1;
  }

  int sectionIndexOf(SerieItem serie) {
    return exercicio.series
        .where((s) => s.tipo == serie.tipo)
        .toList()
        .indexOf(serie);
  }

  int indexOf(SerieItem serie) => exercicio.series.indexOf(serie);

  SerieItem removeAt(int index) => exercicio.series.removeAt(index);

  void insertAt(int index, SerieItem serie) =>
      exercicio.series.insert(index, serie);
}
