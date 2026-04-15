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
    final diasTreinados = _extrairDiasTreinados(logs);

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

          // ── Calendário mensal ──────────────────────────────────────────
          Text('Frequência mensal', style: AppTheme.sectionHeader),
          const SizedBox(height: SpacingTokens.labelToField),
          _CalendarioFrequenciaCard(diasTreinados: diasTreinados),
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

  // ── Dias treinados (Set de datas normalizadas) ───────────────────────────

  Set<DateTime> _extrairDiasTreinados(List<Map<String, dynamic>> logs) {
    return logs
        .map((l) {
          final ts = l['dataHora'] as Timestamp?;
          final dt = ts?.toDate();
          if (dt == null) return null;
          return DateTime(dt.year, dt.month, dt.day);
        })
        .whereType<DateTime>()
        .toSet();
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
// Calendário mensal de frequência
// ─────────────────────────────────────────────────────────────────────────────

class _CalendarioFrequenciaCard extends StatefulWidget {
  final Set<DateTime> diasTreinados;
  const _CalendarioFrequenciaCard({required this.diasTreinados});

  @override
  State<_CalendarioFrequenciaCard> createState() =>
      _CalendarioFrequenciaCardState();
}

class _CalendarioFrequenciaCardState
    extends State<_CalendarioFrequenciaCard> {
  late DateTime _mesAtual;

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    _mesAtual = DateTime(hoje.year, hoje.month);
  }

  void _irParaMesAnterior() {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month - 1);
    });
  }

  void _irParaProximoMes() {
    final hoje = DateTime.now();
    final mesHoje = DateTime(hoje.year, hoje.month);
    if (_mesAtual.isBefore(mesHoje)) {
      setState(() {
        _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final mesHoje = DateTime(hoje.year, hoje.month);
    final isUltimoMes = !_mesAtual.isBefore(mesHoje);

    final nomeMes = DateFormat('MMMM yyyy', 'pt_BR').format(_mesAtual);
    final diasNoMes = DateUtils.getDaysInMonth(_mesAtual.year, _mesAtual.month);
    final primeiroDia = DateTime(_mesAtual.year, _mesAtual.month, 1);
    // weekday: 1=seg ... 7=dom → offset para grade começar na segunda
    final offsetInicio = (primeiroDia.weekday - 1) % 7;

    // Treinos neste mês
    final treinosNoMes = widget.diasTreinados
        .where((d) => d.year == _mesAtual.year && d.month == _mesAtual.month)
        .length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho: mês + contagem + navegação ──────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$treinosNoMes',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.labelPrimary,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      treinosNoMes == 1 ? 'treino em $nomeMes' : 'treinos em $nomeMes',
                      style: AppTheme.caption.copyWith(
                        color: AppColors.labelSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Botões de navegação
              _NavButton(
                icon: Icons.chevron_left_rounded,
                onTap: _irParaMesAnterior,
              ),
              const SizedBox(width: 4),
              _NavButton(
                icon: Icons.chevron_right_rounded,
                onTap: isUltimoMes ? null : _irParaProximoMes,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Labels dos dias da semana ───────────────────────────────────
          Row(
            children: const ['S', 'T', 'Q', 'Q', 'S', 'S', 'D']
                .map(
                  (d) => Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.labelTertiary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          // ── Grade de dias ───────────────────────────────────────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: offsetInicio + diasNoMes,
            itemBuilder: (context, index) {
              if (index < offsetInicio) return const SizedBox.shrink();

              final dia = index - offsetInicio + 1;
              final data = DateTime(_mesAtual.year, _mesAtual.month, dia);
              final treinado = widget.diasTreinados.contains(data);
              final ehHoje = data.year == hoje.year &&
                  data.month == hoje.month &&
                  data.day == hoje.day;
              final futuro = data.isAfter(hoje);

              return _DiaCelula(
                dia: dia,
                treinado: treinado,
                ehHoje: ehHoje,
                futuro: futuro,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ativo = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        ),
        child: Icon(
          icon,
          size: 18,
          color: ativo ? AppColors.labelPrimary : AppColors.labelTertiary,
        ),
      ),
    );
  }
}

class _DiaCelula extends StatelessWidget {
  final int dia;
  final bool treinado;
  final bool ehHoje;
  final bool futuro;

  const _DiaCelula({
    required this.dia,
    required this.treinado,
    required this.ehHoje,
    required this.futuro,
  });

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color textColor;
    FontWeight fontWeight;
    BoxBorder? border;

    if (treinado) {
      bgColor = AppColors.primary;
      textColor = Colors.black;
      fontWeight = FontWeight.w700;
    } else if (ehHoje) {
      bgColor = Colors.transparent;
      textColor = AppColors.primary;
      fontWeight = FontWeight.w700;
      border = Border.all(color: AppColors.primary, width: 1.5);
    } else if (futuro) {
      bgColor = Colors.transparent;
      textColor = AppColors.labelTertiary;
      fontWeight = FontWeight.w400;
    } else {
      bgColor = Colors.transparent;
      textColor = AppColors.labelSecondary;
      fontWeight = FontWeight.w400;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: border,
      ),
      alignment: Alignment.center,
      child: Text(
        '$dia',
        style: TextStyle(
          fontSize: 12,
          fontWeight: fontWeight,
          color: textColor,
          letterSpacing: -0.2,
          height: 1,
        ),
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
