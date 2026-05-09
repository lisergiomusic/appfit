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
        Row(
          children: [
            Text('RITMO DA SEMANA', style: AppTheme.sectionHeader),
            const Spacer(),
          ],
        ),
        const SizedBox(height: SpacingTokens.labelToField),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: dias.map((d) {
                  final isFeito = d['status'] == 'feito';
                  final isFuturo = d['status'] == 'futuro';
                  final isCarregando = d['status'] == 'carregando';

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
                              : AppColors.labelSecondary.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
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

                  final String diaSingularPlural = count == 1 ? 'dia' : 'dias';

                  final String textoResumo = count == 0
                      ? (isAlunoView
                            ? 'Você ainda não treinou esta semana'
                            : '$primeiroNome ainda não treinou esta semana')
                      : (isAlunoView
                            ? 'Você treinou $count $diaSingularPlural esta semana'
                            : '$primeiroNome treinou $count $diaSingularPlural esta semana');

                  return Text(
                    textoResumo.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.labelSecondary.withAlpha(150),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
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