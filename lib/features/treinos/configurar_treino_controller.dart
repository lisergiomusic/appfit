import 'dart:async';
import 'package:flutter/material.dart';

import 'models/exercicio_model.dart';

/// Wrapper para o [ExercicioItem] que garante uma [id] única e estável.
class ExercicioWrapper {
  final String id;
  final ExercicioItem item;

  ExercicioWrapper(this.item) : id = UniqueKey().toString();
}

class ConfigurarTreinoController extends ChangeNotifier {
  // =================================================================================
  // INÍCIO: ESTADO
  // =================================================================================

  late String initialNomeTreino;

  late List<ExercicioWrapper> _exercicios;
  List<ExercicioWrapper> get exercicios => _exercicios;

  bool _hasChanges = false;
  bool get hasChanges => _hasChanges;

  final TextEditingController nomeTreinoController;

  bool _isEditingTitle = false;
  bool get isEditingTitle => _isEditingTitle;

  final FocusNode titleFocusNode = FocusNode();

  final Set<String> _newExercicios = {};
  Set<String> get newExercicios => _newExercicios;

  Timer? _snackBarTimer;
  ExercicioWrapper? _lastRemovedItem;
  int? _lastRemovedIndex;

  // =================================================================================
  // FIM: ESTADO
  // =================================================================================

  ConfigurarTreinoController({
    required String nomeTreino,
    required List<ExercicioItem> exercicios,
  }) : nomeTreinoController = TextEditingController(text: nomeTreino) {
    initialNomeTreino = nomeTreino;
    _exercicios = exercicios.map((ex) => ExercicioWrapper(ex.clone())).toList();

    nomeTreinoController.addListener(_onNomeTreinoChanged);
    titleFocusNode.addListener(_onFocusChanged);
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
    if (nomeTreinoController.text.trim() != initialNomeTreino) {
      if (!_hasChanges) {
        _hasChanges = true;
        notifyListeners();
      }
    }
  }

  void _onFocusChanged() {
    if (!titleFocusNode.hasFocus && _isEditingTitle) {
      toggleEditTitle();
    }
  }

  // =================================================================================
  // INÍCIO: LÓGICA DE NEGÓCIO
  // =================================================================================

  int get totalSeries =>
      _exercicios.fold(0, (sum, wrapper) => sum + wrapper.item.series.length);

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
    _hasChanges = true;
    notifyListeners();
  }

  void addExercicios(List<ExercicioItem> listaExercicios) {
    for (var ex in listaExercicios) {
      // O .clone() é vital para que, se você adicionar dois supinos, eles sejam independentes
      final newWrapper = ExercicioWrapper(ex.clone());
      _exercicios.add(newWrapper);
      _newExercicios.add(newWrapper.id);
    }
    _hasChanges = true;
    notifyListeners();
  }

  void onExercicioChanged() {
    _hasChanges = true;
    notifyListeners();
  }

  void markHintAsShown(String id) {
    _newExercicios.remove(id);
    // Não precisa notificar, pois a animação cuida da UI.
  }

  void deleteExercicio(int index) {
    _lastRemovedItem = _exercicios[index];
    _lastRemovedIndex = index;
    _exercicios.removeAt(index);
    _hasChanges = true;
    notifyListeners();
  }

  void undoDelete() {
    if (_lastRemovedItem != null && _lastRemovedIndex != null) {
      _exercicios.insert(_lastRemovedIndex!, _lastRemovedItem!);
      _lastRemovedItem = null;
      _lastRemovedIndex = null;
      // Idealmente, verificaríamos se a lista voltou ao estado original
      // para setar _hasChanges = false. Por simplicidade, deixamos true.
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
