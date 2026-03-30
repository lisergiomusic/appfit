import 'package:flutter/cupertino.dart';

/// Wrapper de toque com feedback de opacidade (estilo iOS).
/// Substitui CupertinoButton(padding: EdgeInsets.zero) usado como
/// envoltório de tap em containers com layout próprio.
class AppTappable extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const AppTappable({
    super.key,
    required this.child,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: child,
    );
  }
}
