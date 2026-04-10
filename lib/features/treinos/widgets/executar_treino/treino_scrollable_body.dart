import 'package:flutter/material.dart';
import '../../models/rotina_model.dart';
import '../../models/exercicio_model.dart';
import '../../../../core/theme/app_theme.dart';
import 'exercicio_section_header.dart';
import 'workout_set_row.dart';

class TreinoScrollableBody extends StatelessWidget {
  final SessaoTreinoModel sessao;
  final Map<String, dynamic> recordedData;
  final List<List<TextEditingController>> repsControllers;
  final List<List<TextEditingController>> pesoControllers;
  final void Function(int exercicioIndex, int serieIndex) onSerieCompleted;

  const TreinoScrollableBody({
    super.key,
    required this.sessao,
    required this.recordedData,
    required this.repsControllers,
    required this.pesoControllers,
    required this.onSerieCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 140),
      itemCount: sessao.exercicios.length,
      itemBuilder: (context, exIdx) {
        final exercicio = sessao.exercicios[exIdx];
        final exData = recordedData['exercicio_$exIdx'] ?? {'series': []};
        final seriesList = (exData['series'] as List?) ?? [];
        final isLast = exIdx == sessao.exercicios.length - 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExercicioSectionHeader(exercicio: exercicio, exIdx: exIdx),
            _ColumnLabelsRow(),
            ...List.generate(exercicio.series.length, (sIdx) {
              final isCompleted = seriesList.length > sIdx
                  ? (seriesList[sIdx] as Map)['completa'] == true
                  : false;
              return WorkoutSetRow(
                serie: exercicio.series[sIdx],
                visualIndex: _calcWorkIndex(exercicio, sIdx),
                repsController: repsControllers[exIdx][sIdx],
                pesoController: pesoControllers[exIdx][sIdx],
                isCompleted: isCompleted,
                onCheck: () => onSerieCompleted(exIdx, sIdx),
              );
            }),
            if (!isLast)
              Divider(
                color: AppColors.separator.withAlpha(100),
                height: 1,
                thickness: 1,
                indent: SpacingTokens.lg,
                endIndent: SpacingTokens.lg,
              )
            else
              const SizedBox(height: SpacingTokens.xxl),
          ],
        );
      },
    );
  }

  int _calcWorkIndex(ExercicioItem exercicio, int upToIdx) {
    int count = 0;
    for (int i = 0; i <= upToIdx; i++) {
      if (exercicio.series[i].tipo == TipoSerie.trabalho) count++;
    }
    return count;
  }
}

class _ColumnLabelsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: AppColors.labelTertiary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.lg,
        vertical: SpacingTokens.xs,
      ),
      child: Row(
        children: [
          const SizedBox(width: 40, child: Text('SÉRIE', style: labelStyle)),
          const SizedBox(
            width: 50,
            child: Text('ALVO', style: labelStyle, textAlign: TextAlign.center),
          ),
          const Expanded(
            child: Text('REPS', style: labelStyle, textAlign: TextAlign.center),
          ),
          const SizedBox(width: SpacingTokens.sm),
          const Expanded(
            child: Text('KG', style: labelStyle, textAlign: TextAlign.center),
          ),
          const SizedBox(width: SpacingTokens.sm),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
