import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/appfit_sliver_app_bar.dart';
import '../../core/widgets/note_display_field.dart';
import '../../core/widgets/app_primary_button.dart';
import 'models/rotina_model.dart';
import 'models/exercicio_model.dart';
import 'executar_treino_page.dart';
import 'exercicio_view_page.dart';
import 'widgets/exercicio_thumbnail.dart';

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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Exercícios',
                          value: '${sessao.exercicios.length}',
                          icon: Icons.fitness_center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                          label: 'Séries',
                          value: '$totalSeries',
                          icon: Icons.layers_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                          label: 'Estimado',
                          value: tempoEstimado,
                          icon: Icons.timer_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.sectionGap),
                  NoteDisplayField(
                    text: sessao.orientacoes,
                    label: 'Instruções do personal',
                    addLabel: '',
                    readOnly: true,
                    showInsetShadow: true,
                  ),
                  if (sessao.orientacoes != null &&
                      sessao.orientacoes!.trim().isNotEmpty)
                    const SizedBox(height: SpacingTokens.sectionGap),
                  Text(
                    'Lista de exercícios'.toUpperCase(),
                    style: AppTheme.sectionHeader.copyWith(letterSpacing: 0.8),
                  ),
                  const SizedBox(height: SpacingTokens.labelToField),
                  ...List.generate(
                    sessao.exercicios.length,
                    (exIndex) => _ExercicioCard(
                      exercicio: sessao.exercicios[exIndex],
                      alunoId: alunoId,
                    ),
                  ),
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.screenHorizontalPadding,
        ),
        child: AppPrimaryButton(
          label: 'Iniciar sessão',
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
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _MetricCard({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: AppColors.labelSecondary),
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
          Text(value, style: AppTheme.title1.copyWith(fontSize: 24)),
        ],
      ),
    );
  }
}

class _ExercicioCard extends StatefulWidget {
  final ExercicioItem exercicio;
  final String alunoId;

  const _ExercicioCard({required this.exercicio, required this.alunoId});

  @override
  State<_ExercicioCard> createState() => _ExercicioCardState();
}

class _ExercicioCardState extends State<_ExercicioCard> {
  ExercicioItem get exercicio => widget.exercicio;

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
        return AppColors.iosBlue;
      case TipoSerie.feeder:
        return AppColors.accentMetrics;
      case TipoSerie.trabalho:
        return AppColors.primary;
    }
  }

  Map<TipoSerie, Map<String, int>> _agruparSeriesPorTipoEValor() {
    final grupos = <TipoSerie, Map<String, int>>{
      TipoSerie.aquecimento: {},
      TipoSerie.feeder: {},
      TipoSerie.trabalho: {},
    };

    for (final serie in exercicio.series) {
      final tipo = serie.tipo;
      final chave = serie.alvo;
      if (grupos[tipo]!.containsKey(chave)) {
        grupos[tipo]![chave] = grupos[tipo]![chave]! + 1;
      } else {
        grupos[tipo]![chave] = 1;
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
                        width: 2,
                        height: 15,
                        decoration: BoxDecoration(
                          color: corTipo,
                          borderRadius: BorderRadius.circular(1.5),
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
                    final quantidade = serieEntry.value;

                    return Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 8),
                      child: Text(
                        '${quantidade}x  •  $alvo reps',
                        style: AppTheme.bodyText,
                      ),
                    );
                  }),
                ],
              ),
            );
          }),

          // Instruções
          if (exercicio.hasInstrucoesPadrao ||
              exercicio.hasInstrucoesPersonalizadas) ...[
            const SizedBox(height: SpacingTokens.md),
            Divider(height: 1, color: AppColors.labelQuaternary),
            const SizedBox(height: SpacingTokens.md),
            Text('Instruções', style: AppTheme.sectionHeader),
            const SizedBox(height: 8),
            if (exercicio.hasInstrucoesPadrao)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.labelQuaternary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercicio.instrucoesPadraoTexto!,
                      style: AppTheme.bodyText.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            if (exercicio.hasInstrucoesPadrao &&
                exercicio.hasInstrucoesPersonalizadas)
              const SizedBox(height: 8),
            if (exercicio.hasInstrucoesPersonalizadas)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withAlpha(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instruções do personal',
                      style: AppTheme.caption.copyWith(
                        color: AppColors.labelSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exercicio.instrucoesPersonalizadasTexto!,
                      style: AppTheme.bodyText.copyWith(height: 1.4),
                    ),
                  ],
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
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExercicioViewPage(
                exercicio: exercicio,
                alunoId: widget.alunoId,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          child: Container(
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(SpacingTokens.cardPaddingH),
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(
                          right: SpacingTokens.cardPaddingH,
                        ),
                        child: ExercicioThumbnail(
                          exercicio: exercicio,
                          width: 56,
                          height: 56,
                          borderRadius: 10,
                          iconSize: 26,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercicio.nome,
                              style: AppTheme.cardTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: SpacingTokens.xs),
                            RichText(
                              text: TextSpan(
                                style: AppTheme.cardSubtitle,
                                children: [
                                  TextSpan(
                                    text:
                                        '${exercicio.series.length} ${exercicio.series.length == 1 ? 'Série' : 'Séries'}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  if (exercicio.grupoMuscular.isNotEmpty)
                                    TextSpan(
                                      text:
                                          ' • ${exercicio.grupoMuscular.join(' • ')}',
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: AppColors.labelTertiary,
                      ),
                    ],
                  ),
                ),
                _buildConteudoExpandido(),
              ],
            ),
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
      ],
    );
  }
}
