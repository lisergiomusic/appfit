import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/orange_glass_action_button.dart';
import '../../core/widgets/sliver_safe_title.dart';
import 'models/exercicio_model.dart';
import 'exercicio_detalhe_controller.dart';

class ExercicioDetalhePage extends StatefulWidget {
  final ExercicioItem exercicio;
  final VoidCallback onChanged;

  const ExercicioDetalhePage({
    super.key,
    required this.exercicio,
    required this.onChanged,
  });

  @override
  State<ExercicioDetalhePage> createState() => _ExercicioDetalhePageState();
}

class _ExercicioDetalhePageState extends State<ExercicioDetalhePage>
    with TickerProviderStateMixin {
  late ExercicioItem ex;
  late ExercicioDetalheController controller;
  final Map<TipoSerie, GlobalKey<AnimatedListState>> _animatedListKeys = {
    TipoSerie.aquecimento: GlobalKey<AnimatedListState>(),
    TipoSerie.feeder: GlobalKey<AnimatedListState>(),
    TipoSerie.trabalho: GlobalKey<AnimatedListState>(),
  };
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _rowKeys = {};
  final Map<int, AnimationController> _swipeHintControllers = {};
  final Map<int, AnimationController> _rippleControllers = {};
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _activeSnackBar;
  Timer? _undoSnackTimer;
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _instructionsController = TextEditingController();
  final FocusNode _instructionsFocusNode = FocusNode();
  static const int _instructionsMaxChars = 250;
  final Map<String, String> _lastValues = {};
  final Map<String, bool> _hasUserEdited = {};
  final Set<String> _suppressNextOnChanged = {};
  final Set<String> _hapticTriggeredDismissKeys = {};
  bool _isEditingInstructions = false;

  @override
  void initState() {
    super.initState();
    ex = widget.exercicio;
    controller = ExercicioDetalheController(ex);
    _instructionsController.text = ex.observacao;
    _instructionsController.addListener(_onInstructionsChanged);
    _instructionsFocusNode.addListener(_onInstructionsFocusChange);
  }

  Widget _buildEditableSerieField({
    required String fieldKey,
    required TextEditingController controller,
    required String semanticsLabel,
    required String semanticsHint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    required VoidCallback onTap,
    required ValueChanged<String> onChanged,
    required ValueChanged<String> onFieldSubmitted,
    required void Function(dynamic) onTapOutside,
    required InputDecoration decoration,
    TextAlign textAlign = TextAlign.center,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        label: semanticsLabel,
        hint: semanticsHint,
        textField: true,
        child: TextFormField(
          keyboardType: keyboardType,
          inputFormatters: inputFormatters ?? const [],
          controller: controller,
          onTap: onTap,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          onTapOutside: onTapOutside,
          textAlign: textAlign,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: AppTheme.primary,
          decoration: decoration,
        ),
      ),
    );
  }

  void _onInstructionsFocusChange() {
    setState(() {
      _isEditingInstructions = _instructionsFocusNode.hasFocus;
    });
  }

  void _onInstructionsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _disposeControllers();
    _disposeCardAnimationControllers();
    _instructionsFocusNode.removeListener(_onInstructionsFocusChange);
    _instructionsController.removeListener(_onInstructionsChanged);
    _instructionsFocusNode.dispose();
    _instructionsController.dispose();
    _undoSnackTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _disposeCardAnimationControllers() {
    for (final ctrl in _swipeHintControllers.values) {
      ctrl.dispose();
    }
    _swipeHintControllers.clear();
    for (final ctrl in _rippleControllers.values) {
      ctrl.dispose();
    }
    _rippleControllers.clear();
  }

  void _disposeControllers() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  void _clearEditingState() {
    _disposeControllers();
    _lastValues.clear();
    _hasUserEdited.clear();
    _suppressNextOnChanged.clear();
  }

  TextEditingController _getController(String fieldKey, String initialValue) {
    if (!_controllers.containsKey(fieldKey)) {
      _controllers[fieldKey] = TextEditingController(text: initialValue);
    }
    return _controllers[fieldKey]!;
  }

  void _setControllerText(
    String fieldKey,
    TextEditingController controller,
    String value,
  ) {
    _suppressNextOnChanged.add(fieldKey);
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _startEditingField(String fieldKey, TextEditingController controller) {
    _lastValues[fieldKey] = controller.text;
    _hasUserEdited[fieldKey] = false;
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  void _restorePreviousIfNoChange({
    required String fieldKey,
    required TextEditingController controller,
    required void Function(String) onRestore,
    void Function(String)? onCommitEdited,
  }) {
    final hasEdited = _hasUserEdited[fieldKey] ?? false;
    if (!hasEdited) {
      final previousValue = _lastValues[fieldKey] ?? controller.text;
      _setControllerText(fieldKey, controller, previousValue);
      onRestore(previousValue);
      widget.onChanged();
    } else if (onCommitEdited != null) {
      final committed = controller.text.isEmpty ? '' : controller.text;
      onCommitEdited(committed);
      widget.onChanged();
    }
    _lastValues.remove(fieldKey);
    _hasUserEdited.remove(fieldKey);
  }

  void _handleFieldChanged({
    required String fieldKey,
    required TextEditingController controller,
    required String value,
    required String emptyFallback,
    required void Function(String) onSave,
  }) {
    if (_suppressNextOnChanged.contains(fieldKey)) {
      // Ignora apenas a limpeza programática; se já houver entrada do usuário,
      // processa normalmente para não perder a primeira digitação.
      if (value.isEmpty) {
        _suppressNextOnChanged.remove(fieldKey);
        return;
      }
      _suppressNextOnChanged.remove(fieldKey);
    }

    _hasUserEdited[fieldKey] = true;
    final nextValue = value.isEmpty ? emptyFallback : value;
    if (nextValue != value) {
      _setControllerText(fieldKey, controller, nextValue);
    }
    onSave(nextValue);
    widget.onChanged();
  }

  String _extractDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _formatCargaInputValue(String value) {
    if (value.trim() == '-') {
      return '-';
    }

    final digits = _extractDigits(value);
    if (digits.isEmpty) {
      return '';
    }
    return '${digits}kg';
  }

  String _formatDescansoInputValue(String value) {
    final digits = _extractDigits(value);
    if (digits.isEmpty) {
      return '';
    }
    return '${digits}s';
  }

  // Sequência: slide left → hold (mínima) → slide back (suave)
  static final _swipeHintTween = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: -72.0,
      ).chain(CurveTween(curve: Curves.easeInOutCubicEmphasized)),
      weight: 32,
    ),
    TweenSequenceItem(
      tween: ConstantTween<double>(-72.0),
      weight: 1,
    ), // pausa mínima
    TweenSequenceItem(
      tween: Tween(
        begin: -72.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeInOutCubicEmphasized)),
      weight: 67,
    ),
  ]);

  // Quanto do fundo vermelho fica visível (espelha o swipe)
  static final _swipeHintBgTween = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 72.0,
      ).chain(CurveTween(curve: Curves.easeInOutCubicEmphasized)),
      weight: 32,
    ),
    TweenSequenceItem(tween: ConstantTween<double>(72.0), weight: 1),
    TweenSequenceItem(
      tween: Tween(
        begin: 72.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeInOutCubicEmphasized)),
      weight: 67,
    ),
  ]);

  void _startSwipeHintAndRipple(int serieHash) {
    _swipeHintControllers[serieHash]?.dispose();
    _rippleControllers[serieHash]?.dispose();

    final swipeCtrl =
        AnimationController(
          duration: const Duration(milliseconds: 1800),
          vsync: this,
        )..addListener(() {
          if (mounted) setState(() {});
        });

    final rippleCtrl =
        AnimationController(
          duration: const Duration(milliseconds: 150),
          vsync: this,
        )..addListener(() {
          if (mounted) setState(() {});
        });

    setState(() {
      _swipeHintControllers[serieHash] = swipeCtrl;
      _rippleControllers[serieHash] = rippleCtrl;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      swipeCtrl.forward().then((_) {
        if (!mounted) return;
        swipeCtrl.dispose();
        if (mounted) setState(() => _swipeHintControllers.remove(serieHash));
        // M3 state layer: fade in rápido → fade out lento
        rippleCtrl
            .animateTo(
              1.0,
              duration: const Duration(milliseconds: 130),
              curve: Curves.easeOut,
            )
            .then((_) {
              if (!mounted) return;
              rippleCtrl
                  .animateTo(
                    0.0,
                    duration: const Duration(milliseconds: 480),
                    curve: Curves.easeIn,
                  )
                  .then((_) {
                    if (!mounted) return;
                    rippleCtrl.dispose();
                    if (mounted) {
                      setState(() => _rippleControllers.remove(serieHash));
                    }
                  });
            });
      });
    });
  }

  Future<void> _adicionarSerie() async {
    final TipoSerie? tipoEscolhido = await showModalBottomSheet<TipoSerie>(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const Text(
                  'Adicionar Nova Série',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildModalOption(
                        title: 'Série de Aquecimento',
                        icon: Icons.whatshot,
                        color: Colors.amber,
                        onTap: () =>
                            Navigator.pop(context, TipoSerie.aquecimento),
                        showDivider: true,
                        subtitle: 'Prepara articulações e ativa músculos.',
                      ),
                      _buildModalOption(
                        title: 'Feeder Set',
                        icon: Icons.flash_on,
                        color: Colors.blueAccent,
                        onTap: () => Navigator.pop(context, TipoSerie.feeder),
                        showDivider: true,
                        subtitle: 'Aproximação progressiva sem fadiga.',
                      ),
                      _buildModalOption(
                        title: 'Série de Trabalho',
                        icon: Icons.tag,
                        color: Colors.white,
                        onTap: () => Navigator.pop(context, TipoSerie.trabalho),
                        showDivider: false,
                        subtitle: 'Série efetiva próxima à falha muscular.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );

    if (tipoEscolhido != null) {
      String alvoToClone = '10';
      String cargaToClone = '-';
      String descansoToClone = '60s';

      if (ex.series.isNotEmpty) {
        final ultimaSerie = ex.series.lastWhere(
          (s) => s.tipo == tipoEscolhido,
          orElse: () => ex.series.last,
        );
        alvoToClone = ultimaSerie.alvo;
        cargaToClone = ultimaSerie.carga;
        descansoToClone = ultimaSerie.descanso;
      }

      final newSerie = SerieItem(
        tipo: tipoEscolhido,
        alvo: alvoToClone,
        carga: cargaToClone,
        descanso: descansoToClone,
      );

      // Determine section insert index (append to that section)
      final sectionList = controller.entriesForTipo(tipoEscolhido);
      final insertSectionIndex = sectionList.length;

      // Determine real index to insert into master list: after last of same tipo or at end
      final insertRealIndex = controller.computeInsertRealIndex(tipoEscolhido);

      setState(() {
        controller.insertAt(insertRealIndex, newSerie);
      });

      // Animate insertion in section
      Future.microtask(() {
        _animatedListKeys[tipoEscolhido]?.currentState?.insertItem(
          insertSectionIndex,
          duration: const Duration(milliseconds: 300),
        );
      });

      // Visual feedback: scroll to new item and highlight briefly
      final int newHash = newSerie.hashCode;
      // Aguarda a animação de inserção terminar (300ms) antes de iniciar scroll e glow
      Future.delayed(const Duration(milliseconds: 350), () async {
        final key = _rowKeys[newHash];
        if (key != null && key.currentContext != null) {
          await Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 300),
            alignment: 0.12,
            curve: Curves.easeOutCubic,
          );
        } else {
          // Fallback: small scroll to bottom
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }

        // Swipe hint → M3 state layer highlight
        _startSwipeHintAndRipple(newHash);
      });

      widget.onChanged();
    }
  }

  Widget _buildModalOption({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool showDivider,
    required String subtitle,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space16,
              vertical: AppTheme.space16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppTheme.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.textSecondary.withAlpha(160),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.black45,
            indent: 0,
          ),
      ],
    );
  }

  TextStyle _microLabelStyle() {
    return TextStyle(
      color: AppTheme.silverGrey,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    );
  }

  TextStyle _sectionEyebrowStyle() {
    return TextStyle(
      color: AppTheme.textSecondary,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
    );
  }

  InputDecoration _editableFieldDecoration({
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
      horizontal: AppTheme.space12,
      vertical: 8,
    ),
  }) {
    return InputDecoration(
      isDense: true,
      contentPadding: contentPadding,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppTheme.accentMetrics, width: 1.1),
      ),
    );
  }

  Widget _buildSerieRow(
    SerieItem serie,
    int realIndex,
    int visualNumber,
    bool showDivider,
  ) {
    final repsFieldKey = 'reps_$realIndex';
    final cargaFieldKey = 'carga_$realIndex';
    final descansoFieldKey = 'descanso_$realIndex';
    // Use stable keys per serie instance (hashCode) to keep controllers
    final stableId = serie.hashCode;
    final repsFieldStableKey = 'reps_$stableId';
    final cargaFieldStableKey = 'carga_$stableId';
    final descansoFieldStableKey = 'descanso_$stableId';

    final repsController = _getController(repsFieldStableKey, serie.alvo);
    final cargaController = _getController(
      cargaFieldStableKey,
      _formatCargaInputValue(serie.carga),
    );
    final descansoController = _getController(
      descansoFieldStableKey,
      _formatDescansoInputValue(serie.descanso),
    );
    final dismissKey = '${serie.hashCode}';
    final borderRadius = BorderRadius.circular(14);

    // Inicio dos rows de séries
    final rowKey = _rowKeys.putIfAbsent(serie.hashCode, () => GlobalKey());

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space4),
      child: ClipRRect(
        key: rowKey,
        borderRadius: borderRadius,
        child: Dismissible(
          key: ValueKey(dismissKey),
          direction: DismissDirection.endToStart,
          movementDuration: const Duration(milliseconds: 300),
          resizeDuration: const Duration(milliseconds: 300),
          dismissThresholds: const {DismissDirection.endToStart: 0.45},
          confirmDismiss: (_) async {
            // Prevent concurrent deletes while undo snackbar is active.
            if (_activeSnackBar != null) {
              return false;
            }
            return true;
          },
          onUpdate: (details) {
            final reachedThreshold = details.progress >= 0.45;
            if (reachedThreshold &&
                !_hapticTriggeredDismissKeys.contains(dismissKey)) {
              _hapticTriggeredDismissKeys.add(dismissKey);
              HapticFeedback.mediumImpact();
            } else if (!reachedThreshold) {
              _hapticTriggeredDismissKeys.remove(dismissKey);
            }
          },
          onDismissed: (_) {
            _hapticTriggeredDismissKeys.remove(dismissKey);
            final realIndex = ex.series.indexOf(serie);
            if (realIndex == -1) return;
            final tipo = serie.tipo;
            final sectionIndex = controller.sectionIndexOf(serie);
            final messenger = ScaffoldMessenger.of(context);

            // Fecha snackbar anterior e timer se houver
            _undoSnackTimer?.cancel();
            if (_activeSnackBar != null) {
              try {
                _activeSnackBar!.close();
              } catch (_) {}
              _activeSnackBar = null;
            }

            // Remove do modelo imediatamente
            setState(() {
              controller.removeAt(realIndex);
              _clearEditingState();
            });

            // Anima remoção
            try {
              final listState = _animatedListKeys[tipo]?.currentState;
              if (listState != null) {
                listState.removeItem(
                  sectionIndex,
                  (context, animation) => SizeTransition(
                    sizeFactor: animation,
                    child: _buildRemovedSerieRow(
                      serie,
                      sectionIndex + 1,
                      animation,
                    ),
                  ),
                  duration: const Duration(milliseconds: 300),
                );
              }
            } catch (_) {}

            // Mostra snackbar imediatamente
            final snackController = messenger.showSnackBar(
              SnackBar(
                content: const Text(
                  'Série removida',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: AppTheme.surfaceDark,
                behavior: SnackBarBehavior.fixed,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                action: SnackBarAction(
                  label: 'Desfazer',
                  textColor: AppTheme.accentMetrics,
                  onPressed: () {
                    // ...undo logic (pode ser adaptado se necessário)...
                  },
                ),
              ),
            );
            _activeSnackBar = snackController;
            // Gerencia lifecycle do snackbar: limpa referência quando fechado e garante
            // que o timer de undo seja cancelado. Também força close após duração.
            snackController.closed.then((_) {
              if (identical(_activeSnackBar, snackController)) {
                _activeSnackBar = null;
              }
              _undoSnackTimer?.cancel();
            });
            _undoSnackTimer = Timer(const Duration(seconds: 2), () {
              try {
                snackController.close();
              } catch (_) {}
              if (identical(_activeSnackBar, snackController)) {
                _activeSnackBar = null;
              }
              widget.onChanged();
            });
          },
          background: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.space4,
              horizontal: AppTheme.space16,
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Container(color: Colors.black),
            ),
          ),
          secondaryBackground: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.space4,
              horizontal: AppTheme.space16,
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Container(
                color: Colors.redAccent,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppTheme.space20),
                    child: Semantics(
                      label: 'Remover série $visualNumber',
                      hint: 'Deslize para remover esta série',
                      button: true,
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.space4,
                  horizontal: 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _swipeHintControllers[serie.hashCode] ??
                              const AlwaysStoppedAnimation(0.0),
                          _rippleControllers[serie.hashCode] ??
                              const AlwaysStoppedAnimation(0.0),
                        ]),
                        builder: (context, child) {
                          final swipeCtrl =
                              _swipeHintControllers[serie.hashCode];
                          final rippleValue =
                              _rippleControllers[serie.hashCode]?.value ?? 0.0;
                          final dx = swipeCtrl != null
                              ? _swipeHintTween.animate(swipeCtrl).value
                              : 0.0;
                          final bgWidth = swipeCtrl != null
                              ? _swipeHintBgTween.animate(swipeCtrl).value
                              : 0.0;
                          final overlayAlpha =
                              (Curves.easeInOutCubic.transform(rippleValue) *
                                      38)
                                  .round();

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Fundo vermelho com ícone (revelado pelo slide)
                              if (bgWidth > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: bgWidth,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Container(
                                      color: Colors.redAccent,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(
                                        right: AppTheme.space16,
                                      ),
                                      child: Opacity(
                                        opacity: (bgWidth / 72.0).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              // Card com translação
                              Transform.translate(
                                offset: Offset(dx, 0),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.space12,
                                        vertical: AppTheme.space10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceDark,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: Colors.white.withAlpha(14),
                                          width: 1,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black38,
                                            blurRadius: 12,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: child,
                                    ),
                                    if (overlayAlpha > 0)
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            child: Container(
                                              color: AppTheme.accentMetrics
                                                  .withAlpha(overlayAlpha),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 18),
                                  child: Text(
                                    '$visualNumber',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: _microLabelStyle().color,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildEditableSerieField(
                                    fieldKey: repsFieldKey,
                                    controller: repsController,
                                    semanticsLabel:
                                        'Repetições série $visualNumber',
                                    semanticsHint:
                                        'Editar número de repetições',
                                    onTap: () {
                                      _startEditingField(
                                        repsFieldKey,
                                        repsController,
                                      );
                                    },
                                    onChanged: (val) {
                                      _handleFieldChanged(
                                        fieldKey: repsFieldKey,
                                        controller: repsController,
                                        value: val,
                                        emptyFallback: '0',
                                        onSave: (saved) => serie.alvo = saved,
                                      );
                                    },
                                    onFieldSubmitted: (_) {
                                      _restorePreviousIfNoChange(
                                        fieldKey: repsFieldKey,
                                        controller: repsController,
                                        onRestore: (restored) =>
                                            serie.alvo = restored,
                                      );
                                    },
                                    onTapOutside: (_) {
                                      _restorePreviousIfNoChange(
                                        fieldKey: repsFieldKey,
                                        controller: repsController,
                                        onRestore: (restored) =>
                                            serie.alvo = restored,
                                      );
                                    },
                                    decoration: _editableFieldDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: AppTheme.space8,
                                            vertical: 6,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildEditableSerieField(
                                    fieldKey: cargaFieldKey,
                                    controller: cargaController,
                                    semanticsLabel: 'Carga série $visualNumber',
                                    semanticsHint:
                                        'Editar carga em quilogramas',
                                    keyboardType: TextInputType.number,
                                    inputFormatters: const [
                                      _CargaKgInputFormatter(),
                                    ],
                                    onTap: () {
                                      _startEditingField(
                                        cargaFieldKey,
                                        cargaController,
                                      );
                                    },
                                    onChanged: (val) {
                                      _handleFieldChanged(
                                        fieldKey: cargaFieldKey,
                                        controller: cargaController,
                                        value: val,
                                        emptyFallback: '-',
                                        onSave: (saved) => serie.carga = saved,
                                      );
                                    },
                                    onFieldSubmitted: (_) {
                                      _restorePreviousIfNoChange(
                                        fieldKey: cargaFieldKey,
                                        controller: cargaController,
                                        onRestore: (restored) =>
                                            serie.carga = restored,
                                        onCommitEdited: (committed) {
                                          serie.carga = committed.isEmpty
                                              ? '-'
                                              : committed;
                                        },
                                      );
                                    },
                                    onTapOutside: (_) {
                                      _restorePreviousIfNoChange(
                                        fieldKey: cargaFieldKey,
                                        controller: cargaController,
                                        onRestore: (restored) =>
                                            serie.carga = restored,
                                        onCommitEdited: (committed) {
                                          serie.carga = committed.isEmpty
                                              ? '-'
                                              : committed;
                                        },
                                      );
                                    },
                                    decoration: _editableFieldDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: AppTheme.space8,
                                            vertical: 6,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildEditableSerieField(
                                    fieldKey: descansoFieldKey,
                                    controller: descansoController,
                                    semanticsLabel:
                                        'Descanso série $visualNumber',
                                    semanticsHint:
                                        'Editar tempo de descanso em segundos',
                                    keyboardType: TextInputType.number,
                                    inputFormatters: const [
                                      _DescansoSecondsInputFormatter(),
                                    ],
                                    onTap: () {
                                      _startEditingField(
                                        descansoFieldKey,
                                        descansoController,
                                      );
                                    },
                                    onChanged: (val) {
                                      _handleFieldChanged(
                                        fieldKey: descansoFieldKey,
                                        controller: descansoController,
                                        value: val,
                                        emptyFallback: '0',
                                        onSave: (saved) =>
                                            serie.descanso = saved,
                                      );
                                    },
                                    onFieldSubmitted: (_) {
                                      _restorePreviousIfNoChange(
                                        fieldKey: descansoFieldKey,
                                        controller: descansoController,
                                        onRestore: (restored) =>
                                            serie.descanso = restored,
                                      );
                                    },
                                    onTapOutside: (_) {
                                      _restorePreviousIfNoChange(
                                        fieldKey: descansoFieldKey,
                                        controller: descansoController,
                                        onRestore: (restored) =>
                                            serie.descanso = restored,
                                      );
                                    },
                                    decoration: _editableFieldDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: AppTheme.space8,
                                            vertical: 6,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemovedSerieRow(
    SerieItem serie,
    int visualNumber,
    Animation<double> animation,
  ) {
    return FadeTransition(
      opacity: animation,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.space4),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space12,
            vertical: AppTheme.space10,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withAlpha(14), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: Text(
                    '$visualNumber',
                    style: TextStyle(
                      color: _microLabelStyle().color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    serie.alvo,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    _formatCargaInputValue(serie.carga),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    _formatDescansoInputValue(serie.descanso),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesSection({
    IconData? icon,
    Color? iconColor,
    required String title,
    required List<MapEntry<int, SerieItem>> entries,
    Color? titleColor,
    bool showDot = false,
  }) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppTheme.space4,
              right: AppTheme.space12,
              bottom: AppTheme.space10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                showDot
                    ? Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: titleColor ?? Colors.white,
                          shape: BoxShape.circle,
                        ),
                      )
                    : (icon != null
                          ? Icon(icon, color: iconColor, size: 18)
                          : SizedBox(width: 18)),
                const SizedBox(width: AppTheme.space10),
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor ?? Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space0,
              AppTheme.space12,
              AppTheme.space0,
              AppTheme.space12,
            ),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.space4,
                    horizontal: AppTheme.space12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: AppTheme.space8,
                                  ),
                                  child: Text(
                                    'SÉRIE',
                                    style: _microLabelStyle(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Expanded(
                              flex: 3,
                              child: Center(
                                child: Text('REPS', style: _microLabelStyle()),
                              ),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Expanded(
                              flex: 3,
                              child: Center(
                                child: Text('PESO', style: _microLabelStyle()),
                              ),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Expanded(
                              flex: 3,
                              child: Center(
                                child: Text(
                                  'DESCANSO',
                                  style: _microLabelStyle(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Animated list per section for smooth insert/remove
                AnimatedList(
                  key: entries.isNotEmpty
                      ? _animatedListKeys[entries.first.value.tipo]
                      : null,
                  initialItemCount: entries.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index, animation) {
                    final mapped = entries[index];
                    final serie = mapped.value;
                    final isLast = index == entries.length - 1;
                    final realIndex = mapped.key;
                    return SizeTransition(
                      sizeFactor: animation,
                      child: _buildSerieRow(
                        serie,
                        realIndex,
                        index + 1,
                        !isLast,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveInstructions() {
    setState(() {
      ex.observacao = _instructionsController.text.trim();
    });
    widget.onChanged();
  }

  Widget _buildEmptySeriesState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustração (Ícone estilizado)
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary.withAlpha(30),
                  AppTheme.accentMetrics.withAlpha(20),
                ],
              ),
              border: Border.all(
                color: AppTheme.primary.withAlpha(50),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              size: 50,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: AppTheme.space24),
          // Texto motivacional
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
            child: Column(
              children: [
                const Text(
                  'Prescreva o exercício',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                Text(
                  'Defina as séries, repetições e cargas para criar um treino efetivo para seu aluno.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space32),
          // Botão de ação
          Center(
            child: OrangeGlassActionButton(
              label: 'Adicionar Série',
              onTap: _adicionarSerie,
              bottomMargin: 0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exerciseTitle = SliverSafeTitle.safeTitle(
      ex.nome,
      fallback: 'Exercício',
    );
    final warmupEntries = ex.series
        .asMap()
        .entries
        .where((e) => e.value.tipo == TipoSerie.aquecimento)
        .toList();
    final feederEntries = ex.series
        .asMap()
        .entries
        .where((e) => e.value.tipo == TipoSerie.feeder)
        .toList();
    final workEntries = ex.series
        .asMap()
        .entries
        .where((e) => e.value.tipo == TipoSerie.trabalho)
        .toList();
    final muscleGroupsText = ex.grupoMuscular.trim().isEmpty
        ? 'EXERCÍCIO'
        : ex.grupoMuscular
              .toUpperCase()
              .replaceAll(RegExp(r'\s*,\s*'), ' • ')
              .replaceAll(RegExp(r'\s+/\s+'), ' • ');

    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        extendBody: false,
        body: SafeArea(
          bottom: true,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                automaticallyImplyLeading: false,
                backgroundColor: AppTheme.background,
                surfaceTintColor: Colors.transparent,
                pinned: true,
                expandedHeight: 138,
                leadingWidth: 60,
                leading: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Material(
                      color: AppTheme.buttonSurface,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            CupertinoIcons.back,
                            color: AppTheme.textPrimary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  Semantics(
                    label: 'Concluir',
                    button: true,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.accentMetrics,
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text(
                        'Concluir',
                        style: TextStyle(
                          color: AppTheme.accentMetrics,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double collapsedHeight =
                        MediaQuery.of(context).padding.top + kToolbarHeight;
                    final bool isCollapsed =
                        constraints.biggest.height <= collapsedHeight + 20;

                    return FlexibleSpaceBar(
                      centerTitle: true,
                      titlePadding: const EdgeInsets.only(bottom: 18),
                      title: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          // Fade + slight upward slide
                          final offsetAnimation =
                              Tween<Offset>(
                                begin: const Offset(0, 0.08),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              );
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            ),
                          );
                        },
                        child: isCollapsed
                            ? SliverSafeTitle(
                                key: const ValueKey('collapsed_title'),
                                title: exerciseTitle,
                                isVisible: true,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : const SizedBox(
                                key: ValueKey('empty_title'),
                                height: 0,
                              ),
                      ),
                      background: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: AppTheme.space16,
                            right: AppTheme.space16,
                            bottom: 10,
                          ),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isCollapsed ? 0.0 : 1.0,
                            child: Text(
                              exerciseTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space16,
                    AppTheme.space4,
                    AppTheme.space16,
                    AppTheme.space48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(muscleGroupsText, style: _sectionEyebrowStyle()),
                      const SizedBox(height: AppTheme.space16),
                      _ExerciseVideoCard(
                        imageUrl: ex.imagemUrl,
                        exerciseTitle: exerciseTitle,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Assistindo vídeo de $exerciseTitle',
                              ),
                              backgroundColor: AppTheme.primary,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppTheme.space24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('INSTRUÇÕES', style: _sectionEyebrowStyle()),
                              if (_isEditingInstructions)
                                TextButton(
                                  onPressed: () {
                                    _instructionsFocusNode.unfocus();
                                    _saveInstructions();
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.accentMetrics,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.space0,
                                      vertical: AppTheme.space6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Concluir',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: AppTheme.space4),
                                      Icon(
                                        Icons.check,
                                        size: 14,
                                        color: AppTheme.accentMetrics,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space10),
                          Semantics(
                            label: 'Instruções do exercício',
                            textField: true,
                            hint: 'Toque para adicionar instruções de execução',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _instructionsController,
                                  focusNode: _instructionsFocusNode,
                                  minLines: 3,
                                  maxLines: 8,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  onTapOutside: (_) {
                                    FocusScope.of(context).unfocus();
                                    _saveInstructions();
                                  },
                                  onSubmitted: (_) => _saveInstructions(),
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    height: 1.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: _isEditingInstructions
                                        ? null
                                        : 'Toque para adicionar instruções de execução...',
                                    hintStyle: TextStyle(
                                      color: AppTheme.textSecondary.withAlpha(
                                        120,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.surfaceDark,
                                    contentPadding: const EdgeInsets.all(
                                      AppTheme.space16,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.white.withAlpha(28),
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.white.withAlpha(28),
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: AppTheme.accentMetrics,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_isEditingInstructions)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 6,
                                      right: 6,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '${_instructionsController.text.length}/$_instructionsMaxChars',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary
                                              .withValues(alpha: 0.62),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space24),
                      // Condicional: mostrar estado vazio ou séries
                      if (ex.series.isEmpty)
                        _buildEmptySeriesState()
                      else ...[
                        _buildSeriesSection(
                          icon: null,
                          iconColor: null,
                          title: 'AQUECIMENTO',
                          entries: warmupEntries,
                          titleColor: AppTheme.iosBlue,
                          showDot: true,
                        ),
                        if (feederEntries.isNotEmpty) ...[
                          _buildSeriesSection(
                            icon: null,
                            iconColor: null,
                            title: 'FEEDER',
                            entries: feederEntries,
                            titleColor: AppTheme.accentMetrics,
                            showDot: true,
                          ),
                        ],
                        if (workEntries.isNotEmpty) ...[
                          _buildSeriesSection(
                            icon: null,
                            iconColor: null,
                            title: 'SÉRIES DE TRABALHO',
                            entries: workEntries,
                            titleColor: AppTheme.primary,
                            showDot: true,
                          ),
                        ],
                        const SizedBox(height: AppTheme.space12),
                        Center(
                          child: OrangeGlassActionButton(
                            label: 'Adicionar Série',
                            onTap: _adicionarSerie,
                            bottomMargin: 0,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverPadding(padding: EdgeInsets.only(bottom: AppTheme.space16)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseVideoCard extends StatelessWidget {
  final String? imageUrl;
  final String exerciseTitle;
  final VoidCallback onTap;

  const _ExerciseVideoCard({
    required this.imageUrl,
    required this.exerciseTitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Assistir vídeo de $exerciseTitle',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(28), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      imageUrl ??
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuAXzEmkEB7BMnRUWQ6iIDF5Oc_gVzBjCjxHaac9LYJyL8KxdAi-mTOKK2v2nO9Vt3-DXPcDcoSM3RkTh-iDX0q8oShyD0TllFVTVsQBP3fKU0HPHHtOlkO5uRRx_yIiMes1tmlEr6VkkMyvhy-LTIzYuWYuJaLsSzeba5FPnNX9_RQjcusWmbIyWrBVLVSmLZjDaMcPJMKiSSY6S-RSZFaAzRzHQdDbWnPbv1aUP1akkwSiPE9Rriwmdn8VrF3w0ZIWei1Cxfd7B2Ut',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppTheme.surfaceDark,
                        child: Center(
                          child: Icon(
                            Icons.videocam_off,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(64),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha(38),
                          width: 0.9,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CargaKgInputFormatter extends TextInputFormatter {
  const _CargaKgInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = '${digits}kg';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: digits.length),
      composing: TextRange.empty,
    );
  }
}

class _DescansoSecondsInputFormatter extends TextInputFormatter {
  const _DescansoSecondsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = '${digits}s';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: digits.length),
      composing: TextRange.empty,
    );
  }
}
