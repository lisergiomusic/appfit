import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/treino_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bar_divider.dart';

class AlunoHistoricoPage extends StatefulWidget {
  final String uid;
  const AlunoHistoricoPage({super.key, required this.uid});

  @override
  State<AlunoHistoricoPage> createState() => _AlunoHistoricoPageState();
}

class _AlunoHistoricoPageState extends State<AlunoHistoricoPage> {
  final TreinoService _service = TreinoService();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _logs = [];
  DocumentSnapshot? _ultimoDoc;

  bool _carregandoInicial = true;
  bool _carregandoMais = false;
  bool _temMais = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarPrimeiraPagina();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Dispara quando faltam 200px para o fim da lista
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _carregarMais();
    }
  }

  Future<void> _carregarPrimeiraPagina() async {
    try {
      final resultado = await _service.fetchLogsAlunoPage(widget.uid);
      if (!mounted) return;
      setState(() {
        _logs.addAll(resultado.logs);
        _ultimoDoc = resultado.ultimoDoc;
        _temMais = resultado.logs.length == TreinoService.logsPorPagina;
        _carregandoInicial = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro ao carregar histórico.';
        _carregandoInicial = false;
      });
    }
  }

  Future<void> _carregarMais() async {
    if (_carregandoMais || !_temMais || _ultimoDoc == null) return;

    setState(() => _carregandoMais = true);

    try {
      final resultado = await _service.fetchLogsAlunoPage(
        widget.uid,
        aposDoc: _ultimoDoc,
      );
      if (!mounted) return;
      setState(() {
        _logs.addAll(resultado.logs);
        _ultimoDoc = resultado.ultimoDoc;
        _temMais = resultado.logs.length == TreinoService.logsPorPagina;
        _carregandoMais = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregandoMais = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('Histórico'),
        bottom: const AppBarDivider(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_carregandoInicial) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_erro != null) {
      return Center(
        child: Text(
          _erro!,
          style: const TextStyle(color: AppColors.labelSecondary),
        ),
      );
    }

    if (_logs.isEmpty) {
      return _buildEmptyState();
    }

    return _HistoricoContent(
      logs: _logs,
      scrollController: _scrollController,
      carregandoMais: _carregandoMais,
      temMais: _temMais,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.screenHorizontalPadding,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                size: 40,
                color: AppColors.labelTertiary,
              ),
            ),
            const SizedBox(height: SpacingTokens.lg),
            const Text(
              'Nenhum treino registrado',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.labelPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            const Text(
              'Complete seu primeiro treino para\nver seu progresso aqui.',
              style: AppTheme.cardSubtitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conteúdo principal quando há dados
// ─────────────────────────────────────────────────────────────────────────────

class _HistoricoContent extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  final ScrollController scrollController;
  final bool carregandoMais;
  final bool temMais;

  const _HistoricoContent({
    required this.logs,
    required this.scrollController,
    required this.carregandoMais,
    required this.temMais,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _calcularStats(logs);
    final semanas = _agruparPorSemana(logs);
    final frequenciaSemanal = _frequenciaUltimas8Semanas(logs);

    return SingleChildScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.screenHorizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SpacingTokens.lg),

          // ── Cards de métricas ──────────────────────────────────────────
          _MetricsRow(stats: stats),
          const SizedBox(height: SpacingTokens.xxl),

          // ── Gráfico de frequência ──────────────────────────────────────
          Text('Frequência semanal', style: AppTheme.sectionHeader),
          const SizedBox(height: SpacingTokens.labelToField),
          _FrequenciaCard(frequencia: frequenciaSemanal),
          const SizedBox(height: SpacingTokens.xxl),

          // ── Lista de treinos agrupada por semana ───────────────────────
          Text('Treinos realizados', style: AppTheme.sectionHeader),
          const SizedBox(height: SpacingTokens.labelToField),
          ...semanas.entries.map(
            (entry) => _SemanaGroup(
              semanaLabel: entry.key,
              logs: entry.value,
            ),
          ),

          // ── Indicador de carregamento ao fundo ─────────────────────────
          if (carregandoMais)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: SpacingTokens.xxl),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else if (!temMais && logs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xxl),
              child: Center(
                child: Text(
                  'Você chegou ao início do histórico',
                  style: AppTheme.caption.copyWith(
                    color: AppColors.labelTertiary,
                  ),
                ),
              ),
            ),

          const SizedBox(height: SpacingTokens.screenBottomPadding),
        ],
      ),
    );
  }

  // ── Estatísticas agregadas ───────────────────────────────────────────────

  Map<String, dynamic> _calcularStats(List<Map<String, dynamic>> logs) {
    final total = logs.length;

    // Streak: dias consecutivos com pelo menos 1 treino
    final diasComTreino = logs
        .map((l) {
          final ts = l['dataHora'] as Timestamp?;
          final dt = ts?.toDate();
          if (dt == null) return null;
          return DateTime(dt.year, dt.month, dt.day);
        })
        .whereType<DateTime>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    if (diasComTreino.isNotEmpty) {
      final hoje = DateTime.now();
      final hojeDay = DateTime(hoje.year, hoje.month, hoje.day);
      DateTime cursor = diasComTreino.first;

      // Aceita streak se o último treino foi hoje ou ontem
      if (hojeDay.difference(cursor).inDays <= 1) {
        streak = 1;
        for (int i = 1; i < diasComTreino.length; i++) {
          final diff = cursor.difference(diasComTreino[i]).inDays;
          if (diff == 1) {
            streak++;
            cursor = diasComTreino[i];
          } else {
            break;
          }
        }
      }
    }

    // Treinos neste mês
    final agora = DateTime.now();
    final treinos30d = logs.where((l) {
      final ts = l['dataHora'] as Timestamp?;
      final dt = ts?.toDate();
      if (dt == null) return false;
      return agora.difference(dt).inDays <= 30;
    }).length;

    // Total de séries realizadas
    int totalSeries = 0;
    for (final log in logs) {
      final exercicios = log['exercicios'] as List? ?? [];
      for (final ex in exercicios) {
        final series = ex['series'] as List? ?? [];
        totalSeries += series.where((s) => s['concluida'] == true).length;
      }
    }

    return {
      'total': total,
      'streak': streak,
      'treinos30d': treinos30d,
      'totalSeries': totalSeries,
    };
  }

  // ── Agrupa logs por semana (label "dd MMM – dd MMM") ────────────────────

  Map<String, List<Map<String, dynamic>>> _agruparPorSemana(
    List<Map<String, dynamic>> logs,
  ) {
    final Map<String, List<Map<String, dynamic>>> grupos = {};

    for (final log in logs) {
      final ts = log['dataHora'] as Timestamp?;
      final dt = ts?.toDate();
      if (dt == null) continue;

      final inicio = dt.subtract(Duration(days: dt.weekday - 1));
      final fim = inicio.add(const Duration(days: 6));
      final label =
          '${DateFormat('dd MMM', 'pt_BR').format(inicio)} – ${DateFormat('dd MMM', 'pt_BR').format(fim)}';

      grupos.putIfAbsent(label, () => []).add(log);
    }

    return grupos;
  }

  // ── Frequência das últimas 8 semanas (treinos/semana) ───────────────────

  List<_SemanaFrequencia> _frequenciaUltimas8Semanas(
    List<Map<String, dynamic>> logs,
  ) {
    final agora = DateTime.now();
    final List<_SemanaFrequencia> resultado = [];

    for (int i = 7; i >= 0; i--) {
      final inicioSemana = agora.subtract(Duration(days: agora.weekday - 1 + i * 7));
      final inicio = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);
      final fim = inicio.add(const Duration(days: 6, hours: 23, minutes: 59));

      final count = logs.where((l) {
        final ts = l['dataHora'] as Timestamp?;
        final dt = ts?.toDate();
        if (dt == null) return false;
        return dt.isAfter(inicio.subtract(const Duration(seconds: 1))) &&
            dt.isBefore(fim.add(const Duration(seconds: 1)));
      }).length;

      resultado.add(
        _SemanaFrequencia(
          label: i == 0 ? 'Agora' : '-${i}s',
          count: count,
          inicio: inicio,
        ),
      );
    }

    return resultado;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Linha de métricas (3 cards)
// ─────────────────────────────────────────────────────────────────────────────

class _MetricsRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _MetricsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.accentMetrics,
            value: '${stats['streak']}',
            label: 'Dias seguidos',
          ),
        ),
        const SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: _MetricCard(
            icon: Icons.fitness_center_rounded,
            iconColor: AppColors.primary,
            value: '${stats['treinos30d']}',
            label: 'Últimos 30d',
          ),
        ),
        const SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: _MetricCard(
            icon: Icons.repeat_rounded,
            iconColor: AppColors.iosBlue,
            value: '${stats['total']}',
            label: 'Total treinos',
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.labelPrimary,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.labelSecondary,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card com gráfico de barras de frequência semanal
// ─────────────────────────────────────────────────────────────────────────────

class _SemanaFrequencia {
  final String label;
  final int count;
  final DateTime inicio;
  const _SemanaFrequencia({
    required this.label,
    required this.count,
    required this.inicio,
  });
}

class _FrequenciaCard extends StatelessWidget {
  final List<_SemanaFrequencia> frequencia;
  const _FrequenciaCard({required this.frequencia});

  @override
  Widget build(BuildContext context) {
    final maxCount = frequencia.map((s) => s.count).fold(0, math.max);
    final media = frequencia.isEmpty
        ? 0.0
        : frequencia.map((s) => s.count).reduce((a, b) => a + b) /
              frequencia.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho: média semanal
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                media.round().toString(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.labelPrimary,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  'treinos/semana (média)',
                  style: AppTheme.caption.copyWith(
                    color: AppColors.labelSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Barras
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: frequencia.map((semana) {
                final isAtual = semana.label == 'Agora';
                final ratio = maxCount == 0
                    ? 0.0
                    : semana.count / maxCount;
                final barColor = isAtual
                    ? AppColors.primary
                    : semana.count > 0
                    ? AppColors.primary.withAlpha(80)
                    : AppColors.surfaceLight;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (semana.count > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${semana.count}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isAtual
                                    ? AppColors.primary
                                    : AppColors.labelSecondary,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          height: math.max(4, ratio * 60),
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Labels das semanas
          Row(
            children: frequencia.map((semana) {
              final isAtual = semana.label == 'Agora';
              return Expanded(
                child: Text(
                  semana.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: isAtual
                        ? AppColors.primary
                        : AppColors.labelTertiary,
                    fontWeight: isAtual
                        ? FontWeight.w600
                        : FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grupo de treinos por semana
// ─────────────────────────────────────────────────────────────────────────────

class _SemanaGroup extends StatelessWidget {
  final String semanaLabel;
  final List<Map<String, dynamic>> logs;

  const _SemanaGroup({required this.semanaLabel, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
          child: Text(
            semanaLabel,
            style: AppTheme.caption.copyWith(
              color: AppColors.labelSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: AppTheme.cardDecoration,
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: List.generate(logs.length, (i) {
              final log = logs[i];
              final isLast = i == logs.length - 1;
              return Column(
                children: [
                  _TreinoLogTile(log: log),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: AppColors.labelSecondary.withAlpha(20),
                      indent: 56,
                    ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: SpacingTokens.lg),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile individual de log de treino
// ─────────────────────────────────────────────────────────────────────────────

class _TreinoLogTile extends StatelessWidget {
  final Map<String, dynamic> log;
  const _TreinoLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final sessaoNome = log['sessaoNome'] as String? ?? '—';
    final ts = log['dataHora'] as Timestamp?;
    final dt = ts?.toDate();

    final exercicios = log['exercicios'] as List? ?? [];
    int seriesConcluidas = 0;
    int totalSeries = 0;
    for (final ex in exercicios) {
      final series = ex['series'] as List? ?? [];
      totalSeries += series.length;
      seriesConcluidas +=
          series.where((s) => s['concluida'] == true).length;
    }

    // Letra da sessão (primeira letra do nome)
    final letra = sessaoNome.isNotEmpty ? sessaoNome[0].toUpperCase() : '?';

    final dataFormatada = dt != null
        ? DateFormat("EEE, d 'de' MMM", 'pt_BR').format(dt)
        : '—';
    final horaFormatada = dt != null ? DateFormat('HH:mm').format(dt) : '';

    return InkWell(
      onTap: () => _mostrarDetalhe(context, log),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.cardPaddingH,
          vertical: 12,
        ),
        child: Row(
          children: [
            // Badge da sessão
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              alignment: Alignment.center,
              child: Text(
                letra,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info central
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sessaoNome,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.labelPrimary,
                      letterSpacing: -0.2,
                      height: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$dataFormatada · $horaFormatada',
                    style: AppTheme.caption.copyWith(
                      color: AppColors.labelSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Séries concluídas
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$seriesConcluidas',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.labelPrimary,
                    letterSpacing: -0.3,
                    height: 1,
                  ),
                ),
                Text(
                  totalSeries > 0
                      ? 'de $totalSeries séries'
                      : 'séries',
                  style: AppTheme.caption,
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.labelSecondary.withAlpha(80),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalhe(BuildContext context, Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TreinoDetalheSheet(log: log),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet com detalhe do treino
// ─────────────────────────────────────────────────────────────────────────────

class _TreinoDetalheSheet extends StatelessWidget {
  final Map<String, dynamic> log;
  const _TreinoDetalheSheet({required this.log});

  @override
  Widget build(BuildContext context) {
    final sessaoNome = log['sessaoNome'] as String? ?? '—';
    final ts = log['dataHora'] as Timestamp?;
    final dt = ts?.toDate();
    final exercicios = log['exercicios'] as List? ?? [];

    final dataFormatada = dt != null
        ? DateFormat("EEEE, d 'de' MMMM 'de' yyyy", 'pt_BR').format(dt)
        : '—';
    final horaFormatada = dt != null ? DateFormat('HH:mm').format(dt) : '';

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXXL),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.labelSecondary.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Cabeçalho
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(18),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        sessaoNome.isNotEmpty
                            ? sessaoNome[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sessaoNome,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.labelPrimary,
                              letterSpacing: -0.4,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$dataFormatada · $horaFormatada',
                            style: AppTheme.caption.copyWith(
                              color: AppColors.labelSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.labelSecondary.withAlpha(20),
              ),

              // Lista de exercícios
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  itemCount: exercicios.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: SpacingTokens.sm),
                  itemBuilder: (context, i) {
                    final ex = exercicios[i] as Map<String, dynamic>;
                    return _ExercicioLogCard(exercicio: ex);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de exercício dentro do detalhe
// ─────────────────────────────────────────────────────────────────────────────

class _ExercicioLogCard extends StatelessWidget {
  final Map<String, dynamic> exercicio;
  const _ExercicioLogCard({required this.exercicio});

  @override
  Widget build(BuildContext context) {
    final nome = exercicio['nome'] as String? ?? 'Exercício';
    final series = exercicio['series'] as List? ?? [];

    final concluidas = series.where((s) => s['concluida'] == true).toList();
    final totalSeries = series.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome + badge de conclusão
          Row(
            children: [
              Expanded(
                child: Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.labelPrimary,
                    letterSpacing: -0.2,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: concluidas.length == totalSeries && totalSeries > 0
                      ? AppColors.primary.withAlpha(20)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '${concluidas.length}/$totalSeries séries',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: concluidas.length == totalSeries && totalSeries > 0
                        ? AppColors.primary
                        : AppColors.labelSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),

          if (concluidas.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Tabela de séries concluídas
            Row(
              children: const [
                SizedBox(width: 24),
                Expanded(
                  child: Text(
                    'PESO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.labelTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'REPS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.labelTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...List.generate(concluidas.length, (i) {
              final serie = concluidas[i] as Map<String, dynamic>;
              final peso = serie['pesoRealizado'] as String? ?? '—';
              final reps = serie['repsRealizadas'] as String? ?? '—';
              final tipo = serie['tipo'] as String? ?? 'trabalho';
              final isTrabalho = tipo == 'trabalho';

              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isTrabalho
                              ? AppColors.labelSecondary
                              : AppColors.labelTertiary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        peso.isNotEmpty ? '$peso kg' : '—',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isTrabalho
                              ? AppColors.labelPrimary
                              : AppColors.labelSecondary,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        reps.isNotEmpty ? '$reps reps' : '—',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isTrabalho
                              ? AppColors.labelPrimary
                              : AppColors.labelSecondary,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
