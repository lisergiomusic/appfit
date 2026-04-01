import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter/cupertino.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'dart:ui';
import 'package:appfit/core/widgets/appfit_sliver_app_bar.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/orange_glass_action_button.dart';
import '../../core/widgets/app_bar_text_button.dart';
import '../../core/widgets/sliver_safe_title.dart';
import 'models/exercicio_model.dart';
import 'exercicio_detalhe_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

class _EditableFieldWidget extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLength;
  final String? suffixText;
  final String? hintText;
  final TextInputType keyboardType;

  const _EditableFieldWidget({
    required this.controller,
    required this.onChanged,
    this.inputFormatters,
    this.maxLength = 8,
    this.suffixText,
    this.hintText,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_EditableFieldWidget> createState() => _EditableFieldWidgetState();
}

class _EditableFieldWidgetState extends State<_EditableFieldWidget> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  InputDecoration _buildDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 7,
      ),
      hintText: _focusNode.hasFocus ? null : widget.hintText,
      hintStyle: TextStyle(
        color: Colors.white.withAlpha(40),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      suffixText: widget.suffixText,
      suffixStyle: const TextStyle(
        color: AppColors.labelSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Colors.white.withAlpha(14), width: 1),
      ),
      filled: true,
      fillColor: AppColors.surfaceLight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: _focusNode,
      controller: widget.controller,
      onChanged: widget.onChanged,
      inputFormatters: [
        LengthLimitingTextInputFormatter(widget.maxLength),
        ...?widget.inputFormatters,
      ],
      textAlign: TextAlign.center,
      keyboardType: widget.keyboardType,
      style: AppTheme.bodyText.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: _buildDecoration(),
    );
  }
}

class _ExercicioDetalhePageState extends State<ExercicioDetalhePage>
    with TickerProviderStateMixin {
  late final ExercicioItem ex;
  late final ExercicioDetalheController controller;
  final Map<TipoSerie, GlobalKey<AnimatedListState>> _animatedListKeys = {
    TipoSerie.aquecimento: GlobalKey<AnimatedListState>(),
    TipoSerie.feeder: GlobalKey<AnimatedListState>(),
    TipoSerie.trabalho: GlobalKey<AnimatedListState>(),
  };
  final ScrollController _scrollController = ScrollController();
  final Map<int, AnimationController> _swipeHintControllers = {};
  final Map<int, AnimationController> _rippleControllers = {};
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _lastValues = {};
  final Map<String, bool> _hasUserEdited = {};
  final Set<String> _suppressNextOnChanged = {};
  final Map<int, AnimationController> _flashControllers = {};

  @override
  void initState() {
    super.initState();
    ex = widget.exercicio;
    controller = ExercicioDetalheController(ex);
  }

  @override
  void dispose() {
    _disposeControllers();
    _disposeCardAnimationControllers();
    _disposeFlashControllers();
    controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _disposeFlashControllers() {
    for (final ctrl in _flashControllers.values) {
      ctrl.dispose();
    }
    _flashControllers.clear();
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
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
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

  void _playFlashAnimation(int serieHash) {
    _flashControllers[serieHash]?.dispose();
    final flashController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flashControllers[serieHash] = flashController;
    flashController.forward().then((_) {
      if (mounted) {
        flashController.dispose();
        _flashControllers.remove(serieHash);
      }
    });
  }

  void _handleFieldChanged({
    required String fieldKey,
    required TextEditingController controller,
    required String value,
    required String emptyFallback,
    required void Function(String) onSave,
    required int serieHash,
  }) {
    if (_suppressNextOnChanged.contains(fieldKey)) {
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
    _playFlashAnimation(serieHash);
  }

  String _formatCargaInputValue(String value) {
    if (value.trim() == '-') return '-';
    return value.replaceAll(RegExp(r'kg$', caseSensitive: false), '').trim();
  }

  String _formatDescansoInputValue(String value) {
    return value.replaceAll(RegExp(r's$', caseSensitive: false), '').trim();
  }

  void _onDeleteSerie(SerieItem serie) {
    final sectionIndex = controller.sectionIndexOf(serie);
    controller.deleteSerie(serie);
    setState(() {
      _clearEditingState();
    });

    _animatedListKeys[serie.tipo]?.currentState?.removeItem(
      sectionIndex,
      (context, animation) =>
          SizeTransition(sizeFactor: animation, child: Container()),
    );

    controller.cancelSnackBarTimer();
    _scaffoldMessengerKey.currentState?.removeCurrentSnackBar();

    final snackBar = SnackBar(
      content: const Text('Série removida'),
      action: SnackBarAction(
        label: 'DESFAZER',
        textColor: AppColors.primary,
        onPressed: () {
          controller.cancelSnackBarTimer();
          _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
          final restoredIndex = controller.undoDelete();
          if (restoredIndex != null) {
            final restoredSerie = ex.series[restoredIndex];
            final restoredSectionIndex = controller.sectionIndexOf(
              restoredSerie,
            );
            setState(() {});
            _animatedListKeys[restoredSerie.tipo]?.currentState?.insertItem(
              restoredSectionIndex,
              duration: const Duration(milliseconds: 300),
            );
          }
        },
      ),
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    );

    final snackBarController = _scaffoldMessengerKey.currentState?.showSnackBar(
      snackBar,
    );

    if (snackBarController != null) {
      controller.startSnackBarTimer(() {
        snackBarController.close();
        controller.clearUndoState();
      });
    }

    widget.onChanged();
  }

  Future<void> _adicionarSerie() async {
    final TipoSerie? tipoEscolhido = await showModalBottomSheet<TipoSerie>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    width: 36,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.textLabel.withAlpha(50),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),

                  const Text(
                    'Tipo de Série',
                    style: TextStyle(
                      color: AppColors.labelPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    ),
                    child: Column(
                      children: [
                        _buildModalOption(
                          title: 'Aquecimento',
                          icon: Icons.whatshot_rounded,
                          color: const Color(0xFF00B4D8),
                          onTap: () =>
                              Navigator.pop(context, TipoSerie.aquecimento),
                          showDivider: true,
                          subtitle:
                              'Prepara as articulações e o sistema nervoso.',
                        ),
                        _buildModalOption(
                          title: 'Aproximação',
                          icon: Icons.speed_rounded,
                          color: const Color(0xFFFFB703),
                          onTap: () => Navigator.pop(context, TipoSerie.feeder),
                          showDivider: true,
                          subtitle: 'Sobe a carga progressivamente sem fadiga.',
                        ),
                        _buildModalOption(
                          title: 'Série de Trabalho',
                          icon: Icons.fitness_center_rounded,
                          color: const Color(0xFFFF3366),
                          onTap: () =>
                              Navigator.pop(context, TipoSerie.trabalho),
                          showDivider: false,
                          subtitle: 'Série efetiva para hipertrofia ou força.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (tipoEscolhido != null) {
      String alvoToClone = '', cargaToClone = '-', descansoToClone = '';
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
      controller.markAsNew(newSerie.id);

      final sectionList = controller.entriesForTipo(tipoEscolhido);
      final insertSectionIndex = sectionList.length;
      final insertRealIndex = controller.computeInsertRealIndex(tipoEscolhido);

      setState(() {
        controller.insertAt(insertRealIndex, newSerie);
      });

      Future.microtask(() {
        _animatedListKeys[tipoEscolhido]?.currentState?.insertItem(
          insertSectionIndex,
          duration: const Duration(milliseconds: 300),
        );
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.labelPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppColors.labelTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textLabel.withAlpha(40),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 0),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.white.withAlpha(15),
            ),
          ),
      ],
    );
  }

  Color _colorForTipo(TipoSerie tipo) {
    switch (tipo) {
      case TipoSerie.aquecimento:
        return const Color(0xFF00B4D8);
      case TipoSerie.feeder:
        return const Color(0xFFFFB703);
      case TipoSerie.trabalho:
        return const Color(0xFFFF3366);
    }
  }

  // --- WIDGET DE LINHA DA SÉRIE ---
  Widget _buildSerieRow(
    SerieItem serie,
    int realIndex,
    int visualNumber,
    bool isFirst,
    bool isLast,
  ) {
    final isNew = controller.newSeriesIds.contains(serie.id);
    final radius = Radius.circular(AppTheme.radiusXL);
    final borderRadius = BorderRadius.only(
      topLeft: isFirst ? radius : Radius.zero,
      topRight: isFirst ? radius : Radius.zero,
      bottomLeft: isLast ? radius : Radius.zero,
      bottomRight: isLast ? radius : Radius.zero,
    );

    Widget rowContent(Color? flashColor) {
      return _buildSerieRowContent(
        serie,
        realIndex,
        visualNumber,
        isFirst,
        isLast,
        flashColor: flashColor,
      );
    }

    Widget card;
    if (isNew) {
      card = _HintingSerieAnimator(
        onEnd: () {
          if (mounted) {
            setState(() {
              controller.markHintAsShown(serie.id);
            });
          }
        },
        builder: (context, color) => rowContent(color),
      );
    } else {
      card = rowContent(null);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Dismissible(
        key: ValueKey(serie.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _onDeleteSerie(serie),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, AppColors.systemRed.withAlpha(220)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delete_rounded, color: Colors.white, size: 20),
              const SizedBox(height: 3),
              const Text(
                'Remover',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        child: card,
      ),
    );
  }

  Widget _buildSerieRowContent(
    SerieItem serie,
    int realIndex,
    int visualNumber,
    bool isFirst,
    bool isLast, {
    Color? flashColor,
  }) {
    final stableId = serie.id;
    final repsController = _getController('reps_$stableId', serie.alvo);
    final cargaController = _getController(
      'carga_$stableId',
      _formatCargaInputValue(serie.carga),
    );
    final descansoController = _getController(
      'descanso_$stableId',
      _formatDescansoInputValue(serie.descanso),
    );
    final isEditingSection = controller.isSectionEditing(serie.tipo);

    final accentColor = _colorForTipo(serie.tipo);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation:
              _flashControllers[serie.hashCode] ??
              const AlwaysStoppedAnimation(0.0),
          builder: (context, child) {
            final editFlashCtrl = _flashControllers[serie.hashCode];
            final editFlashColor = editFlashCtrl != null
                ? ColorTween(
                    begin: accentColor.withAlpha(40),
                    end: Colors.transparent,
                  ).animate(editFlashCtrl).value
                : Colors.transparent;

            return Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: 6,
              ),
              color: flashColor ?? editFlashColor,
              child: Row(
                children: [
                  // Botão de Deletar (Animado)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    width: isEditingSection ? 28 : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isEditingSection ? 1.0 : 0.0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () => _onDeleteSerie(serie),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    width: isEditingSection ? 8 : 0,
                  ),
                  // Badge do número da série
                  Expanded(
                    flex: 2,
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      padding: EdgeInsets.only(left: isEditingSection ? 2 : 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(22),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSM,
                            ),
                          ),
                          child: Text(
                            '$visualNumber',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _buildEditableField(
                      repsController,
                      (val) => _handleFieldChanged(
                        fieldKey: 'reps_$realIndex',
                        controller: repsController,
                        value: val,
                        emptyFallback: '0',
                        onSave: (s) => serie.alvo = s,
                        serieHash: serie.hashCode,
                      ),
                      hintText: 'Ex: 8 a 12',
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    flex: 3,
                    child: _buildEditableField(
                      cargaController,
                      (val) => _handleFieldChanged(
                        fieldKey: 'carga_$realIndex',
                        controller: cargaController,
                        value: val,
                        emptyFallback: '-',
                        onSave: (s) => serie.carga = s,
                        serieHash: serie.hashCode,
                      ),
                      maxLength: 5,
                      suffixText: 'kg',
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    flex: 3,
                    child: _buildEditableField(
                      descansoController,
                      (val) => _handleFieldChanged(
                        fieldKey: 'descanso_$realIndex',
                        controller: descansoController,
                        value: val,
                        emptyFallback: '',
                        onSave: (s) => serie.descanso = s,
                        serieHash: serie.hashCode,
                      ),
                      maxLength: 8,
                      suffixText: 's',
                      hintText: 'Ex: 60s',
                      keyboardType: TextInputType.text,
                    ),
                  ),

                  // Botão de Duplicar (Animado)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    width: isEditingSection ? 8 : 0,
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    width: isEditingSection ? 26 : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isEditingSection ? 1.0 : 0.0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.copy_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        onPressed: () {
                          final sectionIndex = controller.sectionIndexOf(serie);
                          controller.duplicateSerie(serie);
                          setState(() {});
                          _animatedListKeys[serie.tipo]?.currentState
                              ?.insertItem(
                                sectionIndex + 1,
                                duration: const Duration(milliseconds: 300),
                              );
                          widget.onChanged();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.white.withAlpha(10),
            ),
          ),
      ],
    );
  }

  Widget _buildEditableField(
    TextEditingController ctrl,
    ValueChanged<String> onChanged, {
    List<TextInputFormatter>? inputFormatters,
    int maxLength = 8,
    String? suffixText,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return _EditableFieldWidget(
      controller: ctrl,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      suffixText: suffixText,
      hintText: hintText,
      keyboardType: keyboardType,
    );
  }

  // --- WIDGET DA SEÇÃO DE SÉRIES (O CARD AGRUPADO) ---
  Widget _buildSeriesSection({
    required String title,
    required List<MapEntry<int, SerieItem>> entries,
    Color? titleColor,
    bool showDot = false,
  }) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final tipo = entries.first.value.tipo;
    final isEditingSection = controller.isSectionEditing(tipo);

    final accentColor = titleColor ?? AppColors.labelTertiary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(title, style: AppTheme.sectionHeader),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () {
                    setState(() {
                      controller.toggleEditing(tipo);
                    });
                  },
                  child: Icon(
                    isEditingSection ? Icons.check : Icons.more_vert,
                    color: AppColors.labelSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.labelToField),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(color: Colors.white.withAlpha(8), width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              child: Column(
                children: [
                  // Faixa de acento colorida no topo
                  Container(height: 3, color: accentColor.withAlpha(160)),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      left: 16,
                      right: 16,
                      bottom: 4,
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          width: isEditingSection ? 36 : 0,
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedPadding(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOutCubic,
                              padding: EdgeInsets.only(
                                left: isEditingSection ? 0 : 4,
                              ),
                              child: Text(
                                'SÉRIE',
                                style: AppTheme.microLabelTextStyle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Text(
                              'REPS',
                              style: AppTheme.microLabelTextStyle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Text(
                              'PESO',
                              style: AppTheme.microLabelTextStyle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Text(
                              'PAUSA',
                              style: AppTheme.microLabelTextStyle,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          width: isEditingSection ? 34 : 0,
                        ),
                      ],
                    ),
                  ),
                  AnimatedList(
                    key: _animatedListKeys[entries.first.value.tipo],
                    initialItemCount: entries.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index, animation) {
                      final mapped = entries[index];
                      return SizeTransition(
                        sizeFactor: animation,
                        child: _buildSerieRow(
                          mapped.value,
                          mapped.key,
                          index + 1,
                          index == 0,
                          index == entries.length - 1,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsField() {
    final isEmpty = ex.instrucoes?.trim().isEmpty ?? true;

    if (isEmpty) {
      return GestureDetector(
        onTap: _showEditInstructionsSheet,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.doc_text, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Adicionar instruções',
                style: AppTheme.bodyText.copyWith(
                  color: AppColors.primary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Instruções', style: AppTheme.sectionHeader),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showEditInstructionsSheet,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                  inset: true,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Icon(
                    CupertinoIcons.doc_text,
                    size: 16,
                    color: AppColors.labelTertiary,
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Text(
                    ex.instrucoes ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyText.copyWith(
                      color: AppColors.labelSecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Icon(
                    CupertinoIcons.pencil,
                    size: 16,
                    color: AppColors.labelTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEditInstructionsSheet() {
    final ctrl = TextEditingController(text: ex.instrucoes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background.withAlpha(235),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(100),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header do Modal
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.white.withAlpha(120),
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const Text(
                        'Instruções',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            ex.instrucoes = ctrl.text.trim();
                          });
                          widget.onChanged();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Colors.white.withAlpha(20),
                ),
                // Campo de Texto
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: ctrl,
                        maxLines: 8,
                        maxLength: 500,
                        autofocus: true,
                        cursorColor: AppColors.primary,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Ex: "Focar na cadência do movimento e manter o abdômen contraído em todos os exercícios."',
                          hintStyle: TextStyle(
                            color: Colors.white.withAlpha(40),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: ctrl,
                        builder: (context, value, child) {
                          final remaining = 500 - value.text.length;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '$remaining caracteres disponíveis',
                                style: TextStyle(
                                  color: remaining < 50
                                      ? Colors.redAccent.withAlpha(200)
                                      : Colors.white.withAlpha(60),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exerciseTitle = SliverSafeTitle.safeTitle(
      ex.nome,
      fallback: 'Exercício',
    );
    final warmup = ex.series
        .asMap()
        .entries
        .where((e) => e.value.tipo == TipoSerie.aquecimento)
        .toList();
    final feeder = ex.series
        .asMap()
        .entries
        .where((e) => e.value.tipo == TipoSerie.feeder)
        .toList();
    final work = ex.series
        .asMap()
        .entries
        .where((e) => e.value.tipo == TipoSerie.trabalho)
        .toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                AppFitSliverAppBar(
                  title: exerciseTitle,
                  actions: [
                    AppBarTextButton(
                      label: 'Salvar',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                  background: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exerciseTitle, style: AppTheme.bigTitle),
                          const SizedBox(height: SpacingTokens.xs),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children:
                                (ex.grupoMuscular.isEmpty
                                        ? ['Geral']
                                        : ex.grupoMuscular)
                                    .map(
                                      (g) => Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: SpacingTokens.md, // 12
                                          vertical: SpacingTokens.xs, // 4
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceLight,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          g,
                                          style: AppTheme.caption2,
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: SpacingTokens.screenHorizontalPadding,
                      right: SpacingTokens.screenHorizontalPadding,
                      top: 4,
                      bottom: SpacingTokens.screenBottomPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail do Vídeo
                        _ExerciseVideoCard(
                          imageUrl: ex.imagemUrl,
                          exerciseTitle: exerciseTitle,
                          onTap: () {},
                        ),
                        const SizedBox(height: SpacingTokens.sectionGap),
                        // Campo de Instruções
                        _buildInstructionsField(),
                        const SizedBox(height: SpacingTokens.sectionGap),
                        if (ex.series.isEmpty)
                          Column(
                            children: [
                              const SizedBox(height: 48),
                              const Icon(
                                Icons.fitness_center_rounded,
                                size: 50,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Prescreva o exercício',
                                style: TextStyle(
                                  color: AppColors.labelPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 32),
                              OrangeGlassActionButton(
                                label: 'Adicionar Série',
                                onTap: _adicionarSerie,
                                bottomMargin: 0,
                                showGlow: false,
                              ),
                            ],
                          )
                        else ...[
                          _buildSeriesSection(
                            title: 'Aquecimento',
                            entries: warmup,
                            titleColor: const Color(0xFF00B4D8),
                            showDot: true,
                          ),
                          _buildSeriesSection(
                            title: 'Séries de aproximação',
                            entries: feeder,
                            titleColor: const Color(0xFFFFB703),
                            showDot: true,
                          ),
                          _buildSeriesSection(
                            title: 'Séries de trabalho',
                            entries: work,
                            titleColor: const Color(0xFFFF3366),
                            showDot: true,
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: OrangeGlassActionButton(
                              label: 'Adicionar Série',
                              onTap: _adicionarSerie,
                              bottomMargin: 0,
                              showGlow: false,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- WIDGET DO CARD DE VÍDEO (Thumbnail) ---
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(10), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              Positioned.fill(
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.surfaceDark,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.surfaceDark,
                          child: const Icon(
                            Icons.videocam_off,
                            color: Colors.white38,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceDark,
                        child: const Icon(
                          Icons.videocam_off,
                          color: Colors.white38,
                        ),
                      ),
              ),
              if (imageUrl != null && imageUrl!.isNotEmpty)
                Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(64),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.play_fill,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


class _HintingSerieAnimator extends StatefulWidget {
  final Widget Function(BuildContext context, Color? color) builder;
  final VoidCallback onEnd;

  const _HintingSerieAnimator({required this.builder, required this.onEnd});

  @override
  _HintingSerieAnimatorState createState() => _HintingSerieAnimatorState();
}

class _HintingSerieAnimatorState extends State<_HintingSerieAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    final highlightColor = AppColors.primary.withAlpha(30);
    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.transparent, end: highlightColor),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: highlightColor, end: Colors.transparent),
        weight: 50.0,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _controller.forward().whenComplete(() {
          if (mounted) {
            widget.onEnd();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return widget.builder(context, _colorAnimation.value);
      },
    );
  }
}
