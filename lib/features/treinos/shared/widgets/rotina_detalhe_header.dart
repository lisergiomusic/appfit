import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class RotinaDetalheHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String vencimentoLabel;
  final VoidCallback onEdit;

  const RotinaDetalheHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.vencimentoLabel,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // Centraliza verticalmente o ícone em relação ao texto
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bigTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: SpacingTokens.titleToSubtitle),
              Text(subtitle, style: CardTokens.cardSubtitle),
              const SizedBox(height: SpacingTokens.titleToSubtitle),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 11,
                    color: AppColors.labelSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(vencimentoLabel, style: AppTheme.caption),
                ],
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(12), // Background sutil e translúcido
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withAlpha(20), // Borda ultra-fina "glassmorphism"
                  width: 1,
                ),
              ),
              child: const Icon(
                CupertinoIcons.pencil,
                color: AppColors.labelPrimary,
                size: 18, // Ícone ligeiramente menor para maior elegância
              ),
            ),
          ),
        ),
      ],
    );
  }
}