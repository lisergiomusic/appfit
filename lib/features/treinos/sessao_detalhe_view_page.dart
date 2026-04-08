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

  List<String> _obterGruposUnicos() {
    final grupos = <String>{};
    for (final exercicio in sessao.exercicios) {
      grupos.addAll(exercicio.grupoMuscular);
    }
    return grupos.toList();
  }

  @override
  Widget build(BuildContext context) {
    final gruposUnicos = _obterGruposUnicos();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          AppFitSliverAppBar(
            title: sessao.nome,
            expandedHeight: 180,
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
                    const SizedBox(height: SpacingTokens.sm),
                    if (gruposUnicos.isNotEmpty)
                      Wrap(
                        spacing: SpacingTokens.xs,
                        runSpacing: SpacingTokens.xs,
                        children: gruposUnicos
                            .map(
                              (grupo) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: SpacingTokens.sm,
                                  vertical: SpacingTokens.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(25),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                ),
                                child: Text(
                                  grupo,
                                  style: PillTokens.text,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: SpacingTokens.sm),
                    Text(
                      '${sessao.exercicios.length} exercício${sessao.exercicios.length != 1 ? 's' : ''}',
                      style: AppTheme.cardSubtitle,
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
                    Text(
                      'Observações do treino',
                      style: AppTheme.sectionHeader,
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(SpacingTokens.cardPaddingH),
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
                    (exIndex) => _ExercicioCard(
                      exercicio: sessao.exercicios[exIndex],
                      isLast: exIndex == sessao.exercicios.length - 1,
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

}

class _ExercicioCard extends StatefulWidget {
  final ExercicioItem exercicio;
  final bool isLast;

  const _ExercicioCard({
    required this.exercicio,
    required this.isLast,
  });

  @override
  State<_ExercicioCard> createState() => _ExercicioCardState();
}

class _ExercicioCardState extends State<_ExercicioCard> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _expandido = !_expandido;
            });
          },
          child: Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.all(SpacingTokens.cardPaddingH),
            child: Row(
              children: [
                if (widget.exercicio.imagemUrl != null &&
                    widget.exercicio.imagemUrl!.isNotEmpty)
                  Container(
                    width: ThumbnailTokens.md,
                    height: ThumbnailTokens.md,
                    margin: const EdgeInsets.only(right: SpacingTokens.cardPaddingH),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      color: AppColors.surfaceDark,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      child: Image.network(
                        widget.exercicio.imagemUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.labelSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    width: ThumbnailTokens.md,
                    height: ThumbnailTokens.md,
                    margin: const EdgeInsets.only(right: SpacingTokens.cardPaddingH),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      color: AppColors.primary.withAlpha(20),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.fitness_center,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.exercicio.nome, style: AppTheme.cardTitle),
                      const SizedBox(height: SpacingTokens.xs),
                      Text(
                        '${widget.exercicio.series.length} série${widget.exercicio.series.length != 1 ? 's' : ''}',
                        style: AppTheme.cardSubtitle,
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expandido ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.labelSecondary,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: SpacingTokens.sm),
              if (widget.exercicio.grupoMuscular.isNotEmpty)
                Wrap(
                  spacing: SpacingTokens.xs,
                  runSpacing: SpacingTokens.xs,
                  children: widget.exercicio.grupoMuscular
                      .map(
                        (grupo) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SpacingTokens.sm,
                            vertical: SpacingTokens.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                          ),
                          child: Text(grupo, style: AppTheme.caption2),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: SpacingTokens.sm),
              Column(
                children: List.generate(widget.exercicio.series.length, (sIndex) {
                  final serie = widget.exercicio.series[sIndex];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            'S${sIndex + 1}',
                            style: AppTheme.caption2.copyWith(
                              color: AppColors.labelSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: SpacingTokens.sm),
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
              if (widget.exercicio.instrucoes != null &&
                  widget.exercicio.instrucoes!.isNotEmpty) ...[
                const SizedBox(height: SpacingTokens.sm),
                Text(
                  'Instruções',
                  style: AppTheme.sectionHeader,
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  widget.exercicio.instrucoes!,
                  style: AppTheme.bodyText,
                ),
              ],
            ],
          ),
          crossFadeState: _expandido
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (!widget.isLast)
          Padding(
            padding: const EdgeInsets.only(top: SpacingTokens.sm),
            child: Divider(
              color: AppColors.primary.withAlpha(15),
              height: 1,
            ),
          )
        else
          const SizedBox(height: SpacingTokens.sm),
      ],
    );
  }
}
