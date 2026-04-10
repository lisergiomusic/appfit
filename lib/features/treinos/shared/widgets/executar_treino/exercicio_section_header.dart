import 'package:flutter/material.dart';
import '../../models/exercicio_model.dart';
import '../../../../../core/theme/app_theme.dart';
import '../exercicio_thumbnail.dart';
import '../../../aluno/pages/aluno_exercicio_view_page.dart';

class ExercicioSectionHeader extends StatelessWidget {
  final ExercicioItem exercicio;
  final int exIdx;
  final int completedCount;
  final String? alunoId;

  const ExercicioSectionHeader({
    super.key,
    required this.exercicio,
    required this.exIdx,
    required this.completedCount,
    this.alunoId,
  });

  @override
  Widget build(BuildContext context) {
    final muscles = exercicio.grupoMuscular.join(' · ');
    final totalCount = exercicio.series.length;
    final isCompleto = completedCount == totalCount && totalCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: CardTokens.cardRadius,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AlunoExercicioViewPage(
                exercicio: exercicio,
                alunoId: alunoId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SpacingTokens.lg,
            SpacingTokens.lg,
            SpacingTokens.lg,
            SpacingTokens.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ExercicioThumbnail(
                    exercicio: exercicio,
                    width: 56,
                    height: 56,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercicio.nome,
                      style: CardTokens.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (muscles.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          muscles,
                          style: AppTheme.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
