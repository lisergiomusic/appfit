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
import '../../../../core/services/treino_service.dart';
import '../../shared/models/historico_treino_model.dart';
import 'aluno_executar_treino_page.dart';

class AlunoSessaoDetalhePage extends StatefulWidget {
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

  @override
  State<AlunoSessaoDetalhePage> createState() => _AlunoSessaoDetalhePageState();
}

class _AlunoSessaoDetalhePageState extends State<AlunoSessaoDetalhePage> {
  final TreinoService _treinoService = TreinoService();
  Map<String, List<SerieHistorico>> _historico = {};
  List<bool> _expandedStates = [];

  @override
  void initState() {
    super.initState();
    _expandedStates = List.generate(widget.sessao.exercicios.length, (_) => false);
    _carregarHistorico();
  }

  void _toggleAll(bool expand) {
    setState(() {
      _expandedStates = List.generate(widget.sessao.exercicios.length, (_) => expand);
    });
  }

  Future<void> _carregarHistorico() async {
    try {
      final h = await _treinoService.fetchUltimoHistoricoSessao(
        alunoId: widget.alunoId,
        sessaoNome: widget.sessao.nome,
      );
      if (mounted) {
        setState(() {
          _historico = h;
        });
      }
    } catch (_) {
    }
  }

  List<String> _obterGruposUnicos() {
    final grupos = <String>{};
    for (final exercicio in widget.sessao.exercicios) {
      grupos.addAll(exercicio.grupoMuscular);
    }
    return grupos.toList();
  }

  int _calcularTotalSeries() {
    return widget.sessao.exercicios.fold(0, (sum, e) => sum + e.series.length);
  }

  static const int _kSecondsPerRep = 4;
  static const int _kTransitionSeconds = 120;

  static int _parseDurationString(String value) {
    final v = value.trim().toLowerCase();
    final mMatch = RegExp(r'^(\d+)m$').firstMatch(v);
    if (mMatch != null) return int.parse(mMatch.group(1)!) * 60;
    final sMatch = RegExp(r'^(\d+)s$').firstMatch(v);
    if (sMatch != null) return int.parse(sMatch.group(1)!);
    final msMatch = RegExp(r'^(\d+)m(\d+)s$').firstMatch(v);
    if (msMatch != null) {
      return int.parse(msMatch.group(1)!) * 60 + int.parse(msMatch.group(2)!);
    }
    final plainNumber = RegExp(r'^(\d+)$').firstMatch(v);
    if (plainNumber != null) return int.parse(plainNumber.group(1)!);
    return 0;
  }

  String _calcularTempoEstimado() {
    int totalSegundos = 0;
    for (final exercicio in widget.sessao.exercicios) {
      // Tempo de transição entre exercícios
      totalSegundos += _kTransitionSeconds;

      for (final serie in exercicio.series) {
        // Tempo de execução (Reps * 4s ou Tempo direto)
        final execTime = exercicio.tipoAlvo == 'Tempo'
            ? _parseDurationString(serie.alvo)
            : (int.tryParse(serie.alvo) ?? 0) * _kSecondsPerRep;

        // Tempo de descanso
        final restTime = _parseDurationString(serie.descanso);

        totalSegundos += execTime + restTime;
      }
    }

    final d = Duration(seconds: totalSegundos);
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Future<void> _confirmarIniciarSessao(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text('Iniciar sessão', style: AppTheme.title1),
        content: Text(
          'Pronto para treinar? Você vai executar a sessão "${widget.sessao.nome}" e o tempo de treino começará a contar imediatamente.',
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
            sessao: widget.sessao,
            rotinaId: widget.rotinaId,
            alunoId: widget.alunoId,
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
            title: widget.sessao.nome,
            expandedHeight: 160,
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
                    Text(widget.sessao.nome, style: AppTheme.bigTitle),
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
                          value: '${widget.sessao.exercicios.length}',
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
                    text: widget.sessao.orientacoes,
                    label: 'Instruções do personal',
                    addLabel: '',
                    readOnly: true,
                    showInsetShadow: true,
                  ),
                  if (widget.sessao.orientacoes != null &&
                      widget.sessao.orientacoes!.trim().isNotEmpty)
                    const SizedBox(height: SpacingTokens.sectionGap),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Exercícios', style: AppTheme.sectionHeader),
                      GestureDetector(
                        onTap: () {
                          final allExpanded = _expandedStates.every((e) => e);
                          _toggleAll(!allExpanded);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _expandedStates.every((e) => e)
                                    ? Icons.unfold_less_rounded
                                    : Icons.unfold_more_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _expandedStates.every((e) => e) ? 'Recolher' : 'Expandir',
                                style: AppTheme.sectionAction,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.labelToField),
                  ...List.generate(
                    widget.sessao.exercicios.length,
                    (exIndex) {
                      final ex = widget.sessao.exercicios[exIndex];
                      return _ExercicioCard(
                        exercicio: ex,
                        alunoId: widget.alunoId,
                        historico: _historico[ex.nome] ?? [],
                        isExpanded: _expandedStates[exIndex],
                        onToggle: () {
                          setState(() {
                            _expandedStates[exIndex] = !_expandedStates[exIndex];
                          });
                        },
                      );
                    },
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
  final List<SerieHistorico> historico;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _ExercicioCard({
    required this.exercicio,
    required this.alunoId,
    required this.historico,
    required this.isExpanded,
    required this.onToggle,
  });

  int _calcWorkIndex(int upToIdx) {
    int count = 0;
    for (int i = 0; i <= upToIdx; i++) {
      if (exercicio.series[i].tipo == TipoSerie.trabalho) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    // Cálculo do descanso padrão
    exercicio.series.map((s) => s.descanso.trim()).toSet();

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
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              child: ExercicioSectionHeader(
                exercicio: exercicio,
                exIdx: 0,
                alunoId: alunoId,
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.labelSecondary.withAlpha(150),
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  ..._buildSetsWithContextualRest(exercicio, historico),
                  const SizedBox(height: SpacingTokens.xs),
                ],
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSetsWithContextualRest(ExercicioItem exercicio, List<SerieHistorico> historico) {
    final List<Widget> widgets = [];
    final rests = exercicio.series.map((s) => s.descanso.trim()).toSet();
    final isUniformRest = rests.length == 1;
    final standardRestOverall = rests.isNotEmpty ? rests.first : '60s';

    // Identifica se o exercício tem múltiplos tipos de série para decidir se mostra o rótulo (Trabalho/Aquecimento)
    final types = exercicio.series.map((s) => s.tipo).toSet();
    final hasMultipleTypes = types.length > 1;

    for (int i = 0; i < exercicio.series.length; i++) {
      final serie = exercicio.series[i];
      final indexDentroDoTipo = exercicio.series.take(i).where((s) => s.tipo == serie.tipo).length;

      final historicoSerie = historico.firstWhere(
        (h) => h.tipo == serie.tipo && h.indexDentroDoTipo == indexDentroDoTipo,
        orElse: () => SerieHistorico(tipo: serie.tipo, indexDentroDoTipo: indexDentroDoTipo),
      );

      widgets.add(
        _ReadOnlySetRow(
          serie: serie,
          visualIndex: _calcWorkIndex(i),
          historico: historicoSerie,
          isSpecialRest: !isUniformRest && serie.descanso.trim() != standardRestOverall,
        ),
      );

      // Lógica de Bloco: Verifica se a próxima série é de tipo diferente ou se é a última
      final bool isLastOfBlock = (i == exercicio.series.length - 1) || (exercicio.series[i + 1].tipo != serie.tipo);

      if (isLastOfBlock) {
        final bool isLastOverall = i == exercicio.series.length - 1;
        widgets.add(_buildBlockRestFooter(
          serie.descanso,
          isLastOverall,
          hasMultipleTypes ? (serie.tipo == TipoSerie.aquecimento ? "Aquecimento" : "Trabalho") : null,
        ));
      }
    }

    return widgets;
  }

  Widget _buildBlockRestFooter(String rest, bool isLastOverall, String? label) {
    final cleanRest = RegExp(r'^\d+$').hasMatch(rest) ? '${rest}s' : rest;
    final textLabel = label != null ? 'Descanso ($label): $cleanRest' : 'Descanso: $cleanRest';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: isLastOverall
              ? Border(
                  top: BorderSide(
                    color: AppColors.labelPrimary.withAlpha(20),
                    width: 0.5,
                  ),
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 14,
              color: AppColors.labelSecondary.withAlpha(isLastOverall ? 180 : 120),
            ),
            const SizedBox(width: 6),
            Text(
              textLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isLastOverall ? FontWeight.w600 : FontWeight.w400,
                color: AppColors.labelSecondary.withAlpha(isLastOverall ? 180 : 120),
                letterSpacing: 0.2,
              ),
            ),
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
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: AppColors.labelSecondary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.screenHorizontalPadding,
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 32,
            child: Text(
              'SÉRIE',
              style: labelStyle,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Text('REPETIÇÕES', style: labelStyle, textAlign: TextAlign.center),
          ),
          const SizedBox(width: SpacingTokens.md),
          SizedBox(
            width: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'KG',
                  style: labelStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surfaceDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                        ),
                        title: const Text(
                          'Carga de Referência',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        content: const Text(
                          'Este valor mostra a carga planejada pelo seu personal ou o seu último peso registrado.\n\nO ícone ↗️ indica que seu personal aumentou o desafio para este treino!',
                          style: TextStyle(
                            color: AppColors.labelSecondary,
                            fontSize: 14,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Entendi',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 11,
                    color: AppColors.labelSecondary.withAlpha(120),
                  ),
                ),
              ],
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
  final SerieHistorico historico;
  final bool isSpecialRest;

  const _ReadOnlySetRow({
    required this.serie,
    required this.visualIndex,
    required this.historico,
    this.isSpecialRest = false,
  });

  SerieTypeOption get _serieOption => serieTypeOptions.firstWhere(
    (opt) => opt.type == serie.tipo,
    orElse: () => serieTypeOptions.last,
  );

  Color get _serieColor => _serieOption.color;

  IconData? get _badgeIcon =>
      serie.tipo != TipoSerie.trabalho ? _serieOption.icon : null;

  @override
    Widget build(BuildContext context) {
    // Lógica de Carga Inteligente (Personal vs Histórico)
    final cargaPersonal = double.tryParse(serie.carga) ?? 0;
    final double cargaAnterior = (historico.pesoRealizado as num?)?.toDouble() ?? 0;

    String valorParaExibir;
    Color corValor = AppColors.labelPrimary;
    Widget? trailingIcon;

    if (cargaPersonal > 0) {
      // Prioridade: Personal definiu uma meta
      valorParaExibir = '${serie.carga}kg';

      if (cargaAnterior > 0 && cargaPersonal > cargaAnterior) {
        // Progressão detectada! Personal aumentou a carga
        trailingIcon = const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Icon(
            Icons.trending_up_rounded,
            size: 14,
            color: Colors.greenAccent,
          ),
        );
      }
    } else {
      // Fallback: Mostrar histórico se o personal não estipulou nada
      valorParaExibir = cargaAnterior > 0 ? '${cargaAnterior.toStringAsFixed(0)}kg' : '—';
      if (cargaAnterior == 0) corValor = AppColors.labelSecondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.screenHorizontalPadding,
        vertical: 4,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => showSerieBadgeInfo(context, serie.tipo),
            child: SizedBox.square(
              dimension: 32,
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _serieColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: _badgeIcon != null
                        ? Icon(_badgeIcon, size: 14, color: _serieColor)
                        : Text(
                            visualIndex.toString(),
                            style: TextStyle(
                              color: _serieColor,
                              fontSize: 12,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  serie.alvo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.labelPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (isSpecialRest) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Descanso especial: ${serie.descanso}',
                    child: const Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          SizedBox(
            width: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  valorParaExibir,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: corValor,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                ?trailingIcon,
              ],
            ),
          ),
        ],
      ),
    );
  }
}