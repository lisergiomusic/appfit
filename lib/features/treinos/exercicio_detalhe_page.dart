import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter/cupertino.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'dart:ui';
import 'package:appfit/core/widgets/appfit_sliver_app_bar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/orange_glass_action_button.dart';
import '../../core/widgets/app_bar_text_button.dart';
import '../../core/widgets/sliver_safe_title.dart';
import 'models/exercicio_model.dart';
import 'exercicio_detalhe_controller.dart';
import 'widgets/exercicio_detalhe/exercicio_constants.dart';
import 'widgets/exercicio_detalhe/exercise_video_card.dart';
import 'widgets/exercicio_detalhe/serie_row.dart';
import 'widgets/exercicio_detalhe/series_section.dart';

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
  late final ExercicioItem ex;
  late final ExercicioDetalheController controller;

  final Map<TipoSerie, GlobalKey<AnimatedListState>> _animatedListKeys = {
    TipoSerie.aquecimento: GlobalKey<AnimatedListState>(),
    TipoSerie.feeder: GlobalKey<AnimatedListState>(),
    TipoSerie.trabalho: GlobalKey<AnimatedListState>(),
  };

  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _suppressNextOnChanged = {};

  @override
  void initState() {
    super.initState();
    ex = widget.exercicio;
    controller = ExercicioDetalheController(ex);
  }

  @override
  void dispose() {
    _disposeControllers();
    controller.dispose();
    super.dispose();
  }

  void _disposeControllers() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    _controllers.clear();
  }

  void _clearEditingState() {
    _disposeControllers();
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

  void _handleFieldChanged({
    required String fieldKey,
    required TextEditingController controller,
    required String value,
    required String emptyFallback,
    required void Function(String) onSave,
  }) {
    if (_suppressNextOnChanged.contains(fieldKey)) {
      _suppressNextOnChanged.remove(fieldKey);
      if (value.isEmpty) return;
    }

    final nextValue = value.isEmpty ? emptyFallback : value;
    if (nextValue != value) {
      _setControllerText(fieldKey, controller, nextValue);
    }
    onSave(nextValue);
    widget.onChanged();
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
          SizeTransition(sizeFactor: animation, child: const SizedBox.shrink()),
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
              duration: ExercicioDetalheConstants.rowAnimationDuration,
            );
          }
        },
      ),
      duration: ExercicioDetalheConstants.snackBarDuration,
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

  void _onDuplicateSerie(SerieItem serie) {
    final sectionIndex = controller.sectionIndexOf(serie);
    controller.duplicateSerie(serie);
    setState(() {});
    _animatedListKeys[serie.tipo]?.currentState?.insertItem(
      sectionIndex + 1,
      duration: ExercicioDetalheConstants.rowAnimationDuration,
    );
    widget.onChanged();
  }

  Future<void> _adicionarSerie() async {
    final tipoEscolhido = await _showSerieTypeSelector();

    if (tipoEscolhido != null) {
      final newSerie = _buildSerieFromSelection(tipoEscolhido);
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
          duration: ExercicioDetalheConstants.rowAnimationDuration,
        );
      });

      widget.onChanged();
    }
  }

  SerieItem _buildSerieFromSelection(TipoSerie tipoEscolhido) {
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

    return SerieItem(
      tipo: tipoEscolhido,
      alvo: alvoToClone,
      carga: cargaToClone,
      descanso: descansoToClone,
    );
  }

  Future<TipoSerie?> _showSerieTypeSelector() {
    return showModalBottomSheet<TipoSerie>(
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
                      children: serieTypeOptions
                          .asMap()
                          .entries
                          .map(
                            (entry) => _buildModalOption(
                              option: entry.value,
                              onTap: () =>
                                  Navigator.pop(context, entry.value.type),
                              showDivider:
                                  entry.key != serieTypeOptions.length - 1,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalOption({
    required SerieTypeOption option,
    required VoidCallback onTap,
    required bool showDivider,
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
                      color: option.color.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(option.icon, color: option.color, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.title,
                          style: const TextStyle(
                            color: AppColors.labelPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          option.subtitle,
                          style: const TextStyle(
                            color: AppColors.labelTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.white.withAlpha(15),
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
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: ctrl,
                        maxLines: 8,
                        maxLength:
                            ExercicioDetalheConstants.instructionsMaxLength,
                        autofocus: true,
                        cursorColor: AppColors.primary,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ex: "Focar na cadência do movimento..."',
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
                          final remaining =
                              ExercicioDetalheConstants.instructionsMaxLength -
                              value.text.length;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '$remaining caracteres disponíveis',
                                style: TextStyle(
                                  color:
                                      remaining <
                                          ExercicioDetalheConstants
                                              .warningRemainingChars
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
              const Icon(
                CupertinoIcons.doc_text,
                size: 15,
                color: AppColors.primary,
              ),
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
        Text('Instruções', style: AppTheme.sectionHeader),
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
                const Padding(
                  padding: EdgeInsets.only(top: 3),
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
                const Padding(
                  padding: EdgeInsets.only(top: 3),
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

  Widget _buildSerieRow(
    BuildContext context,
    int visualNumber,
    Animation<double> animation,
    MapEntry<int, SerieItem> entry,
    bool isFirst,
    bool isLast,
  ) {
    final serie = entry.value;
    final realIndex = entry.key;
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

    final accentColor = serieTypeOptions
        .firstWhere((o) => o.type == serie.tipo)
        .color;

    return SizeTransition(
      sizeFactor: animation,
      child: SerieRow(
        serie: serie,
        visualNumber: visualNumber,
        isFirst: isFirst,
        isLast: isLast,
        isNew: controller.newSeriesIds.contains(serie.id),
        isEditingSection: controller.isSectionEditing(serie.tipo),
        repsController: repsController,
        cargaController: cargaController,
        descansoController: descansoController,
        onDelete: () => _onDeleteSerie(serie),
        onDuplicate: () => _onDuplicateSerie(serie),
        onFieldChanged: (field, val) {
          _handleFieldChanged(
            fieldKey: '${field}_$realIndex',
            controller: field == 'reps'
                ? repsController
                : (field == 'carga' ? cargaController : descansoController),
            value: val,
            emptyFallback: field == 'reps'
                ? '0'
                : (field == 'carga' ? '-' : ''),
            onSave: (s) {
              if (field == 'reps') serie.alvo = s;
              if (field == 'carga') serie.carga = s;
              if (field == 'descanso') serie.descanso = s;
            },
          );
        },
        onHintEnd: () {
          if (mounted) {
            setState(() {
              controller.markHintAsShown(serie.id);
            });
          }
        },
        accentColor: accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exerciseTitle = SliverSafeTitle.safeTitle(
      ex.nome,
      fallback: 'Exercício',
    );
    final warmup = controller.entriesForTipo(TipoSerie.aquecimento);
    final feeder = controller.entriesForTipo(TipoSerie.feeder);
    final work = controller.entriesForTipo(TipoSerie.trabalho);
    final muscleGroups = ex.grupoMuscular.isEmpty
        ? const ['Geral']
        : ex.grupoMuscular;

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
                            children: muscleGroups
                                .map((g) => _buildMuscleGroupBadge(g))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      SpacingTokens.screenHorizontalPadding,
                      4,
                      SpacingTokens.screenHorizontalPadding,
                      SpacingTokens.screenBottomPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExerciseVideoCard(
                          imageUrl: ex.imagemUrl,
                          exerciseTitle: exerciseTitle,
                        ),
                        const SizedBox(height: SpacingTokens.sectionGap),
                        _buildInstructionsField(),
                        const SizedBox(height: SpacingTokens.sectionGap),
                        if (ex.series.isEmpty)
                          _buildEmptyState()
                        else ...[
                          _buildSection(
                            title: 'Aquecimento',
                            entries: warmup,
                            tipo: TipoSerie.aquecimento,
                          ),
                          _buildSection(
                            title: 'Séries de aproximação',
                            entries: feeder,
                            tipo: TipoSerie.feeder,
                          ),
                          _buildSection(
                            title: 'Séries de trabalho',
                            entries: work,
                            tipo: TipoSerie.trabalho,
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

  Widget _buildMuscleGroupBadge(String g) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(g, style: AppTheme.caption2),
    );
  }

  Widget _buildEmptyState() {
    return Column(
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
    );
  }

  Widget _buildSection({
    required String title,
    required List<MapEntry<int, SerieItem>> entries,
    required TipoSerie tipo,
  }) {
    final color = serieTypeOptions.firstWhere((o) => o.type == tipo).color;
    return SeriesSection(
      title: title,
      entries: entries,
      titleColor: color,
      isEditingSection: controller.isSectionEditing(tipo),
      onToggleEditing: () => setState(() => controller.toggleEditing(tipo)),
      animatedListKey: _animatedListKeys[tipo]!,
      itemBuilder: (context, index, animation, entry) => _buildSerieRow(
        context,
        index + 1,
        animation,
        entry,
        index == 0,
        index == entries.length - 1,
      ),
    );
  }
}
