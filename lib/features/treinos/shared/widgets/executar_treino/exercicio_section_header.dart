import 'package:flutter/material.dart';
import '../../models/exercicio_model.dart';
import '../../../../../core/theme/app_theme.dart';
import '../exercicio_thumbnail.dart';
import '../../../aluno/pages/aluno_exercicio_view_page.dart';

enum ExercicioMenuAction { verUltimoTreino, detalhes, trocar }

class ExercicioSectionHeader extends StatelessWidget {
  final ExercicioItem exercicio;
  final int exIdx;
  final String? alunoId;
  final void Function(ExercicioMenuAction)? onMenuAction;
  final VoidCallback? onSwap;
  final Widget? trailing;

  const ExercicioSectionHeader({
    super.key,
    required this.exercicio,
    required this.exIdx,
    this.onMenuAction,
    this.onSwap,
    this.alunoId,
    this.trailing,
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
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ExercicioThumbnail(
                          exercicio: exercicio,
                          width: 56,
                          height: 56,
                          borderRadius: AppTheme.radiusSM,
                          iconSize: 22,
                          backgroundColor: AppColors.surfaceLight,
                        ),
                        if (exercicio.alternativas.isNotEmpty && onSwap != null)
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: GestureDetector(
                              onTap: onSwap,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.surfaceDark,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(80),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.swap_horiz_rounded,
                                  color: Colors.black,
                                  size: 14,
                                ),
                              ),
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
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Row(
                              children: [
                                Text(
                                  '${exercicio.series.length} séries',
                                  style: AppTheme.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (muscles.isNotEmpty) ...[
                                  Text(
                                    '  ·  ',
                                    style: AppTheme.caption,
                                  ),
                                  Expanded(
                                    child: Text(
                                      muscles,
                                      style: AppTheme.caption,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
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
          if (trailing != null) trailing!,
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
              onOpened: () => FocusScope.of(context).unfocus(),
              onCanceled: () => FocusScope.of(context).unfocus(),
              onSelected: (action) {
                FocusScope.of(context).unfocus();
                if (action == ExercicioMenuAction.detalhes) {
                  _goToExercicioDetails(context);
                } else if (action == ExercicioMenuAction.trocar) {
                  onSwap?.call();
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
                if (exercicio.alternativas.isNotEmpty && onSwap != null)
                  PopupMenuItem(
                    value: ExercicioMenuAction.trocar,
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz_rounded,
                            size: 18, color: AppColors.labelSecondary),
                        const SizedBox(width: 10),
                        const Text('Trocar exercício'),
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