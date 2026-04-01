import 'dart:async';
import 'package:appfit/core/widgets/app_bar_text_button.dart';
import 'package:appfit/core/widgets/app_section_link_button.dart';
import 'package:appfit/core/widgets/appfit_sliver_app_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/sliver_safe_title.dart';
import 'configurar_treino_controller.dart';
import 'exercicio_detalhe_page.dart';
import 'exercicios_library_page.dart';
import 'models/exercicio_model.dart';
import 'widgets/sessao_note_widget.dart';

class ConfigurarExerciciosPage extends StatelessWidget {
  final String nomeTreino;
  final List<ExercicioItem> exercicios;
  final String sessaoNote;

  const ConfigurarExerciciosPage({
    super.key,
    required this.nomeTreino,
    required this.exercicios,
    this.sessaoNote = '',
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConfigurarTreinoController(
        nomeTreino: nomeTreino,
        exercicios: exercicios,
        sessaoNote: sessaoNote,
      ),
      child: _ConfigurarExerciciosView(originalExercicios: exercicios),
    );
  }
}

class _ConfigurarExerciciosView extends StatefulWidget {
  final List<ExercicioItem> originalExercicios;

  const _ConfigurarExerciciosView({required this.originalExercicios});

  @override
  State<_ConfigurarExerciciosView> createState() =>
      _ConfigurarExerciciosViewState();
}

class _ConfigurarExerciciosViewState extends State<_ConfigurarExerciciosView> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _addButtonKey = GlobalKey();
  bool _canPopNow = false;
  bool _isSaving = false;

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

  void _concluirESalvar(BuildContext context) {
    if (_isSaving) return;
    _isSaving = true;

    final controller = context.read<ConfigurarTreinoController>();

    // Atualiza a lista original (passagem por referência)
    widget.originalExercicios.clear();
    widget.originalExercicios.addAll(controller.getFinalExercicios());

    setState(() => _canPopNow = true);

    if (mounted) {
      Navigator.of(context).pop({
        'nome': controller.nomeTreinoController.text.trim(),
        'sessaoNote': controller.sessaoNote,
      });
    }
  }

  Future<void> _openLibrary(BuildContext context) async {
    final controller = context.read<ConfigurarTreinoController>();

    // Agora o tipo de retorno bate certinho com o que a biblioteca envia!
    final List<ExercicioItem>? selecionados = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExerciciosLibraryPage()),
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
      canPop: _canPopNow,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _concluirESalvar(context);
      },
      child: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              AppFitSliverAppBar(
                title: safeTreinoTitle,
                expandedHeight: controller.isEditingTitle ? 160 : 140,
                onBackPressed: () => Navigator.of(context).maybePop(),
                leading: controller.isEditingTitle
                    ? const SizedBox.shrink()
                    : null,
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
                                  child: Text(
                                    safeTreinoTitle,
                                    style: AppTheme.bigTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          margin: controller.isEditingTitle
                              ? EdgeInsets.only(top: 10)
                              : EdgeInsets.zero,
                          child: IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              controller.toggleEditTitle();
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.buttonSurface,
                            ),
                            icon: Icon(
                              controller.isEditingTitle
                                  ? CupertinoIcons.check_mark
                                  : CupertinoIcons.pencil,
                              color: controller.isEditingTitle
                                  ? AppColors.primary
                                  : AppColors.labelPrimary,
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
                                label: 'Tempo',
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
                            AppSectionLinkButton(label: 'Reorganizar'),
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
                            elevation: 6.0,
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

                        final card = _buildCardContent(context, index);

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: SpacingTokens.listItemGap,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLG,
                            ),
                            child: Dismissible(
                              key: Key(wrapper.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.systemRed.withAlpha(220),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 18),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(height: 3),
                                    Text(
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

  Widget _buildCardContent(BuildContext context, int exIndex) {
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
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExercicioDetalhePage(
                  exercicio: ex,
                  onChanged: () => controller.onExercicioChanged(),
                ),
              ),
            );
          },
          child: Padding(
            padding: CardTokens.padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Thumbnail do Exercício
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: Colors.black.withAlpha(40),
                    child: (ex.imagemUrl != null && ex.imagemUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: ex.imagemUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary.withAlpha(100),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(
                                Icons.fitness_center,
                                color: AppColors.labelSecondary,
                                size: 24,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.fitness_center,
                              color: AppColors.labelSecondary,
                              size: 24,
                            ),
                          ),
                  ),
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
                Icon(
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
    final bool isTempo = label == 'Tempo';

    Widget card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTheme.formLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isTempo) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppColors.labelSecondary.withAlpha(180),
                ),
              ],
            ],
          ),
          const SizedBox(height: SpacingTokens.labelToField),
          Text(value, style: AppTheme.title1),
        ],
      ),
    );

    if (isTempo) {
      return Tooltip(
        message: 'Tempo estimado com base nas séries e descanso',
        triggerMode: TooltipTriggerMode.tap,
        showDuration: Duration(seconds: 3),
        preferBelow: false,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withAlpha(100)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        child: card,
      );
    }

    return card;
  }
}
