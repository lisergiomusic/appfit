import 'package:flutter/cupertino.dart';

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
