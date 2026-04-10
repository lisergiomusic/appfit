import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class OrientacaoPersonalBanner extends StatelessWidget {
  final String? orientacao;

  const OrientacaoPersonalBanner({super.key, required this.orientacao});

  @override
  Widget build(BuildContext context) {
    if (orientacao == null || orientacao!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Text(
                  'Orientação do personal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            orientacao!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.labelPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
