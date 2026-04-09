import 'package:flutter/material.dart';
import '../../models/exercicio_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../exercicio_detalhe/exercise_video_card.dart';
import 'workout_set_row.dart';

class ExercicioExecutionBody extends StatelessWidget {
  final ExercicioItem exercicio;
  final int exercicioIndex;
  final List<SerieItem> series;
  final List<TextEditingController> repsControllers;
  final List<TextEditingController> pesoControllers;
  final Map<String, dynamic> exercicioData;
  final void Function(int serieIndex) onSerieCompleted;

  const ExercicioExecutionBody({
    super.key,
    required this.exercicio,
    required this.exercicioIndex,
    required this.series,
    required this.repsControllers,
    required this.pesoControllers,
    required this.exercicioData,
    required this.onSerieCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise image/video
          if (exercicio.imagemUrl != null && exercicio.imagemUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: SpacingTokens.lg),
              child: ExerciseVideoCard(
                imageUrl: exercicio.imagemUrl,
                exerciseTitle: exercicio.nome,
              ),
            ),
          // Exercise header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercicio.nome,
                  style: AppTheme.title1,
                ),
                if (exercicio.grupoMuscular.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: SpacingTokens.md),
                    child: Wrap(
                      spacing: 6,
                      children: exercicio.grupoMuscular
                          .map(
                            (g) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(20),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusXS),
                              ),
                              child: Text(
                                g,
                                style: AppTheme.caption2.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.xl),
          // Instructions section (collapsible)
          if (exercicio.hasInstrucoesPadrao ||
              exercicio.hasInstrucoesPersonalizadas)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.lg,
              ),
              child: _buildInstrucoesSection(),
            ),
          const SizedBox(height: SpacingTokens.xl),
          // Sets table
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.lg,
            ),
            child: Column(
              children: [
                _buildSetsTableHeader(),
                const SizedBox(height: SpacingTokens.sm),
                ..._buildSetRows(),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.screenBottomPadding),
        ],
      ),
    );
  }

  Widget _buildInstrucoesSection() {
    final hasPersonalized = exercicio.hasInstrucoesPersonalizadas;
    final hasPadrao = exercicio.hasInstrucoesPadrao;

    if (!hasPadrao && !hasPersonalized) return const SizedBox.shrink();

    return ExpansionTile(
      title: const Text(
        'Instruções',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        if (hasPersonalized)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: SpacingTokens.md),
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              border: Border.all(
                color: AppColors.primary.withAlpha(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Do seu personal',
                  style: AppTheme.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  exercicio.instrucoesPersonalizadasTexto!,
                  style: AppTheme.cardSubtitle,
                ),
              ],
            ),
          ),
        if (hasPadrao)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              border: Border.all(
                color: AppColors.labelQuaternary,
              ),
            ),
            child: Text(
              exercicio.instrucoesPadraoTexto!,
              style: AppTheme.cardSubtitle,
            ),
          ),
      ],
    );
  }

  Widget _buildSetsTableHeader() {
    return Row(
      children: [
        const SizedBox(width: 40, child: Text('SET')),
        const SizedBox(width: 50, child: Text('ALVO')),
        Expanded(
          child: Text(
            'REPS',
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: Text(
            'PESO',
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  List<Widget> _buildSetRows() {
    int traboIndex = 0;
    final seriesData = exercicioData['series'] as List? ?? [];

    return List.generate(
      series.length,
      (index) {
        final serie = series[index];
        int visualIndex = index + 1;

        if (serie.tipo == TipoSerie.trabalho) {
          visualIndex = traboIndex + 1;
          traboIndex++;
        }

        final isCompleted =
            index < seriesData.length && seriesData[index]['completa'] == true;

        return WorkoutSetRow(
          serie: serie,
          visualIndex: visualIndex,
          repsController: repsControllers[index],
          pesoController: pesoControllers[index],
          isCompleted: isCompleted,
          onCheck: () => onSerieCompleted(index),
        );
      },
    );
  }
}
