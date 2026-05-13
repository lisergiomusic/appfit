import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Um botão primário com estética de vidro Neo-Industrial.
/// Implementa BackdropFilter para transparência real e animação de escala ao ser pressionado.
class GlassPrimaryButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final double height;
  final double borderRadius;
  final TextStyle? textStyle;

  const GlassPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 56.0,
    this.borderRadius = 100.0,
    this.textStyle,
  });

  @override
  State<GlassPrimaryButton> createState() => _GlassPrimaryButtonState();
}

class _GlassPrimaryButtonState extends State<GlassPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
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
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: GlassTokens.blurStandard,
              sigmaY: GlassTokens.blurStandard,
            ),
            child: Container(
              height: widget.height,
              width: double.infinity,
              decoration: BoxDecoration(
                // Cor vibrante com translucidez para permitir a passagem do desfoque.
                color: AppColors.primary.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: Colors.white.withValues(alpha: GlassTokens.opacityBorder),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.black, size: 20),
                    const SizedBox(width: SpacingTokens.sm),
                  ],
                  Text(
                    widget.label,
                    style: widget.textStyle ??
                        AppTheme.bodyText.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}