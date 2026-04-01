import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'exercicio_constants.dart';

class HintingSerieAnimator extends StatefulWidget {
  final Widget Function(BuildContext context, Color? color) builder;
  final VoidCallback onEnd;

  const HintingSerieAnimator({
    super.key,
    required this.builder,
    required this.onEnd,
  });

  @override
  State<HintingSerieAnimator> createState() => _HintingSerieAnimatorState();
}

class _HintingSerieAnimatorState extends State<HintingSerieAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ExercicioDetalheConstants.newHintAnimationDuration,
      vsync: this,
    );

    final highlightColor = AppColors.primary.withAlpha(30);
    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.transparent, end: highlightColor),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: highlightColor, end: Colors.transparent),
        weight: 50.0,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(ExercicioDetalheConstants.newHintDelay, () {
      if (mounted) {
        _controller.forward().whenComplete(() {
          if (mounted) {
            widget.onEnd();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return widget.builder(context, _colorAnimation.value);
      },
    );
  }
}
