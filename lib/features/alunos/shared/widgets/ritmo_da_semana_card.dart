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
        const SizedBox(height: SpacingTokens.labelToField),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.premiumCardDecoration,
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
                          fontWeight: FontWeight.w900,
                          color: isFeito
                              ? AppColors.primary
                              : AppColors.labelSecondary.withAlpha(120),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isFeito
                              ? AppColors.primary
                              : AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isFeito 
                                ? AppColors.primary 
                                : Colors.white.withAlpha(10),
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: isFeito
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.black,
                                  size: 20,
                                )
                              : Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.labelSecondary.withAlpha(40),
                                    borderRadius: BorderRadius.circular(2),
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
                            : '$primeiroNome AINDA NÃO TREINOU ESTA SEMANA')
                      : (isAlunoView
                            ? 'VOCÊ TREINOU $count $diaSingularPlural ESTA SEMANA'
                            : '$primeiroNome TREINOU $count $diaSingularPlural ESTA SEMANA');

                  return Text(
                    textoResumo,
                    style: AppTheme.premiumLabel.copyWith(
                      color: dias.hasAnyFeito ? AppColors.primary : AppColors.labelSecondary,
                      fontSize: 9,
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

// Auxiliar para detectar se houve algum treino
extension _ListTreinos on List<Map<String, String>> {
  bool get hasAnyFeito => any((d) => d['status'] == 'feito');
}