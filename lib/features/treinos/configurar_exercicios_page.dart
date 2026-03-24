import 'dart:async';

import 'package:appfit/core/widgets/appfit_sliver_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/orange_glass_action_button.dart';
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
          systemNavigationBarColor: AppTheme.background,
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
          backgroundColor: AppTheme.background,
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
                actions: const [],
                background: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      bottom: 16,
                      right: 16,
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
                                                : AppTheme.textSecondary,
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
                                        color: AppTheme.primary.withAlpha(120),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  cursorColor: AppTheme.primary,
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 34,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            controller.toggleEditTitle();
                          },
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: controller.isEditingTitle ? 8.0 : 0.0,
                            ),
                            child: Icon(
                              controller.isEditingTitle
                                  ? Icons.check_circle_rounded
                                  : Icons.edit_note,
                              color: controller.isEditingTitle
                                  ? AppTheme.primary
                                  : Colors.white.withAlpha(80),
                              size: 44,
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
                      AppTheme.space8,
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
                            const SizedBox(width: 16),
                            Expanded(
                              child: _MetricCard(
                                label: 'Total de Séries',
                                value: '${controller.totalSeries}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const SessaoNoteWidget(),
                        const SizedBox(height: 24),
                        Text(
                          'Lista de exercícios',
                          style: AppTheme.textSectionHeaderDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (controller.exercicios.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
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
                              color: AppTheme.primary,
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
                            color: AppTheme.textSecondary,
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
                              child: OrangeGlassActionButton(
                                label: 'Adicionar Exercícios',
                                onTap: () => _openLibrary(context),
                                bottomMargin: 0,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(flex: 3),
                      ],
                    ),
                  ),
                ),
              if (controller.exercicios.isNotEmpty)
                SliverOpacity(
                  opacity: controller.isEditingTitle ? 0.3 : 1.0,
                  sliver: SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.paddingScreen,
                      vertical: AppTheme.space16,
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
                        final isNew = controller.newExercicios.contains(
                          wrapper.id,
                        );

                        Widget card;
                        if (isNew) {
                          card = _HintingExercicioAnimator(
                            onEnd: () {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  controller.markHintAsShown(wrapper.id);
                                }
                              });
                            },
                            builder: (context, color) {
                              return _buildCardContent(
                                context,
                                index,
                                flashColor: color,
                              );
                            },
                          );
                        } else {
                          card = _buildCardContent(context, index);
                        }

                        return Dismissible(
                          key: Key(wrapper.id),
                          direction: DismissDirection.endToStart,
                          background: Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.space12,
                            ),
                            child: Container(
                               padding: const EdgeInsets.only(right: 16),
                              alignment: Alignment.centerRight,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusLarge,
                                ),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 28,
                              ),
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
                                textColor: AppTheme.primary,
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
                        );
                      },
                    ),
                  ),
                ),
              if (controller.exercicios.isNotEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: IgnorePointer(
                      ignoring: !shouldShowFab,
                      child: AnimatedScale(
                        scale: shouldShowFab ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24.0, bottom: 96.0),
                          child: Container(
                            key: _addButtonKey,
                            child: OrangeGlassActionButton(
                              label: 'Adicionar Exercícios',
                              onTap: () => _openLibrary(context),
                              bottomMargin: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // (Removido: Sliver de espaçamento extra. SafeArea agora garante o espaçamento correto do botão.)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    int exIndex, {
    Color? flashColor,
  }) {
    final controller = context.read<ConfigurarTreinoController>();
    final wrapper = controller.exercicios[exIndex];
    final ex = wrapper.item;

    const String defaultThumbnail = 'https://firebasestorage.googleapis.com/v0/b/appfit-6028c.firebasestorage.app/o/exercicios%2Fplaceholder_exercicio.png?alt=media&token=784e622b-285b-4c91-9549-31c34954060b';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Material(
        elevation: 1.0,
        color: flashColor ?? AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          side: BorderSide(color: Colors.white.withAlpha(14), width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          splashColor: AppTheme.splash.withAlpha(30),
          highlightColor: AppTheme.splash.withAlpha(12),
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
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Thumbnail do Exercício
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: Colors.black.withAlpha(40),
                    child: Image.network(
                      (ex.imagemUrl != null && ex.imagemUrl!.isNotEmpty)
                          ? ex.imagemUrl!
                          : defaultThumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                        child: Icon(
                          Icons.fitness_center,
                          color: AppTheme.primary,
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            color: AppTheme.primary.withAlpha(100),
                          ),
                        );
                      },
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.1,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${ex.series.length} ${ex.series.length == 1 ? 'Série' : 'Séries'}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (ex.grupoMuscular.isNotEmpty)
                              TextSpan(
                                text: ' • ${ex.grupoMuscular.join(' • ')}',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
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
                  color: AppTheme.textSecondary.withAlpha(100),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: AppTheme.cardBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 1,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HintingExercicioAnimator extends StatefulWidget {
  final Widget Function(BuildContext context, Color? color) builder;
  final VoidCallback onEnd;

  const _HintingExercicioAnimator({required this.builder, required this.onEnd});

  @override
  _HintingExercicioAnimatorState createState() =>
      _HintingExercicioAnimatorState();
}

class _HintingExercicioAnimatorState extends State<_HintingExercicioAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _swipeHintAnimation;
  late Animation<double> _swipeHintBgAnimation;

  static final _swipeHintTween = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: -72.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 35,
    ),
    TweenSequenceItem(tween: ConstantTween<double>(-72.0), weight: 15),
    TweenSequenceItem(
      tween: Tween(
        begin: -72.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 50,
    ),
  ]);

  static final _swipeHintBgTween = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 72.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 35,
    ),
    TweenSequenceItem(tween: ConstantTween<double>(72.0), weight: 15),
    TweenSequenceItem(
      tween: Tween(
        begin: 72.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 50,
    ),
  ]);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    );

    final highlightColor = AppTheme.primary.withValues(alpha: 0.12);
    // Sequência 1: Animação de flash (0ms a 1200ms)
    _colorAnimation =
        TweenSequence<Color?>([
          TweenSequenceItem(
            tween: ColorTween(begin: AppTheme.surfaceDark, end: highlightColor),
            weight: 50.0,
          ),
          TweenSequenceItem(
            tween: ColorTween(begin: highlightColor, end: AppTheme.surfaceDark),
            weight: 50.0,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 1200 / 2600, curve: Curves.easeOut),
          ),
        );
    final swipeInterval = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.linear),
    );
    _swipeHintAnimation = _swipeHintTween.animate(swipeInterval);
    _swipeHintBgAnimation = _swipeHintBgTween.animate(swipeInterval);

    Future.delayed(const Duration(milliseconds: 600), () {
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
        final dx = _swipeHintAnimation.value;
        final bgWidth = _swipeHintBgAnimation.value;

        return Stack(
          children: [
            if (bgWidth > 0)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.space12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      child: Container(
                        width: bgWidth,
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                         padding: const EdgeInsets.only(right: 16),
                        child: Opacity(
                          opacity: (bgWidth / 72.0).clamp(0.0, 1.0),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Transform.translate(
              offset: Offset(dx, 0),
              child: widget.builder(context, _colorAnimation.value),
            ),
          ],
        );
      },
    );
  }
}