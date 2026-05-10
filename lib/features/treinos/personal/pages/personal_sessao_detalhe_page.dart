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
import 'personal_exercicio_view_page.dart';
import 'personal_exercicios_library_page.dart';
import '../widgets/copy_to_others_sheet.dart';

class PersonalSessaoDetalhePage extends StatelessWidget {
  final String nomeTreino;
  final List<ExercicioItem> exercicios;
  final String sessaoNote;

  final Future<bool> Function(
    List<ExercicioItem> exercicios,
    String nome,
    String sessaoNote,
  )? onSave;

  const PersonalSessaoDetalhePage({
    super.key,
    required this.nomeTreino,
    required this.exercicios,
    this.sessaoNote = '',
    this.onSave,
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
        onSave: onSave,
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
  )? onSave;

  const _SessaoDetalhePersonalView({
    required this.originalExercicios,
    this.onSave,
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

    final animationDelay = Future.delayed(const Duration(milliseconds: 800));

    try {
      final finalExercicios = controller.getFinalExercicios();
      final nome = controller.nomeTreinoController.text.trim();
      final note = controller.sessaoNote;

      if (widget.onSave != null) {
        final salvo = await widget.onSave!(
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

  Future<void> _addAlternative(BuildContext context, int index) async {
    final controller = context.read<ConfigurarTreinoController>();

    final List<ExercicioItem>? selecionados = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PersonalExerciciosLibraryPage(
          isSelectionMode: true,
        ),
      ),
    );

    if (selecionados != null && selecionados.isNotEmpty) {
      controller.addAlternativa(index, selecionados.first);
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _copySeriesToOthers(BuildContext context, int sourceIndex) async {
    final controller = context.read<ConfigurarTreinoController>();
    final allExercises = controller.getFinalExercicios();
    final sourceEx = allExercises[sourceIndex];

    if (sourceEx.series.isEmpty) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Este exercício não possui séries para copiar.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final List<int>? selectedIndices = await CopyToOthersSheet.show(
      context,
      allExercises: allExercises,
      sourceExercise: sourceEx,
    );

    if (selectedIndices != null && selectedIndices.isNotEmpty) {
      controller.replicateSeries(sourceIndex, selectedIndices);
      HapticFeedback.mediumImpact();

      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Séries copiadas para ${selectedIndices.length} ${selectedIndices.length == 1 ? 'exercício' : 'exercícios'}.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showAlternativesModal(
    BuildContext context,
    ExercicioItem exPrincipal,
    int exIndex,
    ConfigurarTreinoController controller,
  ) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.background.withAlpha(235),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.392),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Alternativas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white24, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Exercícios equivalentes para o slot de ${exPrincipal.nome}',
                style: TextStyle(
                  color: Colors.white.withAlpha(120),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              // Lista de Alternativas
              ...exPrincipal.alternativas.asMap().entries.map((entry) {
                final altIndex = entry.key;
                final alt = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withAlpha(10), width: 1),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PersonalExercicioViewPage(
                                exercicio: alt,
                                isSelected: false,
                                isAdmin: false,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              ExercicioThumbnail(
                                exercicio: alt,
                                width: 60,
                                height: 60,
                                borderRadius: 12,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alt.nome,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      alt.grupoMuscular.join(' • '),
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.392),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  controller.removeAlternativa(exIndex, altIndex);
                                  Navigator.pop(context);
                                  HapticFeedback.lightImpact();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AppPrimaryButton(
                  label: 'Adicionar mais alternativas',
                  icon: CupertinoIcons.plus_circle,
                  onPressed: () {
                    Navigator.pop(context);
                    _addAlternative(context, exIndex);
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
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
                    expandedHeight: controller.isEditingTitle ? 140 : 150,
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
                    background: Container(
                      decoration: BoxDecoration(gradient: AppTheme.premiumGradient),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 12,
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
                                        fillColor: Colors.black.withValues(alpha: 0.235),
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
                                        width: 0.5,
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
                  ),
                  if (controller.exercicios.isNotEmpty)
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
                                    'LISTA DE EXERCÍCIOS',
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
                                shadowColor: Colors.black.withValues(alpha: 0.235),
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
                            return _buildCardContent(
                              context,
                              index,
                              isReordering: _isReordering,
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
      color: Colors.black.withValues(alpha: 0.392),
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
                  color: Colors.black.withValues(alpha: 0.392),
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
    final alternativasCount = ex.alternativas.length;
    final hasAlternative = alternativasCount > 0;

    final isConnectedToNext = ex.isSupersetWithNext;
    final isConnectedToPrev = exIndex > 0 && controller.exercicios[exIndex - 1].item.isSupersetWithNext;

    final Widget card = Container(
      decoration: AppTheme.premiumCardDecoration.copyWith(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isConnectedToPrev ? 0 : AppTheme.radiusLarge),
          bottom: Radius.circular(isConnectedToNext ? 0 : AppTheme.radiusLarge),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(isConnectedToPrev ? 0 : AppTheme.radiusLarge),
            bottom: Radius.circular(isConnectedToNext ? 0 : AppTheme.radiusLarge),
          ),
          splashColor: AppColors.splash.withAlpha(50),
          highlightColor: AppColors.splash.withValues(alpha: 0.117),
          onTap: isReordering
              ? null
              : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PersonalExercicioDetalhePage(
                        exercicio: ex,
                        otherExercisesInSession: controller.exercicios
                            .where((w) => w.item != ex)
                            .map((w) => w.item)
                            .toList(),
                        onChanged: () {
                          controller.onExercicioChanged();
                        },
                      ),
                    ),
                  );
                  if (!mounted) return;
                  if (widget.onSave != null && controller.hasChanges) {
                    final finalExercicios = controller.getFinalExercicios();
                    final nome = controller.nomeTreinoController.text.trim();
                    final note = controller.sessaoNote;

                    final salvo = await widget.onSave!(finalExercicios, nome, note);

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
                      Row(
                        children: [
                          Flexible(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!isReordering)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'add_alt') {
                        _addAlternative(context, exIndex);
                      } else if (value == 'view_alt') {
                        _showAlternativesModal(context, ex, exIndex, controller);
                      } else if (value == 'copy_to') {
                        _copySeriesToOthers(context, exIndex);
                      } else if (value == 'toggle_superset') {
                        controller.toggleSuperset(exIndex);
                        HapticFeedback.lightImpact();
                      }
                    },
                    color: AppColors.surfaceDark,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.white.withAlpha(10), width: 1),
                    ),
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: hasAlternative ? AppColors.primary : AppColors.labelSecondary,
                      size: 20,
                    ),
                    itemBuilder: (context) => [
                      if (hasAlternative)
                        const PopupMenuItem(
                          value: 'view_alt',
                          child: Row(
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                size: 18,
                                color: Colors.white70,
                              ),
                              SizedBox(width: 12),
                              Text('Ver exercícios alternativos'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'copy_to',
                        child: Row(
                          children: [
                            Icon(
                              Icons.copy_all_rounded,
                              size: 18,
                              color: Colors.white70,
                            ),
                            SizedBox(width: 12),
                            Text('Copiar séries para...'),
                          ],
                        ),
                      ),
                      if (exIndex < controller.exercicios.length - 1)
                        PopupMenuItem(
                          value: 'toggle_superset',
                          child: Row(
                            children: [
                              Icon(
                                ex.isSupersetWithNext
                                    ? Icons.link_off_rounded
                                    : Icons.link_rounded,
                                size: 18,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 12),
                              Text(ex.isSupersetWithNext
                                  ? 'Desmembrar Bi-set'
                                  : 'Agrupar com o próximo (Bi-set)'),
                            ],
                          ),
                        ),
                      if (!hasAlternative)
                        PopupMenuItem(
                          value: 'add_alt',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 18,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 12),
                              const Text('Add exercício alternativo'),
                            ],
                          ),
                        ),
                    ],
                  ),
                if (isReordering)
                  ReorderableDragStartListener(
                    index: exIndex,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: AppColors.labelSecondary,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final gap = isConnectedToNext ? 0.0 : SpacingTokens.listItemGap;

    Widget finalCard = isReordering
        ? Padding(
            key: Key(wrapper.id),
            padding: EdgeInsets.only(bottom: gap),
            child: card,
          )
        : Padding(
            key: Key(wrapper.id),
            padding: EdgeInsets.only(bottom: gap),
            child: AppSwipeToDelete(
              dismissibleKey: ValueKey('dismiss_${wrapper.id}'),
              onDismissed: (direction) {
                final removedItemName = controller.exercicios[exIndex].item.nome;
                controller.deleteExercicio(exIndex);

                controller.cancelSnackBarTimer();
                _scaffoldMessengerKey.currentState?.removeCurrentSnackBar();

                final snackBar = SnackBar(
                  content: Text('$removedItemName removido'),
                  action: SnackBarAction(
                    label: 'DESFAZER',
                    textColor: AppColors.primary,
                    onPressed: () {
                      controller.cancelSnackBarTimer();
                      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                      controller.undoDelete();
                    },
                  ),
                  duration: const Duration(days: 365),
                  behavior: SnackBarBehavior.floating,
                );

                final snackBarController =
                    _scaffoldMessengerKey.currentState?.showSnackBar(snackBar);

                if (snackBarController != null) {
                  controller.startSnackBarTimer(() {
                    snackBarController.close();
                    controller.clearUndoState();
                  });
                }
              },
              child: card,
            ),
          );

    if (isConnectedToNext) {
      return Column(
        key: Key('${wrapper.id}_group'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          finalCard,
          Container(
            height: 12,
            width: 2,
            margin: const EdgeInsets.only(left: 40), // 16 (pad) + 24 (half thumb)
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.392),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      );
    }

    return finalCard;
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
      decoration: AppTheme.premiumCardDecoration,
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