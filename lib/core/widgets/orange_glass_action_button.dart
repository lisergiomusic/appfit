import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class OrangeGlassActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData icon;
  final double bottomMargin;
  final bool showGlow;

  const OrangeGlassActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.add_circle_outline_rounded,
    this.bottomMargin = 8,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final buttonWidth = MediaQuery.sizeOf(context).width - 32;

    return Container(
      width: buttonWidth,
      margin: EdgeInsets.only(bottom: bottomMargin),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        boxShadow: [AppTheme.cardShadow]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          splashColor: Colors.white.withAlpha(41),
          highlightColor: const Color.fromARGB(
            255,
            153,
            64,
            64,
          ).withAlpha(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(icon, color: Colors.black, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
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