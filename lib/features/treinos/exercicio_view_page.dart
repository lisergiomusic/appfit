import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'models/exercicio_model.dart';
import 'widgets/exercicio_detalhe/exercise_video_card.dart';

class ExercicioViewPage extends StatelessWidget {
  final ExercicioItem exercicio;

  const ExercicioViewPage({super.key, required this.exercicio});

  @override
  Widget build(BuildContext context) {
    final temImagem =
        exercicio.imagemUrl != null && exercicio.imagemUrl!.isNotEmpty;
    final temInstrucoes =
        exercicio.instrucoes != null && exercicio.instrucoes!.trim().isNotEmpty;
    final temMusculos = exercicio.grupoMuscular.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            title: Text(exercicio.nome, style: AppTheme.pageTitle),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: AppColors.primary,
              onPressed: () => Navigator.pop(context),
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

                  // Mídia: imagem ou placeholder
                  ExerciseVideoCard(
                    imageUrl: exercicio.imagemUrl,
                    exerciseTitle: exercicio.nome,
                  ),

                  const SizedBox(height: SpacingTokens.sectionGap),

                  // Músculos ativados
                  if (temMusculos) ...[
                    Text('Músculos ativados', style: AppTheme.sectionHeader),
                    const SizedBox(height: SpacingTokens.labelToField),
                    Wrap(
                      spacing: SpacingTokens.xs,
                      runSpacing: SpacingTokens.xs,
                      children: exercicio.grupoMuscular
                          .map(
                            (grupo) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacingTokens.sm,
                                vertical: SpacingTokens.xs,
                              ),
                              decoration: PillTokens.decoration,
                              child: Text(
                                grupo,
                                style: PillTokens.text,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: SpacingTokens.sectionGap),
                  ],

                  // Instruções
                  if (temInstrucoes) ...[
                    Text('Como executar', style: AppTheme.sectionHeader),
                    const SizedBox(height: SpacingTokens.labelToField),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(SpacingTokens.cardPaddingH),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                        border: Border.all(
                          color: Colors.white.withAlpha(10),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        exercicio.instrucoes!,
                        style: AppTheme.bodyText.copyWith(
                          height: 1.55,
                          color: AppColors.labelPrimary,
                        ),
                      ),
                    ),
                  ],

                  // Placeholder quando não há informações adicionais
                  if (!temImagem && !temMusculos && !temInstrucoes)
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
