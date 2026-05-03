import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SecondaryGlassActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData icon;
  final double bottomMargin;

  const SecondaryGlassActionButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.icon,
    this.bottomMargin = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: bottomMargin),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withAlpha(40),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: Colors.white.withAlpha(20),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          splashColor: Colors.white.withAlpha(20),
          highlightColor: Colors.white.withAlpha(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(icon, color: Colors.white.withAlpha(200), size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withAlpha(230),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}