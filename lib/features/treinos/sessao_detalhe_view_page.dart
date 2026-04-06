import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/appfit_sliver_app_bar.dart';
import '../../core/widgets/app_primary_button.dart';
import 'models/rotina_model.dart';
import 'models/exercicio_model.dart';
import 'executar_treino_page.dart';

class SessaoDetalheViewPage extends StatelessWidget {
  final SessaoTreinoModel sessao;
  final String letra;
  final String rotinaId;
  final String alunoId;

  const SessaoDetalheViewPage({
    super.key,
    required this.sessao,
    required this.letra,
    required this.rotinaId,
    required this.alunoId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          AppFitSliverAppBar(
            title: sessao.nome,
            expandedHeight: 148,
            background: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: SpacingTokens.screenHorizontalPadding,
                  right: SpacingTokens.screenHorizontalPadding,
                  bottom: SpacingTokens.sectionGap,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sessao.nome, style: AppTheme.bigTitle),
                    const SizedBox(height: SpacingTokens.xs),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SpacingTokens.sm,
                            vertical: SpacingTokens.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                          ),
                          child: Text(
                            letra,
                            style: AppTheme.caption2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (sessao.diaSemana != null &&
                            sessao.diaSemana!.isNotEmpty) ...[
                          const SizedBox(width: SpacingTokens.sm),
                          Text(sessao.diaSemana!, style: AppTheme.caption),
                        ],
                        const SizedBox(width: SpacingTokens.sm),
                        Text(
                          '${sessao.exercicios.length} exercício${sessao.exercicios.length != 1 ? 's' : ''}',
                          style: AppTheme.caption2.copyWith(
                            color: AppColors.labelSecondary,
                          ),
                        ),
                      ],
                    ),
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
                  if (sessao.orientacoes != null &&
                      sessao.orientacoes!.isNotEmpty) ...[
                    const SizedBox(height: SpacingTokens.sectionGap),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(10),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(30),
                        ),
                      ),
                      child: Text(
                        sessao.orientacoes!,
                        style: AppTheme.bodyText,
                      ),
                    ),
                  ],
                  const SizedBox(height: SpacingTokens.sectionGap),
                  ...List.generate(
                    sessao.exercicios.length,
                    (exIndex) => _buildExerciseItem(
                      sessao.exercicios[exIndex],
                      exIndex,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.screenBottomPadding),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.screenHorizontalPadding,
            vertical: SpacingTokens.sm,
          ),
          child: AppPrimaryButton(
            label: 'Iniciar treino',
            icon: Icons.play_arrow_rounded,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExecutarTreinoPage(
                    sessao: sessao,
                    rotinaId: rotinaId,
                    alunoId: alunoId,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseItem(ExercicioItem exercise, int exIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.nome, style: AppTheme.cardTitle),
          if (exercise.grupoMuscular.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                children: exercise.grupoMuscular
                    .map(
                      (grupo) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(grupo, style: AppTheme.caption2),
                      ),
                    )
                    .toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: List.generate(exercise.series.length, (sIndex) {
                final serie = exercise.series[sIndex];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          'S${sIndex + 1}',
                          style: AppTheme.caption2.copyWith(
                            color: AppColors.labelSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${serie.alvo} reps | ${serie.carga}kg | ${serie.descanso}s',
                          style: AppTheme.bodyText,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          if (exIndex < sessao.exercicios.length - 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Divider(color: AppColors.primary.withAlpha(15), height: 1),
            ),
        ],
      ),
    );
  }
}
