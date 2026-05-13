import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'dart:math' as math;

/// Widget que exibe o engajamento semanal do aluno através de anéis de atividade (Activity Rings).
/// Inspirado em interfaces de alto desempenho como Apple Fitness e Strava.
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
        // Linha de anéis compactada com padding lateral.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final weekday = index + 1;
              final bool isFeito = diasTreinados?.any((dt) => dt.weekday == weekday) ?? false;
              final bool isHoje = weekday == diaSemanaAtual;

              return Expanded(
                child: Column(
                  children: [
                    // Rótulo abreviado do dia da semana.
                    Text(
                      diasSemana[index],
                      style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 1.0,
                        fontWeight: isHoje ? FontWeight.w900 : FontWeight.w600,
                        color: isHoje 
                            ? AppColors.primary 
                            : Colors.white.withValues(alpha: 0.35), 
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.md),
                    // Anel técnico com animação de progresso (0 a 1).
                    Stack(
                      alignment: Alignment.center,
                      children: [
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
                                  backgroundColor: Colors.white.withValues(alpha: GlassTokens.opacityHighBorder),
                                  isHoje: isHoje,
                                ),
                              );
                            },
                          ),
                        ),
                        // Núcleo do anel que indica status de conclusão.
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
        const SizedBox(height: SpacingTokens.xxl),
        // Frase narrativa que resume a performance semanal.
        Text(
          totalTreinados > 0
              ? '${primeiroNome.toUpperCase()} TREINOU $totalTreinados DIAS ESSA SEMANA'
              : '${primeiroNome.toUpperCase()} NÃO TREINOU ESSA SEMANA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35), 
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

/// Desenha um anel de atividade com suporte a gradientes e brilho atmosférico.
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
    const strokeWidth = 2.2; 

    // Desenha o fundo (soquete) do anel.
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Desenha o arco de progresso com efeito de glow se estiver concluído.
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color.withValues(alpha: 0.9) 
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final shadowPaint = Paint()
        ..color = color.withValues(alpha: 0.2) 
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
      
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, shadowPaint);
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
    }

    // Desenha um indicador sutil de foco para o dia atual.
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