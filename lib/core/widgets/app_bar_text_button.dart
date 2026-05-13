import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'app_tappable.dart';

/// Um botão de texto otimizado para AppBars com estética Neo-Industrial.
/// Utiliza AppTappable para feedback tátil e tipografia técnica refinada.
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

    return AppTappable(
      onPressed: isEnabled ? () {
        HapticFeedback.lightImpact();
        onPressed!();
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isEnabled 
          ? BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 0.5,
              ),
            )
          : null,
        child: isLoading
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 1.5,
                ),
              )
            : Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: isEnabled 
                      ? AppColors.primary 
                      : Colors.white.withValues(alpha: 0.15),
                ),
              ),
      ),
    );
  }
}