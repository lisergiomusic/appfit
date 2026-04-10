import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/appfit_sliver_app_bar.dart';
import '../../../../core/widgets/note_display_field.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../shared/models/rotina_model.dart';
import '../../shared/models/exercicio_model.dart';
import '../../shared/widgets/executar_treino/exercicio_section_header.dart';
import '../../shared/widgets/executar_treino/orientacao_personal_banner.dart';
import '../../shared/widgets/executar_treino/serie_badge_info_dialog.dart';
import '../../shared/widgets/exercicio_detalhe/exercicio_constants.dart';
import 'aluno_executar_treino_page.dart';

class AlunoSessaoDetalhePage extends StatelessWidget {
  final SessaoTreinoModel sessao;
  final String letra;
  final String rotinaId;
  final String alunoId;

  const AlunoSessaoDetalhePage({
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

  Future<void> _confirmarIniciarSessao(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text('Iniciar sessão', style: AppTheme.title1),
        content: Text(
          'Pronto para treinar? Você vai executar a sessão "${sessao.nome}" e o tempo de treino começará a contar imediatamente.',
          style: AppTheme.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.labelSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Iniciar', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AlunoExecutarTreinoPage(
            sessao: sessao,
            rotinaId: rotinaId,
            alunoId: alunoId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mapa de seções da interface desta página:
    // 1) Estrutura superior: AppBar, título e ações de navegação.
    // 2) Conteúdo principal: blocos, listas, cards e estados da tela.
    // 3) Ações finais: botões primários, confirmadores e feedbacks.
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
                  Text('Exercícios', style: AppTheme.sectionHeader),
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
          onPressed: () => _confirmarIniciarSessao(context),
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

class _ExercicioCard extends StatelessWidget {
  final ExercicioItem exercicio;
  final String alunoId;

  const _ExercicioCard({required this.exercicio, required this.alunoId});

  int _calcWorkIndex(int upToIdx) {
    int count = 0;
    for (int i = 0; i <= upToIdx; i++) {
      if (exercicio.series[i].tipo == TipoSerie.trabalho) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.listItemGap),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExercicioSectionHeader(
              exercicio: exercicio,
              exIdx: 0,
              alunoId: alunoId,
            ),
            if (exercicio.instrucoesParaExibicao != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.lg,
                ),
                child: OrientacaoPersonalBanner(
                  orientacao: exercicio.instrucoesParaExibicao,
                ),
              ),
            const SizedBox(height: SpacingTokens.sm),
            _ColumnLabelsRow(),
            const SizedBox(height: SpacingTokens.xs),
            ...List.generate(exercicio.series.length, (sIdx) {
              return _ReadOnlySetRow(
                serie: exercicio.series[sIdx],
                visualIndex: _calcWorkIndex(sIdx),
              );
            }),
            const SizedBox(height: SpacingTokens.sm),
          ],
        ),
      ),
    );
  }
}

class _ColumnLabelsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: AppColors.labelTertiary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.screenHorizontalPadding,
      ),
      child: Row(
        children: const [
          SizedBox(
            width: 36,
            child: Text(
              'SÉRIE',
              style: labelStyle,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Text('ALVO', style: labelStyle, textAlign: TextAlign.center),
          ),
          SizedBox(width: SpacingTokens.md),
          SizedBox(
            width: 72,
            child: Text(
              'DESCANSO',
              style: labelStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlySetRow extends StatelessWidget {
  final SerieItem serie;
  final int visualIndex;

  const _ReadOnlySetRow({required this.serie, required this.visualIndex});

  SerieTypeOption get _serieOption => serieTypeOptions.firstWhere(
    (opt) => opt.type == serie.tipo,
    orElse: () => serieTypeOptions.last,
  );

  Color get _serieColor => _serieOption.color;

  IconData? get _badgeIcon =>
      serie.tipo != TipoSerie.trabalho ? _serieOption.icon : null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.screenHorizontalPadding,
        vertical: SpacingTokens.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => showSerieBadgeInfo(context, serie.tipo),
            child: SizedBox.square(
              dimension: 36,
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _serieColor.withAlpha(22),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: Center(
                    child: _badgeIcon != null
                        ? Icon(_badgeIcon, size: 16, color: _serieColor)
                        : Text(
                            visualIndex.toString(),
                            style: TextStyle(
                              color: _serieColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Text(
              '${serie.alvo} reps',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.labelSecondary,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          SizedBox(
            width: 72,
            child: Text(
              RegExp(r'^\d+$').hasMatch(serie.descanso.trim())
                  ? '${serie.descanso}s'
                  : serie.descanso,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.labelSecondary,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
