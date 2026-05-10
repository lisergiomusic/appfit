import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class AppPremiumFAB extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final double bottomPadding;
  final bool isFullWidth;

  const AppPremiumFAB({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.bottomPadding = 0,
    this.isFullWidth = false,
  });

  @override
  State<AppPremiumFAB> createState() => _AppPremiumFABState();
}

class _AppPremiumFABState extends State<AppPremiumFAB> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomPadding),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        scale: _isPressed ? 0.95 : 1.0,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            HapticFeedback.lightImpact();
            widget.onPressed();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: Container(
            height: 56,
            width: widget.isFullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(80),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Icon(widget.icon, color: Colors.black, size: 20),
                const SizedBox(width: 10),
                Text(
                  widget.label.toUpperCase(),
                  style: AppTheme.sectionHeader.copyWith(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
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
