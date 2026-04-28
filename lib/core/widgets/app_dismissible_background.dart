import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppDismissibleBackground extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color baseColor;
  final Alignment alignment;

  const AppDismissibleBackground({
    super.key,
    this.label = 'Remover',
    this.icon = Icons.delete_rounded,
    this.baseColor = AppColors.systemRed,
    this.alignment = Alignment.centerRight,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEndToStart = alignment == Alignment.centerRight;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEndToStart
              ? [Colors.transparent, baseColor.withAlpha(220)]
              : [baseColor.withAlpha(220), Colors.transparent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      alignment: alignment,
      padding: EdgeInsets.only(
        right: isEndToStart ? 18 : 0,
        left: isEndToStart ? 0 : 18,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}