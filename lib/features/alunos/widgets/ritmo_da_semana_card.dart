import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RitmoDaSemanaCard extends StatelessWidget {
  const RitmoDaSemanaCard({super.key, });


  @override
  Widget build(BuildContext context) {
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text('Frequência semanal', style: AppTheme.textSectionHeaderDark),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Ver mais',
                  style: TextStyle(color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen),
          padding: const EdgeInsets.all(20),
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
                          color: isFuturo ? AppTheme.textSecondary.withAlpha(100) : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isFeito ? AppTheme.primary : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isFeito ? AppTheme.primary : AppTheme.textSecondary.withAlpha(30),
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
                                    color: AppTheme.textSecondary.withAlpha(50),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final int diasTreinados = dias.where((d) => d['status'] == 'feito').length;
                  return Center(
                    child: Text(
                      'O aluno treinou $diasTreinados dias essa semana',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
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