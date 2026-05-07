import 'dart:async';
import 'package:flutter/material.dart';
import '../../shared/models/exercicio_model.dart';

class ExercicioDetalheController extends ChangeNotifier {
  final ExercicioItem exercicio;
  late final ExercicioItem _initialSnapshot;
  List<SerieItem>? _lastReplacedSeries;
  final Set<String> _newSeriesIds = {};

  SerieItem? _lastRemovedItem;
  int? _lastRemovedIndex;
  List<SerieItem>? _lastClearedSeries;
  TipoSerie? _lastClearedTipo;
  Timer? _snackBarTimer;

  ExercicioDetalheController(this.exercicio) {
    _initialSnapshot = exercicio.clone();
  }

  bool get hasChanges {
    // 1. Check instructions
    if (exercicio.instrucoesPersonalizadas != _initialSnapshot.instrucoesPersonalizadas) {
      return true;
    }

    // 2. Check series count
    if (exercicio.series.length != _initialSnapshot.series.length) {
      return true;
    }

    // 3. Deep check each series
    for (int i = 0; i < exercicio.series.length; i++) {
      if (exercicio.series[i] != _initialSnapshot.series[i]) {
        return true;
      }
    }

    return false;
  }

  Set<String> get newSeriesIds => _newSeriesIds;

  void markAsNew(String id) {
    _newSeriesIds.add(id);
  }

  void markHintAsShown(String id) {
    _newSeriesIds.remove(id);
  }

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

  void deleteSerie(SerieItem serie) {
    _lastRemovedIndex = exercicio.series.indexOf(serie);
    if (_lastRemovedIndex != -1) {
      _lastRemovedItem = exercicio.series.removeAt(_lastRemovedIndex!);
      notifyListeners();
    }
  }

  void duplicateSerie(SerieItem serie) {
    final index = exercicio.series.indexOf(serie);
    if (index != -1) {
      final newSerie = serie.clone(sameId: false);
      exercicio.series.insert(index + 1, newSerie);
      markAsNew(newSerie.id);
      notifyListeners();
    }
  }

  int? undoDelete() {
    if (_lastRemovedItem != null && _lastRemovedIndex != null) {
      final index = _lastRemovedIndex!;
      exercicio.series.insert(index, _lastRemovedItem!);
      _lastRemovedItem = null;
      _lastRemovedIndex = null;
      notifyListeners();
      return index;
    }
    return null;
  }

  void startSnackBarTimer(VoidCallback onTimeout) {
    _snackBarTimer?.cancel();
    _snackBarTimer = Timer(const Duration(seconds: 4), onTimeout);
  }

  void cancelSnackBarTimer() {
    _snackBarTimer?.cancel();
  }

  SerieItem removeAt(int index) => exercicio.series.removeAt(index);

  void insertAt(int index, SerieItem serie) {
    exercicio.series.insert(index, serie);
    notifyListeners();
  }

  void onManualNotify() {
    notifyListeners();
  }

  void replaceAllSeries(List<SerieItem> newSeries) {
    _lastReplacedSeries = List<SerieItem>.from(exercicio.series);
    exercicio.series.clear();
    exercicio.series.addAll(newSeries);
    for (var s in newSeries) {
      markAsNew(s.id);
    }
    notifyListeners();
  }

  void undoReplace() {
    if (_lastReplacedSeries != null) {
      exercicio.series.clear();
      exercicio.series.addAll(_lastReplacedSeries!);
      _lastReplacedSeries = null;
      notifyListeners();
    }
  }

  void appendSeries(List<SerieItem> newSeries) {
    exercicio.series.addAll(newSeries);
    for (var s in newSeries) {
      markAsNew(s.id);
    }
    notifyListeners();
  }

  /// Pega a primeira série de um tipo e aplica seus valores (reps, carga, descanso) em todas as outras do mesmo tipo.
  void equalizeSeries(TipoSerie tipo, {bool reps = false, bool carga = false, bool descanso = false}) {
    final list = exercicio.series.where((s) => s.tipo == tipo).toList();
    if (list.length < 2) return;

    final first = list.first;
    for (int i = 1; i < list.length; i++) {
      if (reps) list[i].alvo = first.alvo;
      if (carga) list[i].carga = first.carga;
      if (descanso) list[i].descanso = first.descanso;
    }
    notifyListeners();
  }

  void clearAllSeries(TipoSerie tipo) {
    _lastClearedTipo = tipo;
    _lastClearedSeries = exercicio.series.where((s) => s.tipo == tipo).toList();
    exercicio.series.removeWhere((s) => s.tipo == tipo);
    notifyListeners();
  }

  void undoClearAll() {
    if (_lastClearedSeries != null && _lastClearedTipo != null) {
      exercicio.series.addAll(_lastClearedSeries!);
      // Re-ordena as séries para manter Aquecimento -> Trabalho
      final order = {TipoSerie.aquecimento: 0, TipoSerie.trabalho: 1};
      exercicio.series.sort((a, b) => order[a.tipo]!.compareTo(order[b.tipo]!));
      
      _lastClearedSeries = null;
      _lastClearedTipo = null;
      notifyListeners();
    }
  }

  void clearUndoState() {
    _lastRemovedItem = null;
    _lastRemovedIndex = null;
    _lastClearedSeries = null;
    _lastClearedTipo = null;
  }

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    super.dispose();
  }
}