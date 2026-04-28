import 'dart:async';
import 'package:flutter/material.dart';

import '../../shared/models/exercicio_model.dart';

class ExercicioWrapper {
  final String id;
  final ExercicioItem item;

  ExercicioWrapper(this.item) : id = UniqueKey().toString();
}

class ConfigurarTreinoController extends ChangeNotifier {

  late final String initialNomeTreino;
  late final String _initialSessaoNote;
  late final List<String> _initialExercicioIds;

  late List<ExercicioWrapper> _exercicios;
  List<ExercicioWrapper> get exercicios => _exercicios;

  bool get hasChanges {
    final nomeChanged = nomeTreinoController.text.trim() != initialNomeTreino;
    final noteChanged = _sessaoNote != _initialSessaoNote;
    
    // Compara estrutura da lista (Instâncias e Ordem)
    final currentIds = _exercicios.map((e) => e.id).toList();
    bool listChanged = currentIds.length != _initialExercicioIds.length;
    if (!listChanged) {
      for (int i = 0; i < currentIds.length; i++) {
        if (currentIds[i] != _initialExercicioIds[i]) {
          listChanged = true;
          break;
        }
      }
    }

    return nomeChanged || noteChanged || listChanged;
  }

  final TextEditingController nomeTreinoController;

  bool _isEditingTitle = false;
  bool get isEditingTitle => _isEditingTitle;

  final FocusNode titleFocusNode = FocusNode();

  final Set<String> _newExercicios = {};
  Set<String> get newExercicios => _newExercicios;

  Timer? _snackBarTimer;
  ExercicioWrapper? _lastRemovedItem;
  int? _lastRemovedIndex;

  String _sessaoNote = '';
  String get sessaoNote => _sessaoNote;


  ConfigurarTreinoController({
    required String nomeTreino,
    required List<ExercicioItem> exercicios,
    String sessaoNote = '',
  }) : nomeTreinoController = TextEditingController(text: nomeTreino) {
    initialNomeTreino = nomeTreino;
    _initialSessaoNote = sessaoNote;
    _sessaoNote = sessaoNote;
    _exercicios = exercicios.map((ex) => ExercicioWrapper(ex.clone())).toList();
    _initialExercicioIds = _exercicios.map((e) => e.id).toList();

    nomeTreinoController.addListener(_onNomeTreinoChanged);
    titleFocusNode.addListener(_onFocusChanged);
  }

  void updateSessaoNote(String newNote) {
    if (_sessaoNote != newNote) {
      _sessaoNote = newNote;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nomeTreinoController.removeListener(_onNomeTreinoChanged);
    titleFocusNode.removeListener(_onFocusChanged);
    nomeTreinoController.dispose();
    titleFocusNode.dispose();
    _snackBarTimer?.cancel();
    super.dispose();
  }

  void _onNomeTreinoChanged() {
    notifyListeners();
  }

  void _onFocusChanged() {
    if (!titleFocusNode.hasFocus && _isEditingTitle) {
      toggleEditTitle();
    }
  }


  static const int _kSecondsPerRep = 4;
  static const int _kTransitionSeconds = 120;

  int get totalSeries =>
      _exercicios.fold(0, (sum, wrapper) => sum + wrapper.item.series.length);

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
    return int.tryParse(v) ?? 0;
  }

  Duration get estimatedDuration {
    int totalSeconds = 0;
    for (final wrapper in _exercicios) {
      final ex = wrapper.item;
      totalSeconds += _kTransitionSeconds;
      for (final serie in ex.series) {
        final execTime = ex.tipoAlvo == 'Tempo'
            ? _parseDurationString(serie.alvo)
            : (int.tryParse(serie.alvo) ?? 0) * _kSecondsPerRep;
        final restTime = _parseDurationString(serie.descanso);
        totalSeconds += execTime + restTime;
      }
    }
    return Duration(seconds: totalSeconds);
  }

  String get estimatedDurationLabel {
    final d = estimatedDuration;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  void toggleEditTitle() {
    _isEditingTitle = !_isEditingTitle;
    if (_isEditingTitle) {
      titleFocusNode.requestFocus();
    } else {
      titleFocusNode.unfocus();
    }
    notifyListeners();
  }

  void onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _exercicios.removeAt(oldIndex);
    _exercicios.insert(newIndex, item);
    notifyListeners();
  }

  void addExercicios(List<ExercicioItem> listaExercicios) {
    for (var ex in listaExercicios) {
      final newWrapper = ExercicioWrapper(ex.clone());
      _exercicios.add(newWrapper);
      _newExercicios.add(newWrapper.id);
    }
    notifyListeners();
  }

  void onExercicioChanged() {
    notifyListeners();
  }

  void markHintAsShown(String id) {
    _newExercicios.remove(id);
  }

  void deleteExercicio(int index) {
    _lastRemovedItem = _exercicios[index];
    _lastRemovedIndex = index;
    _exercicios.removeAt(index);
    notifyListeners();
  }

  void undoDelete() {
    if (_lastRemovedItem != null && _lastRemovedIndex != null) {
      _exercicios.insert(_lastRemovedIndex!, _lastRemovedItem!);
      _lastRemovedItem = null;
      _lastRemovedIndex = null;
      notifyListeners();
    }
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

  List<ExercicioItem> getFinalExercicios() {
    return _exercicios.map((e) => e.item).toList();
  }
}