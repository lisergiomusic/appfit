import 'package:flutter/material.dart';
import 'app_dismissible_background.dart';

class AppSwipeToDelete extends StatelessWidget {
  final Key dismissibleKey;
  final Widget child;
  final void Function(DismissDirection) onDismissed;
  final Future<bool?> Function(DismissDirection)? confirmDismiss;
  final DismissDirection direction;
  final String label;

  const AppSwipeToDelete({
    super.key,
    required this.dismissibleKey,
    required this.child,
    required this.onDismissed,
    this.confirmDismiss,
    this.direction = DismissDirection.endToStart,
    this.label = 'Remover',
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: dismissibleKey,
      direction: direction,
      confirmDismiss: confirmDismiss,
      background: const AppDismissibleBackground(
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: AppDismissibleBackground(
        label: label,
        alignment: Alignment.centerRight,
      ),
      onDismissed: onDismissed,
      child: child,
    );
  }
}