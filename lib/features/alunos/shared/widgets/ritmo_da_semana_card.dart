import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'dart:math' as math;

class RitmoDaSemanaCard extends StatelessWidget {
  final String alunoNome;
  final List<DateTime>? diasTreinados;
  final bool isAlunoView;

  const RitmoDaSemanaCard({
    super.key,
    required this.alunoNome,
    this.diasTreinados,
    this.isAlunoView = false,
  });

  @override
  Widget build(BuildContext context) {
    const diasSemana = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM'];
    final hoje = DateTime.now();
    final diaSemanaAtual = hoje.weekday;
    final totalTreinados = diasTreinados?.length ?? 0;
    final primeiroNome = alunoNome.split(' ').first;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12), // Ajustando para um equilíbrio melhor
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final weekday = index + 1;
              final bool isFeito = diasTreinados?.any((dt) => dt.weekday == weekday) ?? false;
              final bool isHoje = weekday == diaSemanaAtual;

              return Expanded(
                child: Column(
                  children: [
                    // Label Superior (Visibilidade Aumentada)
                    Text(
                      diasSemana[index],
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.0,
                        fontWeight: isHoje ? FontWeight.w900 : FontWeight.w600,
                        color: isHoje
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Ring de Performance (Contraste Técnico)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Gauge / Anel
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeOutCubic,
                            tween: Tween<double>(begin: 0, end: isFeito ? 1.0 : 0.0),
                            builder: (context, value, child) {
                              return CustomPaint(
                                painter: RingPainter(
                                  progress: value,
                                  color: AppColors.primary,
                                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                                  isHoje: isHoje,
                                ),
                              );
                            },
                          ),
                          ),                        // Core do Gauge (Mais definido)
                        if (isFeito)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            ),
                          )
                        else if (isHoje)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
        // Narrativa Técnica (Sem fundo, integrada à profundidade)
        Text(
          totalTreinados > 0
              ? '${primeiroNome.toUpperCase()} TREINOU $totalTreinados DIAS ESSA SEMANA'
              : '${primeiroNome.toUpperCase()} NÃO TREINOU ESSA SEMANA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35), // Leve redução para integrar melhor
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final bool isHoje;

  RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.isHoje = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 2.2; // Aumentado de 1.8 para 2.2 para definição

    // 1. Slot de Fundo (Visibilidade de Hardware)
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // 2. Anel de Atividade
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color.withValues(alpha: 0.9) // Mais sólido
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final shadowPaint = Paint()
        ..color = color.withValues(alpha: 0.2) // Mais vibrante
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, shadowPaint);
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
    }

    // 3. Indicador de "Foco" para o dia atual (Mais nítido)
    if (isHoje) {
      final focusPaint = Paint()
        ..color = (progress >= 1.0 ? color : Colors.white).withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius - strokeWidth - 5, focusPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isHoje != isHoje;
  }
}