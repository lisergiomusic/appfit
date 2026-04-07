import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_section_link_button.dart';

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

    // Map days of week: [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
    const diasSemana = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

    // Derive status from real data or show loading state
    final dias = <Map<String, String>>[];
    for (int i = 0; i < 7; i++) {
      final weekday = i + 1; // Mon = 1, Sun = 7
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
            Text('Ritmo da semana', style: AppTheme.sectionHeader),
            const Spacer(),
            AppSectionLinkButton(label: 'Ver mais', onPressed: () {}),
          ],
        ),
        const SizedBox(height: SpacingTokens.labelToField),
        Container(
          padding: CardTokens.padding,
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
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isFuturo || isCarregando
                              ? AppColors.labelSecondary.withAlpha(100)
                              : AppColors.labelSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isFeito
                              ? AppColors.primary
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isFeito
                                ? AppColors.primary
                                : AppColors.labelSecondary.withAlpha(30),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: isFeito
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.black,
                                  size: 18,
                                )
                              : Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.labelSecondary.withAlpha(
                                      50,
                                    ),
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
                    return Center(
                      child: Text(
                        'Carregando...',
                        style: TextStyle(
                          color: AppColors.labelSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }

                  final int count = dias
                      .where((d) => d['status'] == 'feito')
                      .length;
                  final String textoResumo = isAlunoView
                      ? 'Você treinou $count dias essa semana'
                      : '$primeiroNome treinou $count dias essa semana';

                  return Center(
                    child: Text(
                      textoResumo,
                      style: TextStyle(
                        color: AppColors.labelSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
