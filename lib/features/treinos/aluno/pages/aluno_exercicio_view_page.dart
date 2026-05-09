import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/exercise_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../shared/models/exercicio_model.dart';
import '../../shared/widgets/exercicio_detalhe/exercicio_constants.dart';
import '../../shared/widgets/exercicio_detalhe/exercise_video_card.dart';

class AlunoExercicioViewPage extends StatefulWidget {
  final ExercicioItem exercicio;
  final String? alunoId;

  const AlunoExercicioViewPage({
    super.key,
    required this.exercicio,
    this.alunoId,
  });

  @override
  State<AlunoExercicioViewPage> createState() => _AlunoExercicioViewPageState();
}

class _AlunoExercicioViewPageState extends State<AlunoExercicioViewPage> {
  final ExerciseService _exerciseService = ExerciseService();
  late final Future<ExercicioItem?>? _exercicioBaseFuture;
  late final Future<ExercicioItem?> _exercicioBaseParaMidiaFuture;

  @override
  void initState() {
    super.initState();
    _exercicioBaseFuture = widget.exercicio.hasInstrucoesPadrao
        ? null
        : _exerciseService.buscarExercicioPorNome(widget.exercicio.nome);

    final hasLocalMedia =
        widget.exercicio.mediaUrl != null &&
        widget.exercicio.mediaUrl!.isNotEmpty;
    _exercicioBaseParaMidiaFuture = hasLocalMedia
        ? Future.value(null)
        : _exerciseService.buscarExercicioPorNome(widget.exercicio.nome);
  }

  void _mostrarAvisoInstrucoes(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          side: BorderSide(color: Colors.white.withAlpha(15), width: 0.5),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: AppColors.labelSecondary,
            ),
            const SizedBox(width: SpacingTokens.sm),
            Text('Sobre estas instruções', style: AppTheme.cardTitle),
          ],
        ),
        content: Text(
          'As instruções exibidas aqui são orientações gerais e educativas sobre o exercício, '
          'fornecidas como referência básica. Elas não substituem as orientações individualizadas '
          'do seu personal trainer.\n\n'
          'Antes de executar qualquer exercício, considere:\n\n'
          '• Suas condições físicas e limitações pessoais\n'
          '• Lesões ou restrições médicas preexistentes\n'
          '• As instruções específicas passadas pelo seu personal\n\n'
          'Em caso de dúvida, consulte sempre um profissional de educação física habilitado '
          'antes de iniciar ou modificar sua prática.',
          style: AppTheme.bodyText.copyWith(
            color: AppColors.labelSecondary,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'ENTENDI',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temMusculos = widget.exercicio.grupoMuscular.isNotEmpty;

    // Lógica para ajustar a altura do header com base no tamanho do nome
    // Um nome com mais de ~22 caracteres geralmente quebra para 2 linhas com fontSize 18
    final bool isLongTitle = widget.exercicio.nome.length > 22;
    final double expandedHeight = isLongTitle ? 120 : 90;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: expandedHeight,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            leading: Container(
              margin: const EdgeInsets.only(left: 8),
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withAlpha(150),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(10), width: 0.5),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            // O título da AppBar (colapsado) agora é controlado pelo FlexibleSpace para sincronia perfeita
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final double expandedH = constraints.maxHeight;
                final double collapsedH = MediaQuery.of(context).padding.top + kToolbarHeight;
                // Threshold para considerar colapsado (quando falta ~20px para atingir a altura mínima)
                final bool isCollapsed = expandedH <= collapsedH + 20;

                return FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  centerTitle: true,
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isCollapsed ? 1.0 : 0.0,
                    child: Text(
                      widget.exercicio.nome,
                      style: AppTheme.pageTitle,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(gradient: AppTheme.premiumGradient),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isCollapsed ? 0.0 : 1.0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          SpacingTokens.screenHorizontalPadding,
                          0,
                          SpacingTokens.screenHorizontalPadding,
                          12,
                        ),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            widget.exercicio.nome,
                            style: AppTheme.title1,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.screenHorizontalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (temMusculos) ...[

                    Wrap(
                      spacing: SpacingTokens.xs,
                      runSpacing: SpacingTokens.xs,
                      children: widget.exercicio.grupoMuscular
                          .map(
                            (grupo) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacingTokens.sm,
                                vertical: SpacingTokens.xs,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(10),
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                border: Border.all(color: Colors.white.withAlpha(10), width: 0.5),
                              ),
                              child: Text(
                                grupo.toUpperCase(),
                                style: PillTokens.text.copyWith(
                                  letterSpacing: 1.0,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: SpacingTokens.sectionGap),

                  // Bloco de Vídeo
                  FutureBuilder<ExercicioItem?>(
                    future: _exercicioBaseParaMidiaFuture,
                    builder: (context, snapshot) {
                      final hasLocalMedia =
                          widget.exercicio.mediaUrl != null &&
                          widget.exercicio.mediaUrl!.isNotEmpty;

                      if (!hasLocalMedia &&
                          snapshot.connectionState == ConnectionState.waiting) {
                        return const _VideoCardLoadingPlaceholder();
                      }

                      final resolvedMedia = hasLocalMedia
                          ? widget.exercicio.mediaUrl
                          : snapshot.data?.mediaUrl;

                      return ExerciseVideoCard(
                        mediaUrl: resolvedMedia,
                        exerciseTitle: widget.exercicio.nome,
                      );
                    },
                  ),

                  const SizedBox(height: SpacingTokens.sectionGap),

                  // Cabeçalho de Instruções
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'INSTRUÇÕES',
                        style: AppTheme.sectionHeader.copyWith(
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _mostrarAvisoInstrucoes(context);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 11,
                            color: AppColors.labelSecondary.withAlpha(120),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Conteúdo de Instruções
                  FutureBuilder<ExercicioItem?>(
                    future: _exercicioBaseFuture,
                    builder: (context, snapshot) {
                      final instrucoesPadrao =
                          widget.exercicio.instrucoesPadraoTexto ??
                          snapshot.data?.instrucoesPadraoTexto;

                      if (instrucoesPadrao == null &&
                          snapshot.connectionState == ConnectionState.waiting) {
                        return const _InstructionLoadingCard();
                      }

                      if (instrucoesPadrao != null) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(SpacingTokens.lg),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                            border: Border.all(color: Colors.white.withAlpha(10), width: 0.5),
                          ),
                          child: Text(
                            instrucoesPadrao,
                            style: AppTheme.bodyText.copyWith(
                              color: AppColors.labelPrimary.withAlpha(200),
                              height: 1.6,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: SpacingTokens.xxl,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                          border: Border.all(color: Colors.white.withAlpha(10), width: 0.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 32,
                              color: AppColors.labelSecondary.withAlpha(40),
                            ),
                            const SizedBox(height: SpacingTokens.sm),
                            Text(
                              'Nenhuma instrução disponível',
                              style: AppTheme.premiumLabel.copyWith(
                                color: AppColors.labelSecondary.withAlpha(100),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: SpacingTokens.screenBottomPadding),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoCardLoadingPlaceholder extends StatelessWidget {
  const _VideoCardLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: Colors.white.withAlpha(10), width: 0.5),
      ),
      child: AspectRatio(
        aspectRatio: ExercicioDetalheConstants.videoAspectRatio,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _InstructionLoadingCard extends StatelessWidget {
  const _InstructionLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: Colors.white.withAlpha(10), width: 0.5),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      ),
    );
  }
}