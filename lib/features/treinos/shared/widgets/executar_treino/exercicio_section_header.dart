import 'package:flutter/material.dart';
import '../../models/exercicio_model.dart';
import '../../../../../core/theme/app_theme.dart';
import '../exercicio_thumbnail.dart';
import '../../../aluno/pages/aluno_exercicio_view_page.dart';

enum ExercicioMenuAction { verUltimoTreino, detalhes }

class ExercicioSectionHeader extends StatelessWidget {
  final ExercicioItem exercicio;
  final int exIdx;
  final String? alunoId;
  final void Function(ExercicioMenuAction)? onMenuAction;

  const ExercicioSectionHeader({
    super.key,
    required this.exercicio,
    required this.exIdx,
    this.onMenuAction,
    this.alunoId,
  });

  void _goToExercicioDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlunoExercicioViewPage(
          exercicio: exercicio,
          alunoId: alunoId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muscles = exercicio.grupoMuscular.join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.lg,
        SpacingTokens.lg,
        SpacingTokens.xs,
        SpacingTokens.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                onTap: () => _goToExercicioDetails(context),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ExercicioThumbnail(
                      exercicio: exercicio,
                      width: 56,
                      height: 56,
                      borderRadius: AppTheme.radiusSM,
                      iconSize: 22,
                      backgroundColor: AppColors.surfaceLight,
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
          ),
          if (onMenuAction != null)
            PopupMenuButton<ExercicioMenuAction>(
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.labelTertiary,
                size: 22,
              ),
              color: AppColors.surfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              onSelected: (action) {
                if (action == ExercicioMenuAction.detalhes) {
                  _goToExercicioDetails(context);
                } else {
                  onMenuAction?.call(action);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: ExercicioMenuAction.detalhes,
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.labelSecondary),
                      const SizedBox(width: 10),
                      const Text('Detalhes do exercício'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: ExercicioMenuAction.verUltimoTreino,
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded,
                          size: 18, color: AppColors.labelSecondary),
                      const SizedBox(width: 10),
                      const Text('Último registro'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}