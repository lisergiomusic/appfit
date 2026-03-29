import 'dart:async';
import 'package:flutter/material.dart';
import 'models/exercicio_model.dart';

class ExercicioDetalheController {
  final ExercicioItem exercicio;
  final Set<String> _newSeriesIds = {};

  SerieItem? _lastRemovedItem;
  int? _lastRemovedIndex;
  Timer? _snackBarTimer;

  final Set<TipoSerie> _editingSections = {};
  bool isSectionEditing(TipoSerie tipo) => _editingSections.contains(tipo);

  bool get isEditing => _editingSections.isNotEmpty;

  ExercicioDetalheController(this.exercicio);

  Set<String> get newSeriesIds => _newSeriesIds;

  void toggleEditing(TipoSerie tipo) {
    if (_editingSections.contains(tipo)) {
      _editingSections.remove(tipo);
    } else {
      _editingSections.add(tipo);
    }
  }

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
    }
  }

  void duplicateSerie(SerieItem serie) {
    final index = exercicio.series.indexOf(serie);
    if (index != -1) {
      final newSerie = serie.clone(sameId: false);
      exercicio.series.insert(index + 1, newSerie);
      markAsNew(newSerie.id);
    }
  }

  int? undoDelete() {
    if (_lastRemovedItem != null && _lastRemovedIndex != null) {
      final index = _lastRemovedIndex!;
      exercicio.series.insert(index, _lastRemovedItem!);
      _lastRemovedItem = null;
      _lastRemovedIndex = null;
      return index;
    }
    return null;
  }

  void clearUndoState() {
    _lastRemovedItem = null;
    _lastRemovedIndex = null;
  }

  void startSnackBarTimer(VoidCallback onTimeout) {
    _snackBarTimer?.cancel();
    _snackBarTimer = Timer(const Duration(seconds: 4), onTimeout);
  }

  void cancelSnackBarTimer() {
    _snackBarTimer?.cancel();
  }

  SerieItem removeAt(int index) => exercicio.series.removeAt(index);

  void insertAt(int index, SerieItem serie) =>
      exercicio.series.insert(index, serie);
      
  void dispose() {
    _snackBarTimer?.cancel();
  }
}
