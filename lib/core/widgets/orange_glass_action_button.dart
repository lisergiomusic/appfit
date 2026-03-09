import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class OrangeGlassActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData icon;
  final double bottomMargin;

  const OrangeGlassActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.add_circle_outline_rounded,
    this.bottomMargin = 8,
  });

  @override
  State<OrangeGlassActionButton> createState() =>
      _OrangeGlassActionButtonState();
}

class _OrangeGlassActionButtonState extends State<OrangeGlassActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final glowShadows = _isPressed
        ? <BoxShadow>[
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.38),
              blurRadius: 12,
              spreadRadius: 0.6,
              offset: const Offset(0, 2),
            ),
          ]
        : <BoxShadow>[
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.34),
              blurRadius: 12,
              spreadRadius: 0.4,
              offset: const Offset(0, 2),
            ),
          ];

    final buttonWidth = MediaQuery.sizeOf(context).width - 32;

    return Container(
      width: buttonWidth,
      margin: EdgeInsets.only(bottom: widget.bottomMargin),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(999),
        boxShadow: glowShadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (isHighlighted) {
            if (_isPressed != isHighlighted) {
              setState(() => _isPressed = isHighlighted);
            }
          },
          borderRadius: BorderRadius.circular(999),
          splashColor: Colors.white.withValues(alpha: 0.16),
          highlightColor: Colors.black.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(widget.icon, color: Colors.black, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.2,
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
