import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class RecordesPessoaisSection extends StatelessWidget {
  final Map<String, double?> recordes;

  const RecordesPessoaisSection({super.key, required this.recordes});

  String _formatValor(double? valor) {
    if (valor == null) return '—';
    if (valor == valor.truncateToDouble()) {
      return '${valor.toInt()} kg';
    }
    return '${valor.toStringAsFixed(1)} kg';
  }

  void _mostrarExplicacao(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.cardPaddingH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ExplicacaoItem(
                titulo: 'Maior Peso',
                descricao:
                    'O maior peso registrado em uma série concluída para este exercício.',
                icone: Icons.fitness_center_rounded,
                cor: AppColors.accentMetrics,
              ),
              const SizedBox(height: SpacingTokens.sectionGap),
              _ExplicacaoItem(
                titulo: 'Melhor 1RM',
                descricao:
                    '1RM (Máximo de Uma Repetição) é uma estimativa do peso máximo que você consegue levantar em uma única repetição, calculada a partir das suas séries anteriores.',
                icone: Icons.bar_chart_rounded,
                cor: AppColors.iosBlue,
              ),
              const SizedBox(height: SpacingTokens.sectionGap),
              _ExplicacaoItem(
                titulo: 'Melhor Volume de Série',
                descricao:
                    'A série com maior volume total: peso multiplicado pelo número de repetições realizadas nessa série.',
                icone: Icons.layers_rounded,
                cor: AppColors.primary,
              ),
              const SizedBox(height: SpacingTokens.sectionGap),
              _ExplicacaoItem(
                titulo: 'Melhor Volume de Sessão',
                descricao:
                    'A sessão em que você acumulou mais volume neste exercício, somando o volume de todas as séries realizadas.',
                icone: Icons.calendar_today_rounded,
                cor: AppColors.success,
              ),
              const SizedBox(height: SpacingTokens.sectionGap),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: SpacingTokens.sm,
                  ),
                ),
                child: Text(
                  'Ok',
                  style: AppTheme.bodyText.copyWith(
                    color: AppColors.background,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Maior Peso', _formatValor(recordes['maiorPeso'])),
      ('Melhor 1RM', _formatValor(recordes['melhorUmRM'])),
      ('Melhor Volume de Série', _formatValor(recordes['melhorVolumeSerie'])),
      ('Melhor Volume de Sessão', _formatValor(recordes['melhorVolumeSessao'])),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              size: 16,
              color: AppColors.accentMetrics,
            ),
            const SizedBox(width: SpacingTokens.xs),
            Text('Recordes Pessoais', style: AppTheme.sectionHeader),
            const Spacer(),
            GestureDetector(
              onTap: () => _mostrarExplicacao(context),
              child: Icon(
                Icons.help_outline_rounded,
                size: 18,
                color: AppColors.labelTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.labelToField),
        Container(
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: List.generate(rows.length, (i) {
              final isLast = i == rows.length - 1;
              final isDash = rows[i].$2 == '—';
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.cardPaddingH,
                      vertical: SpacingTokens.cardPaddingV,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          rows[i].$1,
                          style: AppTheme.bodyText.copyWith(fontSize: 15),
                        ),
                        Text(
                          rows[i].$2,
                          style: AppTheme.cardSubtitle.copyWith(
                            color: isDash
                                ? AppColors.labelTertiary
                                : AppColors.labelPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: SpacingTokens.cardPaddingH,
                      color: Colors.white.withAlpha(10),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _ExplicacaoItem extends StatelessWidget {
  final String titulo;
  final String descricao;
  final IconData icone;
  final Color cor;

  const _ExplicacaoItem({
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cor.withAlpha(25),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: Icon(icone, size: 18, color: cor),
        ),
        const SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: AppTheme.cardTitle),
              const SizedBox(height: 3),
              Text(
                descricao,
                style: AppTheme.cardSubtitle.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
