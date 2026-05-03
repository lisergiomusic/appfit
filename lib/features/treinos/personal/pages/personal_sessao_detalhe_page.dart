import 'dart:async';
import 'dart:ui';
import 'package:appfit/core/widgets/app_bar_text_button.dart';
import 'package:appfit/core/widgets/app_section_link_button.dart';
import 'package:appfit/core/widgets/appfit_sliver_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_swipe_to_delete.dart';
import '../../../../core/widgets/sliver_safe_title.dart';
import '../controllers/configurar_treino_controller.dart';
import '../../shared/models/exercicio_model.dart';
import '../../shared/widgets/exercicio_thumbnail.dart';
import '../../shared/widgets/sessao_note_widget.dart';
import 'personal_exercicio_detalhe_page.dart';
import 'personal_exercicios_library_page.dart';

class PersonalSessaoDetalhePage extends StatelessWidget {
  final String nomeTreino;
  final List<ExercicioItem> exercicios;
  final String sessaoNote;

  /// Called when the session has changes to persist. Receives the updated
  /// exercicios list, session name and note. Returns true on success.
  /// Null means the parent will handle persistence (e.g. new unsaved rotina).
  final Future<bool> Function(
    List<ExercicioItem> exercicios,
    String nome,
    String sessaoNote,
  )? onSaveToFirebase;

  const PersonalSessaoDetalhePage({
    super.key,
    required this.nomeTreino,
    required this.exercicios,
    this.sessaoNote = '',
    this.onSaveToFirebase,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConfigurarTreinoController(
        nomeTreino: nomeTreino,
        exercicios: exercicios,
        sessaoNote: sessaoNote,
      ),
      child: _SessaoDetalhePersonalView(
        originalExercicios: exercicios,
        onSaveToFirebase: onSaveToFirebase,
      ),
    );
  }
}

class _SessaoDetalhePersonalView extends StatefulWidget {
  final List<ExercicioItem> originalExercicios;
  final Future<bool> Function(
    List<ExercicioItem> exercicios,
    String nome,
    String sessaoNote,
  )? onSaveToFirebase;

  const _SessaoDetalhePersonalView({
    required this.originalExercicios,
    this.onSaveToFirebase,
  });

  @override
  State<_SessaoDetalhePersonalView> createState() =>
      _SessaoDetalhePersonalViewState();
}

class _SessaoDetalhePersonalViewState
    extends State<_SessaoDetalhePersonalView> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _addButtonKey = GlobalKey();
  bool _canPopNow = false;
  bool _isSaving = false;
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    });
  }

  Future<void> _concluirESalvar(BuildContext context) async {
    if (_isSaving) return;

    final controller = context.read<ConfigurarTreinoController>();

    if (!controller.hasChanges) {
      setState(() => _canPopNow = true);
      if (mounted) {
        Navigator.of(context).pop({
          'nome': controller.nomeTreinoController.text.trim(),
          'sessaoNote': controller.sessaoNote,
        });
      }
      return;
    }

    setState(() => _isSaving = true);

    // Feedback visual de salvamento (Staff-level UX)
    final animationDelay = Future.delayed(const Duration(milliseconds: 800));

    try {
      final finalExercicios = controller.getFinalExercicios();
      final nome = controller.nomeTreinoController.text.trim();
      final note = controller.sessaoNote;

      if (widget.onSaveToFirebase != null) {
        final salvo = await widget.onSaveToFirebase!(
          finalExercicios,
          nome,
          note,
        );

        if (!mounted) return;

        if (!salvo) {
          setState(() => _isSaving = false);
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: const Text('Falha ao salvar. Verifique sua conexão.'),
              backgroundColor: Colors.redAccent,
              action: SnackBarAction(
                label: 'TENTAR NOVAMENTE',
                textColor: Colors.white,
                onPressed: () => _concluirESalvar(context),
              ),
              duration: const Duration(seconds: 6),
            ),
          );
          return;
        }
      }

      await animationDelay;

      // Atualiza a lista original apenas após o sucesso do salvamento
      widget.originalExercicios.clear();
      widget.originalExercicios.addAll(finalExercicios);

      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _canPopNow = true;
      });
      if (context.mounted) {
        Navigator.of(context).pop({'nome': nome, 'sessaoNote': note});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _openLibrary(BuildContext context) async {
    final controller = context.read<ConfigurarTreinoController>();

    final List<ExercicioItem>? selecionados = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PersonalExerciciosLibraryPage(isSelectionMode: true)),
    );

    if (selecionados != null && selecionados.isNotEmpty) {
      controller.addExercicios(selecionados);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ConfigurarTreinoController>();
    final safeTreinoTitle = SliverSafeTitle.safeTitle(
      controller.nomeTreinoController.text.isEmpty
          ? controller.initialNomeTreino
          : controller.nomeTreinoController.text,
      fallback: 'Treino',
    );
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final shouldShowFab = !controller.isEditingTitle && !isKeyboardVisible;

    return PopScope(
      canPop: !controller.hasChanges || _canPopNow,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _concluirESalvar(context);
      },
      child: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: AppColors.background,
              body: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  AppFitSliverAppBar(
                    title: safeTreinoTitle,
                    expandedHeight: controller.isEditingTitle ? 160 : 170,
                    onBackPressed: () => Navigator.of(context).maybePop(),
                    leading: controller.isEditingTitle
                        ? const SizedBox.shrink()
                        : null,
                    actions: [
                      AppBarTextButton(
                        label: 'Salvar',
                        isLoading: _isSaving,
                        onPressed: _isSaving
                            ? null
                            : () => _concluirESalvar(context),
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
                        child: Row(
                          crossAxisAlignment: controller.isEditingTitle
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: controller.isEditingTitle
                                  ? TextField(
                                      controller: controller.nomeTreinoController,
                                      focusNode: controller.titleFocusNode,
                                      maxLines: 1,
                                      maxLength: 35,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 32,
                                        letterSpacing: -0.5,
                                      ),
                                      buildCounter:
                                          (
                                            context, {
                                            required currentLength,
                                            required isFocused,
                                            maxLength,
                                          }) {
                                            final isLimit =
                                                currentLength == maxLength;
                                            return Text(
                                              '$currentLength / $maxLength',
                                              style: TextStyle(
                                                color: isLimit
                                                    ? Colors.redAccent
                                                    : AppColors.labelSecondary,
                                                fontSize: 12,
                                                fontWeight: isLimit
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                              ),
                                            );
                                          },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.black.withAlpha(60),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: AppColors.primary.withAlpha(120),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      cursorColor: AppColors.primary,
                                      textCapitalization: TextCapitalization.words,
                                      onSubmitted: (_) =>
                                          controller.toggleEditTitle(),
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        controller.toggleEditTitle();
                                      },
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            safeTreinoTitle,
                                            style: AppTheme.bigTitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Builder(
                                            builder: (context) {
                                              final grupos = <String>{};
                                              for (final w
                                                  in controller.exercicios) {
                                                grupos.addAll(w.item.grupoMuscular);
                                              }
                                              if (grupos.isEmpty) {
                                                return const SizedBox.shrink();
                                              }
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: SpacingTokens.sm,
                                                ),
                                                child: Wrap(
                                                  spacing: SpacingTokens.xs,
                                                  runSpacing: SpacingTokens.xs,
                                                  children: grupos
                                                      .map(
                                                        (grupo) => Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal:
                                                                    SpacingTokens
                                                                        .sm,
                                                                vertical:
                                                                    SpacingTokens
                                                                        .xs,
                                                              ),
                                                          decoration:
                                                              PillTokens.decoration,
                                                          child: Text(
                                                            grupo,
                                                            style: PillTokens.text,
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              margin: controller.isEditingTitle
                                  ? const EdgeInsets.only(top: 10)
                                  : EdgeInsets.zero,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    controller.toggleEditTitle();
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withAlpha(20),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      controller.isEditingTitle
                                          ? CupertinoIcons.check_mark
                                          : CupertinoIcons.pencil,
                                      color: controller.isEditingTitle
                                          ? AppColors.primary
                                          : AppColors.labelPrimary,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverOpacity(
                    opacity: controller.isEditingTitle ? 0.3 : 1.0,
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.paddingScreen,
                          4,
                          AppTheme.paddingScreen,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricCard(
                                    label: 'Exercícios',
                                    value: '${controller.exercicios.length}',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _MetricCard(
                                    label: 'Séries',
                                    value: '${controller.totalSeries}',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _MetricCard(
                                    label: 'Estimado',
                                    value: controller.estimatedDurationLabel,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: SpacingTokens.sectionGap),
                            const SessaoNoteWidget(),
                            const SizedBox(height: SpacingTokens.sectionGap),
                            Row(
                              children: [
                                Text(
                                  'Lista de exercícios',
                                  style: AppTheme.sectionHeader,
                                ),
                                const Spacer(),
                                AppSectionLinkButton(
                                  label: _isReordering ? 'Concluir' : 'Reorganizar',
                                  onPressed: controller.exercicios.length < 2
                                      ? null
                                      : () {
                                          HapticFeedback.lightImpact();
                                          setState(
                                            () => _isReordering = !_isReordering,
                                          );
                                        },
                                ),
                              ],
                            ),
                            const SizedBox(height: SpacingTokens.labelToField),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (controller.exercicios.isEmpty)
                    emptyState(shouldShowFab, context),
                  if (controller.exercicios.isNotEmpty)
                    SliverOpacity(
                      opacity: controller.isEditingTitle ? 0.3 : 1.0,
                      sliver: SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.paddingScreen,
                        ),
                        sliver: SliverReorderableList(
                          itemCount: controller.exercicios.length,
                          onReorder: controller.onReorder,
                          proxyDecorator: (child, index, animation) {
                            final curvedAnimation = CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOut,
                            );

                            return ScaleTransition(
                              scale: Tween<double>(
                                begin: 1.0,
                                end: 1.02,
                              ).animate(curvedAnimation),
                              child: Material(
                                elevation: 2.0,
                                shadowColor: Colors.black.withAlpha(60),
                                color: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusLarge,
                                  ),
                                ),
                                child: child,
                              ),
                            );
                          },
                          itemBuilder: (context, index) {
                            final wrapper = controller.exercicios[index];

                            final card = _buildCardContent(
                              context,
                              index,
                              isReordering: _isReordering,
                            );

                            if (_isReordering) {
                              return Padding(
                                key: Key(wrapper.id),
                                padding: const EdgeInsets.only(
                                  bottom: SpacingTokens.listItemGap,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusLG,
                                  ),
                                  child: card,
                                ),
                              );
                            }

                            return Padding(
                              key: Key(wrapper.id),
                              padding: const EdgeInsets.only(
                                bottom: SpacingTokens.listItemGap,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusLG,
                                ),
                                child: AppSwipeToDelete(
                                  dismissibleKey: ValueKey('dismiss_${wrapper.id}'),
                                  onDismissed: (direction) {
                                    final removedItemName =
                                        controller.exercicios[index].item.nome;
                                    controller.deleteExercicio(index);

                                    controller.cancelSnackBarTimer();
                                    _scaffoldMessengerKey.currentState
                                        ?.removeCurrentSnackBar();

                                    final snackBar = SnackBar(
                                      content: Text('$removedItemName removido'),
                                      action: SnackBarAction(
                                        label: 'DESFAZER',
                                        textColor: AppColors.primary,
                                        onPressed: () {
                                          controller.cancelSnackBarTimer();
                                          _scaffoldMessengerKey.currentState
                                              ?.hideCurrentSnackBar();
                                          controller.undoDelete();
                                        },
                                      ),
                                      duration: const Duration(days: 365),
                                      behavior: SnackBarBehavior.floating,
                                    );

                                    final snackBarController = _scaffoldMessengerKey
                                        .currentState
                                        ?.showSnackBar(snackBar);

                                    if (snackBarController != null) {
                                      controller.startSnackBarTimer(() {
                                        snackBarController.close();
                                        controller.clearUndoState();
                                      });
                                    }
                                  },
                                  child: card,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  if (controller.exercicios.isNotEmpty)
                    SliverOpacity(
                      opacity: controller.isEditingTitle ? 0.3 : 1.0,
                      sliver: SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.paddingScreen,
                            24,
                            AppTheme.paddingScreen,
                            24,
                          ),
                          child: AppPrimaryButton(
                            label: 'Adicionar Exercícios',
                            icon: CupertinoIcons.add_circled,
                            onPressed: () => _openLibrary(context),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_isSaving) _buildSavingOverlay(),
          ],
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
                  const Text(
                    'Salvando...',
                    style: TextStyle(
                      color: Colors.white,
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

  SliverFillRemaining emptyState(bool shouldShowFab, BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  Icons.fitness_center_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum exercício adicionado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Toque no botão abaixo para começar a\n'
              'montar o seu treino.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.labelSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const Spacer(flex: 2),
            IgnorePointer(
              ignoring: !shouldShowFab,
              child: AnimatedScale(
                scale: shouldShowFab ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Container(
                  key: _addButtonKey,
                  child: AppPrimaryButton(
                    label: 'Adicionar Exercícios',
                    icon: CupertinoIcons.add_circled,
                    onPressed: () => _openLibrary(context),
                  ),
                ),
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    int exIndex, {
    bool isReordering = false,
  }) {
    final controller = context.read<ConfigurarTreinoController>();
    final wrapper = controller.exercicios[exIndex];
    final ex = wrapper.item;

    return Container(
      decoration: AppTheme.cardDecoration,
      child: Material(
        type: MaterialType.transparency,
        elevation: 0,
        child: InkWell(
          borderRadius: CardTokens.cardRadius,
          splashColor: AppColors.splash.withAlpha(50),
          highlightColor: AppColors.splash.withAlpha(30),
          onTap: isReordering
              ? null
              : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PersonalExercicioDetalhePage(
                        exercicio: ex,
                        onChanged: () {
                          // Notifica a sessão que algo dentro do exercício mudou
                          controller.onExercicioChanged();
                        },
                      ),
                    ),
                  );
                  if (!mounted) return;
                  if (widget.onSaveToFirebase != null && controller.hasChanges) {
                    final finalExercicios = controller.getFinalExercicios();
                    final nome = controller.nomeTreinoController.text.trim();
                    final note = controller.sessaoNote;

                    final salvo = await widget.onSaveToFirebase!(finalExercicios, nome, note);

                    if (!mounted) return;

                    if (salvo) {
                      widget.originalExercicios.clear();
                      widget.originalExercicios.addAll(finalExercicios);
                    } else {
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(
                          content: Text('Falha ao auto-salvar alterações.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
          child: Padding(
            padding: CardTokens.padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ExercicioThumbnail(
                  exercicio: ex,
                  width: 48,
                  height: 48,
                  borderRadius: 8,
                  iconSize: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ex.nome,
                        style: CardTokens.cardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      RichText(
                        text: TextSpan(
                          style: CardTokens.cardSubtitle,
                          children: [
                            TextSpan(
                              text:
                                  '${ex.series.length} ${ex.series.length == 1 ? 'Série' : 'Séries'}',
                              style: const TextStyle(color: AppColors.primary),
                            ),
                            if (ex.grupoMuscular.isNotEmpty)
                              TextSpan(
                                text: ' • ${ex.grupoMuscular.join(' • ')}',
                                style: const TextStyle(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                isReordering
                    ? ReorderableDragStartListener(
                        index: exIndex,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            color: AppColors.labelSecondary,
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(
                        CupertinoIcons.chevron_right,
                        color: AppColors.labelSecondary.withAlpha(100),
                        size: 20.0,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final bool isEstimado = label == 'Estimado';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isEstimado) ...[
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: AppColors.labelSecondary,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.formLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.labelToField),
          Text(value, style: AppTheme.title1),
        ],
      ),
    );
  }
}