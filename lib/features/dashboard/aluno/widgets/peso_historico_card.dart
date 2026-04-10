import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';

class PesoHistoricoCard extends StatelessWidget {
  final double? pesoAtual;
  final List<Map<String, dynamic>>? historico;
  final VoidCallback onAdicionarPeso;

  const PesoHistoricoCard({
    super.key,
    this.pesoAtual,
    this.historico,
    required this.onAdicionarPeso,
  });

  @override
  Widget build(BuildContext context) {
    if (historico == null) return _buildLoadingState();
    if (historico!.isEmpty || pesoAtual == null) return _buildEmptyState();

    final sorted = historico!
        .take(8)
        .map(
          (doc) => (
            peso: (doc['peso'] as num).toDouble(),
            data: (doc['dataHora'] as Timestamp).toDate(),
          ),
        )
        .toList()
        .reversed
        .toList();

    final pesos = sorted.map((e) => e.peso).toList();
    final datas = sorted.map((e) => e.data).toList();

    final pesoAtualVal = pesos.last;
    final pesoAnterior = pesos.length > 1
        ? pesos[pesos.length - 2]
        : pesos.last;
    final diferenca = pesoAtualVal - pesoAnterior;

    final pesoMin = pesos.reduce(math.min);
    final pesoMax = pesos.reduce(math.max);

    final dataPrimeira = DateFormat("d 'de' MMM", 'pt_BR').format(datas.first);
    final dataUltima = DateFormat("d 'de' MMM", 'pt_BR').format(datas.last);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Peso corporal', style: AppTheme.sectionHeader),
        const SizedBox(height: SpacingTokens.labelToField),
        Container(
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top section: weight + trend + action button
              Padding(
                padding: CardTokens.padding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                pesoAtualVal.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1.5,
                                  height: 1,
                                  color: AppColors.labelPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'kg',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.labelSecondary,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _TrendBadge(diferenca: diferenca),
                        ],
                      ),
                    ),
                    // Right column: mini stats + add button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _MiniStat(
                          label: 'Mínimo',
                          value: '${pesoMin.toStringAsFixed(1)} kg',
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        _MiniStat(
                          label: 'Máximo',
                          value: '${pesoMax.toStringAsFixed(1)} kg',
                          color: AppColors.iosBlue,
                        ),
                        const SizedBox(height: 8),
                        _MiniStat(
                          label: 'Registros',
                          value: '${historico!.length}',
                          color: AppColors.labelSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Chart area
              SizedBox(
                height: 80,
                child: CustomPaint(
                  painter: _AreaChartPainter(
                    pesos: pesos,
                    color: AppColors.primary,
                  ),
                  size: Size.infinite,
                ),
              ),

              // Bottom: bar chart + date range + button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    _BarMiniChart(pesos: pesos),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dataPrimeira,
                          style: AppTheme.caption2.copyWith(
                            color: AppColors.labelSecondary.withAlpha(120),
                          ),
                        ),
                        Text(
                          dataUltima,
                          style: AppTheme.caption2.copyWith(
                            color: AppColors.labelSecondary.withAlpha(120),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _AddButton(onTap: onAdicionarPeso),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Peso corporal', style: AppTheme.sectionHeader),
        const SizedBox(height: SpacingTokens.labelToField),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          ),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.monitor_weight_outlined,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Nenhum registro ainda', style: AppTheme.cardTitle),
              const SizedBox(height: 4),
              Text(
                'Comece agora e acompanhe\nsua evolução ao longo do tempo',
                style: AppTheme.caption.copyWith(
                  color: AppColors.labelSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onAdicionarPeso,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.black, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Registrar peso',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Peso corporal', style: AppTheme.sectionHeader),
        const SizedBox(height: SpacingTokens.labelToField),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          ),
          padding: CardTokens.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBox(width: 130, height: 48),
              const SizedBox(height: 8),
              _shimmerBox(width: 80, height: 22),
              const SizedBox(height: 20),
              _shimmerBox(width: double.infinity, height: 80),
              const SizedBox(height: 12),
              _shimmerBox(width: double.infinity, height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shimmerBox({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceDark,
      highlightColor: AppColors.surfaceLight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.fillSecondary,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        ),
      ),
    );
  }
}

// ─── Add button ──────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(22),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: AppColors.primary, size: 16),
            SizedBox(width: 5),
            Text(
              'Registrar peso',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Trend badge ─────────────────────────────────────────────────────────────

class _TrendBadge extends StatelessWidget {
  final double diferenca;

  const _TrendBadge({required this.diferenca});

  @override
  Widget build(BuildContext context) {
    final bool stable = diferenca.abs() < 0.1;
    final bool up = diferenca > 0;

    final Color cor = stable
        ? AppColors.labelSecondary.withAlpha(130)
        : AppColors.iosBlue;

    final IconData icon = stable
        ? Icons.remove_rounded
        : up
        ? Icons.keyboard_arrow_up_rounded
        : Icons.keyboard_arrow_down_rounded;

    final String label = stable
        ? 'Estável'
        : '${up ? '+' : ''}${diferenca.toStringAsFixed(1)} kg';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withAlpha(22),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: cor.withAlpha(40), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cor, size: 13),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cor,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mini stat label/value ────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.labelSecondary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Smooth area chart ────────────────────────────────────────────────────────

class _AreaChartPainter extends CustomPainter {
  final List<double> pesos;
  final Color color;

  _AreaChartPainter({required this.pesos, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (pesos.isEmpty) return;

    final min = pesos.reduce(math.min);
    final max = pesos.reduce(math.max);
    final range = (max - min) > 0 ? (max - min) : 1.0;

    // Extra vertical padding so the line is never clipped
    const vPad = 10.0;
    final usableH = size.height - vPad * 2;

    List<Offset> points = [];
    for (int i = 0; i < pesos.length; i++) {
      final x = pesos.length == 1
          ? size.width / 2
          : (i / (pesos.length - 1)) * size.width;
      final normalized = (pesos[i] - min) / range;
      final y = vPad + usableH - (normalized * usableH * 0.85);
      points.add(Offset(x, y));
    }

    // Gradient fill
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    _addCatmullRom(fillPath, points);
    fillPath
      ..lineTo(points.last.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withAlpha(55), color.withAlpha(0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    _addCatmullRom(linePath, points);

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // Dots — only first and last
    _drawDot(canvas, points.first, color, small: true);
    _drawDot(canvas, points.last, color, small: false);
  }

  void _drawDot(
    Canvas canvas,
    Offset point,
    Color color, {
    required bool small,
  }) {
    final radius = small ? 2.5 : 4.5;
    canvas.drawCircle(point, radius, Paint()..color = color);
    if (!small) {
      canvas.drawCircle(
        point,
        radius,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _addCatmullRom(Path path, List<Offset> pts) {
    if (pts.length < 2) return;
    for (int i = 1; i < pts.length; i++) {
      final p0 = pts[math.max(0, i - 2)];
      final p1 = pts[i - 1];
      final p2 = pts[i];
      final p3 = pts[math.min(pts.length - 1, i + 1)];

      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
  }

  @override
  bool shouldRepaint(_AreaChartPainter old) =>
      old.pesos != pesos || old.color != color;
}

// ─── Vertical bar mini-chart ──────────────────────────────────────────────────

class _BarMiniChart extends StatelessWidget {
  final List<double> pesos;

  const _BarMiniChart({required this.pesos});

  @override
  Widget build(BuildContext context) {
    if (pesos.isEmpty) return const SizedBox.shrink();

    final min = pesos.reduce(math.min);
    final max = pesos.reduce(math.max);
    final range = (max - min) > 0 ? (max - min) : 1.0;

    return SizedBox(
      height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(pesos.length, (i) {
          final normalized = (pesos[i] - min) / range;
          final heightFraction = 0.15 + normalized * 0.85;
          final isLast = i == pesos.length - 1;
          final isMax = pesos[i] == max;

          Color barColor;
          if (isLast) {
            barColor = AppColors.primary;
          } else if (isMax) {
            barColor = AppColors.iosBlue.withAlpha(180);
          } else {
            barColor = AppColors.labelSecondary.withAlpha(50);
          }

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: FractionallySizedBox(
                alignment: Alignment.bottomCenter,
                heightFactor: heightFraction,
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
