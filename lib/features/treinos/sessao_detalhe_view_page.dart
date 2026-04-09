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

  int _calcularTotalSeries() {
    return sessao.exercicios.fold(0, (sum, e) => sum + e.series.length);
  }

  String _calcularTempoEstimado() {
    int totalSegundos = 0;
    for (final exercicio in sessao.exercicios) {
      for (final serie in exercicio.series) {
        // Extrai o número de strings como "60s"
        final match = RegExp(r'(\d+)').firstMatch(serie.descanso);
        if (match != null) {
          totalSegundos += int.parse(match.group(1)!);
        }
      }
    }
    final minutos = totalSegundos ~/ 60;
    if (minutos > 0) {
      return '$minutos min';
    }
    return '${totalSegundos}s';
  }

  @override
  Widget build(BuildContext context) {
    final gruposUnicos = _obterGruposUnicos();
    final tempoEstimado = _calcularTempoEstimado();
    final totalSeries = _calcularTotalSeries();

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
                                decoration: PillTokens.decoration,
                                child: Text(grupo, style: PillTokens.text),
                              ),
                            )
                            .toList(),
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
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Exercícios',
                          value: '${sessao.exercicios.length}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                          label: 'Séries',
                          value: '$totalSeries',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                          label: 'Estimado',
                          value: tempoEstimado,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.sectionGap),
                  if (sessao.orientacoes != null &&
                      sessao.orientacoes!.isNotEmpty) ...[
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
                    const SizedBox(height: SpacingTokens.sectionGap),
                  ],
                  Text('Lista de exercícios', style: AppTheme.sectionHeader),
                  const SizedBox(height: SpacingTokens.labelToField),
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

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final bool isEstimado = label == 'Estimado';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isEstimado) ...[
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: AppColors.labelSecondary,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.formLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.labelToField),
          Text(value, style: AppTheme.title1),
        ],
      ),
    );
  }
}

class _ExercicioCard extends StatefulWidget {
  final ExercicioItem exercicio;
  final bool isLast;

  const _ExercicioCard({required this.exercicio, required this.isLast});

  @override
  State<_ExercicioCard> createState() => _ExercicioCardState();
}

class _ExercicioCardState extends State<_ExercicioCard> {
  bool _expandido = false;

  String _getTituloTipoSerie(TipoSerie tipo) {
    switch (tipo) {
      case TipoSerie.aquecimento:
        return 'Séries de aquecimento';
      case TipoSerie.feeder:
        return 'Séries de aproximação';
      case TipoSerie.trabalho:
        return 'Séries de trabalho';
    }
  }

  Color _getCorTipoSerie(TipoSerie tipo) {
    switch (tipo) {
      case TipoSerie.aquecimento:
        return AppColors.accentMetrics;
      case TipoSerie.feeder:
        return AppColors.iosBlue;
      case TipoSerie.trabalho:
        return AppColors.primary;
    }
  }

  Map<TipoSerie, Map<String, (int, String)>> _agruparSeriesPorTipoEValor() {
    final grupos = <TipoSerie, Map<String, (int, String)>>{
      TipoSerie.aquecimento: {},
      TipoSerie.feeder: {},
      TipoSerie.trabalho: {},
    };

    for (final serie in widget.exercicio.series) {
      final tipo = serie.tipo;
      final chave = serie.alvo;
      if (grupos[tipo]!.containsKey(chave)) {
        final (count, descanso) = grupos[tipo]![chave]!;
        grupos[tipo]![chave] = (count + 1, descanso);
      } else {
        grupos[tipo]![chave] = (1, serie.descanso);
      }
    }

    return grupos;
  }

  Widget _buildConteudoExpandido() {
    final seriesPorTipoEValor = _agruparSeriesPorTipoEValor();
    final tiposComSeries = [
      TipoSerie.aquecimento,
      TipoSerie.feeder,
      TipoSerie.trabalho,
    ].where((tipo) => seriesPorTipoEValor[tipo]!.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.cardPaddingH,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grupos musculares
          if (widget.exercicio.grupoMuscular.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.exercicio.grupoMuscular
                  .map(
                    (grupo) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        grupo,
                        style: AppTheme.caption2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: SpacingTokens.md),
            Divider(height: 1, color: AppColors.labelQuaternary),
            const SizedBox(height: SpacingTokens.md),
          ],

          // Seções de séries agrupadas por tipo
          ...tiposComSeries.asMap().entries.map((typeEntry) {
            final typeIndex = typeEntry.key;
            final tipo = typeEntry.value;
            final seriesPorValor = seriesPorTipoEValor[tipo]!;
            final tituloTipo = _getTituloTipoSerie(tipo);
            final corTipo = _getCorTipoSerie(tipo);
            final isLast = typeIndex == tiposComSeries.length - 1;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : SpacingTokens.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header da seção com trilho colorido
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: corTipo,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      Text(
                        '$tituloTipo:',
                        style: AppTheme.sectionHeader.copyWith(
                          fontSize: 13,
                          letterSpacing: 0.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Agrupamentos de séries por valor
                  ...seriesPorValor.entries.map((serieEntry) {
                    final alvo = serieEntry.key;
                    final (quantidade, descanso) = serieEntry.value;

                    return Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$quantidade× $alvo reps',
                              style: AppTheme.bodyText,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.labelQuaternary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_outlined,
                                  size: 12,
                                  color: AppColors.labelSecondary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  descanso,
                                  style: AppTheme.caption2.copyWith(
                                    color: AppColors.labelSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),

          // Instruções
          if (widget.exercicio.instrucoes != null &&
              widget.exercicio.instrucoes!.isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.md),
            Divider(height: 1, color: AppColors.labelQuaternary),
            const SizedBox(height: SpacingTokens.md),
            Text('Instruções', style: AppTheme.sectionHeader),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.labelQuaternary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.exercicio.instrucoes!,
                style: AppTheme.bodyText.copyWith(height: 1.4),
              ),
            ),
          ],

          const SizedBox(height: SpacingTokens.sm),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expandido = !_expandido;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(SpacingTokens.cardPaddingH),
                  child: Row(
                    children: [
                      if (widget.exercicio.imagemUrl != null &&
                          widget.exercicio.imagemUrl!.isNotEmpty)
                        Container(
                          width: ThumbnailTokens.md,
                          height: ThumbnailTokens.md,
                          margin: const EdgeInsets.only(
                            right: SpacingTokens.cardPaddingH,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSM,
                            ),
                            color: AppColors.surfaceDark,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSM,
                            ),
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
                          margin: const EdgeInsets.only(
                            right: SpacingTokens.cardPaddingH,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSM,
                            ),
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
                            Text(
                              widget.exercicio.nome,
                              style: AppTheme.cardTitle,
                            ),
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
              AnimatedOpacity(
                opacity: _expandido ? 1.0 : 0.0,
                duration: Duration(milliseconds: _expandido ? 300 : 400),
                curve: _expandido ? Curves.easeOut : Curves.easeIn,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: _expandido ? 350 : 450),
                  curve: _expandido ? Curves.easeOut : Curves.easeInCubic,
                  height: _expandido ? null : 0,
                  child: _expandido
                      ? _buildConteudoExpandido()
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
        if (!widget.isLast)
          Padding(
            padding: const EdgeInsets.only(top: SpacingTokens.sm),
            child: Divider(color: AppColors.primary.withAlpha(15), height: 1),
          )
        else
          const SizedBox(height: SpacingTokens.sm),
      ],
    );
  }
}
