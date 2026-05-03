import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'dart:ui';
import 'package:appfit/core/widgets/appfit_sliver_app_bar.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/exercise_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/orange_glass_action_button.dart';
import '../../../../core/widgets/app_bar_text_button.dart';
import '../../../../core/widgets/sliver_safe_title.dart';
import '../../../../core/widgets/note_display_field.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/cloudinary.dart';
import '../controllers/exercicio_detalhe_controller.dart';
import '../../shared/models/exercicio_model.dart';
import '../../shared/widgets/exercicio_detalhe/exercicio_constants.dart';
import '../../shared/widgets/exercicio_detalhe/exercise_spotlight_overlay.dart';
import '../../shared/widgets/exercicio_detalhe/serie_row.dart';
import '../../shared/widgets/exercicio_detalhe/series_section.dart';

class PersonalExercicioDetalhePage extends StatefulWidget {
  final ExercicioItem exercicio;
  final VoidCallback onChanged;

  const PersonalExercicioDetalhePage({
    super.key,
    required this.exercicio,
    required this.onChanged,
  });

  @override
  State<PersonalExercicioDetalhePage> createState() =>
      _PersonalExercicioDetalhePageState();
}

class _PersonalExercicioDetalhePageState
    extends State<PersonalExercicioDetalhePage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExercicioDetalheController(widget.exercicio),
      child: _PersonalExercicioDetalheView(
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _PersonalExercicioDetalheView extends StatefulWidget {
  final VoidCallback onChanged;

  const _PersonalExercicioDetalheView({
    required this.onChanged,
  });

  @override
  State<_PersonalExercicioDetalheView> createState() =>
      _PersonalExercicioDetalheViewState();
}

class _PersonalExercicioDetalheViewState
    extends State<_PersonalExercicioDetalheView>
    with TickerProviderStateMixin {
  late final ExercicioItem ex;
  final ExerciseService _exerciseService = ExerciseService();
  late final Future<ExercicioItem?> _exercicioBaseFuture;
  late final double _dynamicHeaderHeight;

  bool _isSaving = false;
  bool _canPopNow = false;

  final Map<TipoSerie, GlobalKey<AnimatedListState>> _animatedListKeys = {
    TipoSerie.aquecimento: GlobalKey<AnimatedListState>(),
    TipoSerie.feeder: GlobalKey<AnimatedListState>(),
    TipoSerie.trabalho: GlobalKey<AnimatedListState>(),
  };

  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final ScrollController _scrollController = ScrollController();
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _suppressNextOnChanged = {};

  @override
  void initState() {
    super.initState();
    ex = context.read<ExercicioDetalheController>().exercicio;
    final hasLocalMedia = ex.mediaUrl != null && ex.mediaUrl!.isNotEmpty;
    _exercicioBaseFuture = hasLocalMedia
        ? Future.value(null)
        : _exerciseService.buscarExercicioPorNome(ex.nome);
    _calculateHeaderHeight();
  }

  void _calculateHeaderHeight() {
    final title = SliverSafeTitle.safeTitle(ex.nome, fallback: 'Exercício');
    final textPainter = TextPainter(
      text: TextSpan(
        text: title,
        style: AppTheme.bigTitle.copyWith(height: 1.1, letterSpacing: -1),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: 300); // Estimativa conservadora de largura disponível para o texto

    final lines = textPainter.computeLineMetrics().length;
    _dynamicHeaderHeight = lines > 1 ? 210 : 180;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _disposeControllers();
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
    context.read<ExercicioDetalheController>().onManualNotify();
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
    final controller = context.read<ExercicioDetalheController>();
    final sectionIndex = controller.sectionIndexOf(serie);

    // UX Senior: Primeiro removemos do AnimatedList para garantir a sincronia da árvore de widgets
    _animatedListKeys[serie.tipo]?.currentState?.removeItem(
      sectionIndex,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: const SizedBox.shrink(),
      ),
    );

    // Depois atualizamos o data source (isso dispara o notifyListeners)
    controller.deleteSerie(serie);

    setState(() {
      _clearEditingState();
    });

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
    final controller = context.read<ExercicioDetalheController>();
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
    final controller = context.read<ExercicioDetalheController>();

    // Forçamos a perda de foco de qualquer campo antes de abrir o seletor ou adicionar
    FocusManager.instance.primaryFocus?.unfocus();

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

        // UX Senior: Rolar para a nova série se ela estiver fora de vista
        _scrollToNewItem();
      });

      widget.onChanged();
    }
  }

  void _scrollToNewItem() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      // Aguardamos um pouco para a animação de inserção começar
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted || !_scrollController.hasClients) return;

        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;

        // Se já estamos perto do fim, ou se a lista cresceu
        if (maxScroll > currentScroll) {
          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      });
    });
  }

  SerieItem _buildSerieFromSelection(TipoSerie tipoEscolhido) {
    String alvoToClone = '', cargaToClone = '', descansoToClone = '';
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
                          option.subtitlePersonal,
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
    final controller = context.read<ExercicioDetalheController>();
    final ctrl = TextEditingController(
      text: ex.instrucoesPersonalizadasTexto ?? '',
    );

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
                        'Instruções gerais',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            ex.instrucoesPersonalizadas =
                                ctrl.text.trim().isEmpty
                                ? null
                                : ctrl.text.trim();
                          });
                          controller.onManualNotify();
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

  Widget _buildSerieRow(
    BuildContext context,
    int visualNumber,
    Animation<double> animation,
    MapEntry<int, SerieItem> entry,
    bool isFirst,
    bool isLast,
  ) {
    final controller = context.read<ExercicioDetalheController>();
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
            emptyFallback: '',
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
    final controller = context.watch<ExercicioDetalheController>();
    // Mapa de seções da interface desta página:
    // 1) Estrutura superior: AppBar, título e ações de navegação.
    // 2) Conteúdo principal: blocos, listas, cards e estados da tela.
    // 3) Ações finais: botões primários, confirmadores e feedbacks.
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

    return PopScope(
      canPop: !controller.hasChanges || _canPopNow,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (controller.hasChanges && !_isSaving) {
          setState(() => _isSaving = true);

          // Feedback visual de salvamento (Staff-level UX)
          await Future.delayed(const Duration(milliseconds: 800));

          if (mounted) {
            setState(() {
              _isSaving = false;
              _canPopNow = true;
            });
            if (mounted) {
              Navigator.of(context).pop();
            }
          }
        } else if (!controller.hasChanges) {
          // Se não houver mudanças, apenas sai imediatamente
          setState(() => _canPopNow = true);
          Navigator.of(context).pop();
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ScaffoldMessenger(
          key: _scaffoldMessengerKey,
          child: Stack(
            children: [
              Scaffold(
                backgroundColor: AppColors.background,
                bottomNavigationBar: ex.series.isNotEmpty
                    ? ColoredBox(
                        color: AppColors.background,
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              SpacingTokens.screenHorizontalPadding,
                              8,
                              SpacingTokens.screenHorizontalPadding,
                              SpacingTokens.md,
                            ),
                            child: OrangeGlassActionButton(
                              label: 'Adicionar Série',
                              onTap: _adicionarSerie,
                              bottomMargin: 0,
                              showGlow: false,
                            ),
                          ),
                        ),
                      )
                    : null,
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    return CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        AppFitSliverAppBar(
                          title: exerciseTitle,
                          expandedHeight: _dynamicHeaderHeight,
                          onBackPressed: () => Navigator.of(context).maybePop(),
                          actions: [
                            AppBarTextButton(
                              label: 'Salvar',
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                          ],
                          background: Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                SpacingTokens.screenHorizontalPadding,
                                0,
                                SpacingTokens.screenHorizontalPadding,
                                SpacingTokens.sm,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exerciseTitle,
                                          style: AppTheme.bigTitle.copyWith(
                                            height: 1.1,
                                            letterSpacing: -1,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (muscleGroups.isNotEmpty) ...[
                                          const SizedBox(height: SpacingTokens.sm),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: muscleGroups
                                                .map((g) => _buildMuscleGroupBadge(g))
                                                .toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildMiniVideoPreview(ex),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (ex.series.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                SpacingTokens.screenHorizontalPadding,
                                SpacingTokens.sectionGap,
                                SpacingTokens.screenHorizontalPadding,
                                0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  NoteDisplayField(
                                    text: ex.instrucoesPersonalizadasTexto,
                                    label: 'Instruções gerais',
                                    addLabel: 'Adicionar instruções gerais',
                                    onTap: _showEditInstructionsSheet,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (ex.series.isEmpty)
                          _buildEmptyState()
                        else ...[
                          _buildSliverSeries(context, warmup, TipoSerie.aquecimento),
                          _buildSliverSeries(context, feeder, TipoSerie.feeder),
                          _buildSliverSeries(context, work, TipoSerie.trabalho),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: SpacingTokens.screenBottomPadding),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              if (_isSaving) _buildSavingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavingOverlay() {
    return Container(
      color: Colors.black.withAlpha(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(100),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Salvando...',
                    style: TextStyle(
                      color: Colors.white.withAlpha(230),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
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

  Widget _buildMuscleGroupBadge(String g) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withAlpha(10), width: 0.5),
      ),
      child: Text(
        g.toUpperCase(),
        style: AppTheme.caption2.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: AppColors.labelSecondary,
        ),
      ),
    );
  }

  Widget _buildMiniVideoPreview(ExercicioItem ex) {
    return FutureBuilder<ExercicioItem?>(
      future: _exercicioBaseFuture,
      builder: (context, snapshot) {
        final hasLocalMedia = ex.mediaUrl != null && ex.mediaUrl!.isNotEmpty;
        final resolvedMedia = hasLocalMedia ? ex.mediaUrl : snapshot.data?.mediaUrl;

        if (resolvedMedia == null || resolvedMedia.isEmpty) {
          return const SizedBox.shrink();
        }

        final heroTag = 'video_${ex.id}';

        return GestureDetector(
          onTap: () => ExerciseSpotlightOverlay.show(
            context,
            mediaUrl: resolvedMedia,
            exerciseTitle: ex.nome,
            heroTag: heroTag,
          ),
          child: Hero(
            tag: heroTag,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: Cloudinary.thumbnail(resolvedMedia),
                    fit: BoxFit.cover,
                  ),
                  Container(
                    color: Colors.black.withAlpha(40),
                    child: const Center(
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
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

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.screenHorizontalPadding,
        ),
        child: Column(
          children: [
            const Spacer(flex: 2),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.fitness_center_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Planeje a execução',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Defina as séries de aquecimento,\naproximação ou trabalho para este exercício.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.labelSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const Spacer(flex: 2),
            OrangeGlassActionButton(
              label: 'Adicionar Primeira Série',
              onTap: _adicionarSerie,
              bottomMargin: 0,
              showGlow: true,
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverSeries(
    BuildContext context,
    List<MapEntry<int, SerieItem>> entries,
    TipoSerie tipo,
  ) {
    if (entries.isEmpty) return const SliverToBoxAdapter();

    final title = tipo == TipoSerie.aquecimento
        ? 'Aquecimento'
        : tipo == TipoSerie.feeder
            ? 'Séries de aproximação'
            : 'Séries de trabalho';

    return SliverPadding(
      padding: const EdgeInsets.only(top: SpacingTokens.sectionGap),
      sliver: SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.screenHorizontalPadding,
          ),
          child: _buildSection(
            title: title,
            entries: entries,
            tipo: tipo,
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<MapEntry<int, SerieItem>> entries,
    required TipoSerie tipo,
  }) {
    final controller = context.read<ExercicioDetalheController>();
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