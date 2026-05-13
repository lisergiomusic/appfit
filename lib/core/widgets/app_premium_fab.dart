import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class AppPremiumFAB extends StatefulWidget {
  final String? label;
  final IconData icon;
  final VoidCallback onPressed;
  final double bottomPadding;
  final bool isFullWidth;
  final double height;
  final Color? backgroundColor;

  const AppPremiumFAB({
    super.key,
    this.label,
    required this.icon,
    required this.onPressed,
    this.bottomPadding = 0,
    this.isFullWidth = false,
    this.height = 56,
    this.backgroundColor,
  });

  @override
  State<AppPremiumFAB> createState() => _AppPremiumFABState();
}

class _AppPremiumFABState extends State<AppPremiumFAB> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.backgroundColor ?? AppColors.primary;

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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: widget.height,
                width: widget.isFullWidth 
                    ? double.infinity 
                    : (widget.label == null ? widget.height : null),
                padding: EdgeInsets.symmetric(
                  horizontal: widget.label == null ? 0 : 24,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: bgColor.alpha == 255 ? [
                    BoxShadow(
                      color: bgColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ] : null,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    Icon(
                      widget.icon, 
                      color: bgColor == AppColors.primary ? Colors.black : Colors.white, 
                      size: widget.height * 0.4,
                    ),
                    if (widget.label != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        widget.label!.toUpperCase(),
                        style: AppTheme.sectionHeader.copyWith(
                          color: bgColor == AppColors.primary ? Colors.black : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
