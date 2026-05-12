import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

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
    final String primeiroNome = alunoNome.split(' ').first;
    const diasSemana = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

    final dias = <Map<String, String>>[];
    for (int i = 0; i < 7; i++) {
      final weekday = i + 1;
      bool feito = false;

      if (diasTreinados != null) {
        feito = diasTreinados!.any((dt) => dt.weekday == weekday);
      }

      dias.add({
        'dia': diasSemana[i],
        'status': diasTreinados == null
            ? 'carregando'
            : (feito ? 'feito' : 'futuro'),
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RITMO DA SEMANA', style: AppTheme.sectionHeader),
        const SizedBox(height: SpacingTokens.lg),
        Container(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: dias.map((d) {
                  final isFeito = d['status'] == 'feito';

                  return Column(
                    children: [
                      Text(
                        d['dia']!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isFeito
                              ? AppColors.primary
                              : AppColors.labelSecondary.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isFeito
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.03),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isFeito 
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.05),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: isFeito
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                )
                              : Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  if (diasTreinados == null) {
                    return const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    );
                  }

                  final int count = dias
                      .where((d) => d['status'] == 'feito')
                      .length;

                  final String diaSingularPlural = count == 1 ? 'DIA' : 'DIAS';

                  final String textoResumo = count == 0
                      ? (isAlunoView
                            ? 'VOCÊ AINDA NÃO TREINOU ESTA SEMANA'
                            : '${primeiroNome.toUpperCase()} AINDA NÃO TREINOU ESTA SEMANA')
                      : (isAlunoView
                            ? 'VOCÊ TREINOU $count $diaSingularPlural ESTA SEMANA'
                            : '${primeiroNome.toUpperCase()} TREINOU $count $diaSingularPlural ESTA SEMANA');

                  return Center(
                    child: Text(
                      textoResumo,
                      textAlign: TextAlign.center,
                      style: AppTheme.premiumLabel.copyWith(
                        color: AppColors.labelSecondary.withValues(alpha: 0.6),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}