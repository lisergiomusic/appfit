import 'package:flutter/material.dart';
import '../../../../core/services/exercise_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/appfit_sliver_app_bar.dart';
import '../../shared/models/exercicio_model.dart';
import '../../shared/widgets/exercicio_detalhe/exercicio_constants.dart';
import '../../shared/widgets/exercicio_detalhe/exercise_video_card.dart';
import 'personal_criar_exercicio_page.dart';

class PersonalExercicioViewPage extends StatefulWidget {
  final ExercicioItem exercicio;
  final bool isSelected;
  final bool isAdmin;

  const PersonalExercicioViewPage({
    super.key,
    required this.exercicio,
    required this.isSelected,
    required this.isAdmin,
  });

  @override
  State<PersonalExercicioViewPage> createState() => _PersonalExercicioViewPageState();
}

class _PersonalExercicioViewPageState extends State<PersonalExercicioViewPage> {
  final ExerciseService _exerciseService = ExerciseService();
  late bool _isSelected;
  late final Future<ExercicioItem?>? _exercicioBaseFuture;
  late final Future<ExercicioItem?> _exercicioBaseParaMidiaFuture;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.isSelected;

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
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
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
          'passadas por você para cada aluno.\n\n'
          'Ao editar um exercício global, as instruções que você definir serão aplicadas a todos os alunos '
          'que utilizarem este exercício na sua biblioteca.',
          style: AppTheme.bodyText.copyWith(
            color: AppColors.labelSecondary,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
              ),
              child: const Text(
                'Entendi',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temImagem =
        widget.exercicio.mediaUrl != null &&
        widget.exercicio.mediaUrl!.isNotEmpty;
    final temMusculos = widget.exercicio.grupoMuscular.isNotEmpty;

    final screenWidth = MediaQuery.of(context).size.width;
    final titleWidth = screenWidth - SpacingTokens.screenHorizontalPadding * 2;
    final titlePainter = TextPainter(
      text: TextSpan(text: widget.exercicio.nome, style: AppTheme.bigTitle),
      textDirection: TextDirection.ltr,
    )..layout();
    final quebra2Linhas = titlePainter.width > titleWidth;

    final expandedHeight = quebra2Linhas
        ? (temMusculos ? 188.0 : 160.0)
        : (temMusculos ? 148.0 : 120.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                AppFitSliverAppBar(
                  title: widget.exercicio.nome,
                  expandedHeight: expandedHeight,
                  background: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: SpacingTokens.screenHorizontalPadding,
                        right: SpacingTokens.screenHorizontalPadding,
                        bottom: SpacingTokens.sm,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.exercicio.nome, style: AppTheme.bigTitle),
                          if (temMusculos) ...[
                            const SizedBox(height: SpacingTokens.sm),
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
                                      decoration: PillTokens.decoration,
                                      child: Text(grupo, style: PillTokens.text),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
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
                        const SizedBox(height: SpacingTokens.sm),

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

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Instruções', style: AppTheme.sectionHeader),
                            GestureDetector(
                              onTap: () => _mostrarAvisoInstrucoes(context),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: AppColors.labelTertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: SpacingTokens.labelToField),
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
                              return _InstructionCard(text: instrucoesPadrao);
                            }

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: SpacingTokens.xl,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDark,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusLG,
                                ),
                                border: Border.all(
                                  color: Colors.white.withAlpha(10),
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.menu_book_rounded,
                                    size: 32,
                                    color: AppColors.labelTertiary,
                                  ),
                                  const SizedBox(height: SpacingTokens.sm),
                                  Text(
                                    'Nenhuma instrução disponível',
                                    style: AppTheme.cardSubtitle.copyWith(
                                      color: AppColors.labelTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        if (widget.isAdmin) ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PersonalCriarExercicioPage(
                                      exercicioParaEditar: widget.exercicio,
                                    ),
                                  ),
                                );
                                if (result != null && mounted) {
                                  Navigator.pop(context, 'reload');
                                }
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Editar Exercício (Admin)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        if (!temImagem && !temMusculos)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.fitness_center_rounded,
                                    size: 48,
                                    color: AppColors.labelTertiary,
                                  ),
                                  const SizedBox(height: SpacingTokens.sm),
                                  Text(
                                    'Sem informações adicionais',
                                    style: AppTheme.cardSubtitle.copyWith(
                                      color: AppColors.labelTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: SpacingTokens.screenBottomPadding),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: Colors.white.withAlpha(10))),
            ),
            child: ElevatedButton(
              onPressed: () {
                setState(() => _isSelected = !_isSelected);
                Navigator.pop(context, _isSelected ? 'select' : 'unselect');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSelected ? AppColors.surfaceLight : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _isSelected ? 'Remover do Treino' : 'Adicionar ao Treino',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _isSelected ? Colors.redAccent : Colors.black,
                ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(10), width: 0.5),
      ),
      child: AspectRatio(
        aspectRatio: ExercicioDetalheConstants.videoAspectRatio,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  final String text;

  const _InstructionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingTokens.cardPaddingH),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: Colors.white.withAlpha(10), width: 0.5),
      ),
      child: Text(text, style: AppTheme.bodyText),
    );
  }
}