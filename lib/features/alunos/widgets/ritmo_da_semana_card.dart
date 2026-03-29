import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_theme.dart';

class RitmoDaSemanaCard extends StatelessWidget {
  final String alunoNome;

  const RitmoDaSemanaCard({super.key, required this.alunoNome});


  @override
  Widget build(BuildContext context) {
    final String primeiroNome = alunoNome.split(' ').first;
    final dias = [
      {'dia': 'S', 'status': 'feito'},
      {'dia': 'T', 'status': 'feito'},
      {'dia': 'Q', 'status': 'futuro'},
      {'dia': 'Q', 'status': 'feito'},
      {'dia': 'S', 'status': 'feito'},
      {'dia': 'S', 'status': 'futuro'},
      {'dia': 'D', 'status': 'futuro'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen),
          child: SizedBox(
            height: 32,
            child: Row(
              children: [
                const SizedBox(width: 4),
                Text('Frequência semanal', style: AppTheme.sectionHeader),
                const Spacer(),
                CupertinoButton(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 4,
                    top: 4,
                    bottom: 4,
                  ),
                  onPressed: () {},
                  child: const Text(
                    'Ver mais',
                    style: AppTheme.sectionAction,
                  ), minimumSize: Size(0, 0),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: dias.map((d) {
                  final isFeito = d['status'] == 'feito';
                  final isFuturo = d['status'] == 'futuro';

                  return Column(
                    children: [
                      Text(
                        d['dia']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isFuturo ? AppColors.labelSecondary.withAlpha(100) : AppColors.labelSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isFeito ? AppColors.primary : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isFeito ? AppColors.primary : AppColors.labelSecondary.withAlpha(30),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: isFeito
                              ? const Icon(Icons.check, color: Colors.black, size: 18)
                              : Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.labelSecondary.withAlpha(50),
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
                  final int diasTreinados = dias.where((d) => d['status'] == 'feito').length;
                  return Center(
                    child: Text(
                      '$primeiroNome treinou $diasTreinados dias essa semana',
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