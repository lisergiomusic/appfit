import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RotinaModernInput extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;

  const RotinaModernInput({
    super.key,
    required this.label,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 0, bottom: AppTheme.space12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primary),
              SizedBox(width: AppTheme.space8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}