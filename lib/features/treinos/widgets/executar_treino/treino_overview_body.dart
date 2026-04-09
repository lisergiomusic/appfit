import 'package:flutter/material.dart';
import '../../models/rotina_model.dart';
import '../../../../core/theme/app_theme.dart';
import 'exercicio_overview_card.dart';

class TreinoOverviewBody extends StatelessWidget {
  final SessaoTreinoModel sessao;
  final Map<String, dynamic> recordedData;
  final void Function(int index) onExerciseTap;
  final int? activeExerciseIndex;

  const TreinoOverviewBody({
    super.key,
    required this.sessao,
    required this.recordedData,
    required this.onExerciseTap,
    this.activeExerciseIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.screenHorizontalPadding,
        vertical: SpacingTokens.lg,
      ),
      child: ListView.separated(
        itemCount: sessao.exercicios.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: SpacingTokens.listItemGap),
        itemBuilder: (context, index) {
          final exercicio = sessao.exercicios[index];
          final exercData =
              recordedData['exercicio_$index'] ?? {'series': []};

          return ExercicioOverviewCard(
            exercicio: exercicio,
            exercicioIndex: index,
            exercicioData: exercData,
            onTap: () => onExerciseTap(index),
            isActive: activeExerciseIndex == index,
          );
        },
      ),
    );
  }
}
