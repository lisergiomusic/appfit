import 'package:flutter/material.dart';
import '../../models/exercicio_model.dart';
import '../../../../../core/theme/app_theme.dart';
import '../exercicio_thumbnail.dart';

/// Exercise card header: thumbnail (square) with progress ring + name + muscles.
class ExercicioSectionHeader extends StatelessWidget {
  final ExercicioItem exercicio;
  final int exIdx;
  final int completedCount;
  final int totalCount;

  const ExercicioSectionHeader({
    super.key,
    required this.exercicio,
    required this.exIdx,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final muscles = exercicio.grupoMuscular.join(' · ');
    final isCompleto = completedCount == totalCount && totalCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.lg,
        SpacingTokens.lg,
        SpacingTokens.lg,
        SpacingTokens.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail with optional checkmark overlay
          Stack(
            alignment: Alignment.center,
            children: [
              ExercicioThumbnail(
                exercicio: exercicio,
                width: 48,
                height: 48,
                borderRadius: AppTheme.radiusSM,
                iconSize: 22,
                backgroundColor: AppColors.surfaceLight,
              ),
              if (isCompleto)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(210),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.black,
                    size: 22,
                  ),
                ),
            ],
          ),
          const SizedBox(width: SpacingTokens.md),
          // Name + muscles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercicio.nome,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: AppColors.labelPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (muscles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      muscles,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.labelSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          // Series counter badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isCompleto
                  ? AppColors.primary.withAlpha(25)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              '$completedCount/$totalCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isCompleto
                    ? AppColors.primary
                    : AppColors.labelSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
