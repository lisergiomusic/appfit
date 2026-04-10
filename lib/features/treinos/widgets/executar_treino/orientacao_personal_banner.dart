import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class OrientacaoPersonalBanner extends StatefulWidget {
  final String? orientacao;

  const OrientacaoPersonalBanner({
    super.key,
    required this.orientacao,
  });

  @override
  State<OrientacaoPersonalBanner> createState() =>
      _OrientacaoPersonalBannerState();
}

class _OrientacaoPersonalBannerState extends State<OrientacaoPersonalBanner>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.orientacao == null || widget.orientacao!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.lg,
        vertical: SpacingTokens.sm,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                border: Border.all(
                  color: AppColors.primary.withAlpha(40),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.md,
                vertical: SpacingTokens.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      'Orientação do personal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: SpacingTokens.sm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(SpacingTokens.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(30),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.orientacao!,
                  style: AppTheme.cardSubtitle.copyWith(
                    color: AppColors.labelPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
