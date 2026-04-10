import 'package:flutter/material.dart';
import '../../../../core/services/exercise_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/appfit_sliver_app_bar.dart';
import '../../shared/models/exercicio_model.dart';
import '../../shared/widgets/exercicio_detalhe/exercise_video_card.dart';

/// Página de visualização do exercício para um aluno.
///
/// Exibe nome, grupo muscular, imagem e instruções. Quando o exercício não
/// traz instruções padrão no objeto passado, a página carrega o registro base
/// pelo nome para tentar recuperar dados adicionais.
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

  @override
  void initState() {
    super.initState();
    _exercicioBaseFuture = widget.exercicio.hasInstrucoesPadrao
        ? null
        : _exerciseService.buscarExercicioPorNome(widget.exercicio.nome);
  }

  @override
  Widget build(BuildContext context) {
    final temImagem =
        widget.exercicio.imagemUrl != null &&
        widget.exercicio.imagemUrl!.isNotEmpty;
    final temMusculos = widget.exercicio.grupoMuscular.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          AppFitSliverAppBar(
            title: widget.exercicio.nome,
            expandedHeight: temMusculos ? 148 : 120,
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
                    future: _exercicioBaseFuture,
                    builder: (context, snapshot) {
                      final temImagemPropria =
                          widget.exercicio.imagemUrl != null &&
                          widget.exercicio.imagemUrl!.isNotEmpty;

                      // Carrega o placeholder apenas quando o recurso não tem imagem
                      // própria e ainda está buscando o exercício base.
                      if (!temImagemPropria &&
                          snapshot.connectionState == ConnectionState.waiting) {
                        return const _VideoCardLoadingPlaceholder();
                      }

                      final resolvedImage = temImagemPropria
                          ? widget.exercicio.imagemUrl
                          : snapshot.data?.imagemUrl;

                      return ExerciseVideoCard(
                        imageUrl: resolvedImage,
                        exerciseTitle: widget.exercicio.nome,
                        autoplayGif: true,
                      );
                    },
                  ),

                  const SizedBox(height: SpacingTokens.sectionGap),

                  Text('Instruções', style: AppTheme.sectionHeader),
                  const SizedBox(height: SpacingTokens.labelToField),
                  FutureBuilder<ExercicioItem?>(
                    future: _exercicioBaseFuture,
                    builder: (context, snapshot) {
                      final instrucoesPadrao =
                          widget.exercicio.instrucoesPadraoTexto ??
                          snapshot.data?.instrucoesPadraoTexto;

                      // Enquanto a instrução ainda não foi definida, mostra um
                      // indicador de carregamento para evitar uma tela vazia.
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
                  const SizedBox(height: SpacingTokens.sectionGap),

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
        aspectRatio: 16 / 9,
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
