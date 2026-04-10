import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class OrientacaoPersonalBanner extends StatefulWidget {
  final String? orientacao;

  const OrientacaoPersonalBanner({
    super.key,
    required this.orientacao,
  });

  @override
  State<OrientacaoPersonalBanner> createState() =>
      _OrientacaoPersonalBannerState();
}

class _OrientacaoPersonalBannerState extends State<OrientacaoPersonalBanner>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orientacao == null || widget.orientacao!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: SpacingTokens.sm),
        GestureDetector(
          onTap: _toggle,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              border: Border.all(
                color: AppColors.primary.withAlpha(35),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: 10,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: SpacingTokens.sm),
                const Expanded(
                  child: Text(
                    'Orientação do personal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  turns: _isExpanded ? 0.5 : 0,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        FadeTransition(
          opacity: _fadeAnim,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: SpacingTokens.sm),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(SpacingTokens.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(10),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.orientacao!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.labelPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
      ],
    );
  }
}
