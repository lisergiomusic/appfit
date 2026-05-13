import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Um botão de ícone circular com estética de vidro Neo-Industrial.
/// Possui efeito de desfoque de fundo (Glassmorphism) e micro-interação tátil de escala.
class GlassIconButton extends StatefulWidget {
  final IconData icon;
  final Widget? customIcon;
  final VoidCallback onPressed;
  final double size;
  final double? iconSize;
  final Color? color;
  final Color? iconColor;
  final bool hasBorder;

  const GlassIconButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.customIcon,
    this.size = 48.0,
    this.iconSize,
    this.color,
    this.iconColor,
    this.hasBorder = true,
  });

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      scale: _isPressed ? 0.92 : 1.0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.size / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: GlassTokens.blurStandard,
              sigmaY: GlassTokens.blurStandard,
            ),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color ?? Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: widget.hasBorder
                    ? Border.all(
                        color: Colors.white.withValues(alpha: GlassTokens.opacityBorder),
                        width: 1,
                      )
                    : null,
              ),
              child: Center(
                child: widget.customIcon ??
                    Icon(
                      widget.icon,
                      color: widget.iconColor ?? Colors.white,
                      size: widget.iconSize ?? (widget.size * 0.45),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}