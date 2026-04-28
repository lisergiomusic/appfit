import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppBarTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppBarTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      minimumSize: const Size(0, 0),
      onPressed: isEnabled ? onPressed : null,
      child: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.2,
              ),
            )
          : Text(
              label,
              style: AppBarTokens.actionButton.copyWith(
                color: isEnabled ? AppColors.primary : AppColors.labelTertiary,
              ),
            ),
    );
  }
}