import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppFitSimpleAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool centerTitle;
  final VoidCallback? onBack;
  final bool showBackButton;
  final String backLabel;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppFitSimpleAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.centerTitle = true,
    this.onBack,
    this.showBackButton = true,
    this.backLabel = 'Voltar',
    this.actionLabel,
    this.onAction,
  }) : assert(title != null || titleWidget != null);

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 44,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leadingWidth: showBackButton ? 108 : null,
      leading: showBackButton
          ? TextButton.icon(
              onPressed: onBack ?? () => Navigator.pop(context),
              icon: const Icon(
                Icons.chevron_left,
                color: AppColors.primary,
                size: 18,
              ),
              label: Text(
                backLabel,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.only(left: 4, right: 8),
              ),
            )
          : null,
      title:
          titleWidget ??
          Text(
            title!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
      actions: [
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (actionLabel != null && onAction != null) const SizedBox(width: 4),
      ],
    );
  }
}
