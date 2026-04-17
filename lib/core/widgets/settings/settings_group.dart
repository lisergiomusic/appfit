import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SettingsItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final Color? labelColor;
  final VoidCallback onTap;

  const SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    this.labelColor,
    required this.onTap,
  });
}

class SettingsGroup extends StatelessWidget {
  final List<SettingsItem> items;

  const SettingsGroup({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _SettingsRow(item: items[i]),
            if (i < items.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 52,
                color: Color(0x14EBEBF5),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final SettingsItem item;

  const _SettingsRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isLogout = item.labelColor == AppColors.systemRed;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        splashColor: isLogout ? AppColors.systemRed.withAlpha(60) : AppColors.splash,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SpacingTokens.cardPaddingH,
            vertical: item.subtitle != null ? 12 : 15,
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 19, color: item.iconColor),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.2,
                        color: item.labelColor ?? AppColors.labelPrimary,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(item.subtitle!, style: AppTheme.caption),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.labelSecondary.withAlpha(80),
              ),
            ],
          ),
        ),
      ),
    );
  }
}