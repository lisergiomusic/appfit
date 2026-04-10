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
        IconButton(
          onPressed: onEdit,
          style: IconButton.styleFrom(backgroundColor: AppColors.buttonSurface),
          icon: const Icon(
            CupertinoIcons.pencil,
            color: AppColors.labelPrimary,
          ),
        ),
      ],
    );
  }
}
