import 'package:flutter/material.dart';
import '../../models/exercicio_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../exercicio_detalhe/exercicio_editable_field.dart';
import '../exercicio_detalhe/exercicio_constants.dart';

class WorkoutSetRow extends StatelessWidget {
  final SerieItem serie;
  final int visualIndex;
  final TextEditingController repsController;
  final TextEditingController pesoController;
  final bool isCompleted;
  final bool isCurrent;
  final VoidCallback onCheck;

  const WorkoutSetRow({
    super.key,
    required this.serie,
    required this.visualIndex,
    required this.repsController,
    required this.pesoController,
    required this.isCompleted,
    this.isCurrent = false,
    required this.onCheck,
  });

  String get _serieLabel {
    switch (serie.tipo) {
      case TipoSerie.aquecimento:
        return 'W';
      case TipoSerie.feeder:
        return 'F';
      case TipoSerie.trabalho:
        return visualIndex.toString();
    }
  }

  Color get _serieColor {
    final option = serieTypeOptions.firstWhere(
      (opt) => opt.type == serie.tipo,
      orElse: () => serieTypeOptions.last,
    );
    return option.color;
  }

  @override
  Widget build(BuildContext context) {
    final rowColor = isCompleted
        ? AppColors.primary.withAlpha(15)
        : isCurrent
        ? AppColors.primary.withAlpha(8)
        : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: rowColor,
        border: isCurrent && !isCompleted
            ? Border(
                left: BorderSide(
                  color: AppColors.primary.withAlpha(150),
                  width: 2,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.lg,
        vertical: SpacingTokens.sm,
      ),
      child: Row(
        children: [
          // Set badge
          SizedBox(
            width: 40,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _serieColor.withAlpha(22),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Center(
                child: Text(
                  _serieLabel,
                  style: TextStyle(
                    color: _serieColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Target
          SizedBox(
            width: 50,
            child: Text(
              serie.alvo,
              style: AppTheme.caption2,
              textAlign: TextAlign.center,
            ),
          ),
          // Reps input
          Expanded(
            child: ExercicioEditableField(
              controller: repsController,
              onChanged: (_) {},
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          // Peso input
          Expanded(
            child: ExercicioEditableField(
              controller: pesoController,
              onChanged: (_) {},
              keyboardType: TextInputType.number,
              suffixText: 'kg',
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          // Check button
          SizedBox(
            width: 40,
            child: GestureDetector(
              onTap: onCheck,
              child: Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isCompleted
                    ? AppColors.primary
                    : AppColors.labelTertiary,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
