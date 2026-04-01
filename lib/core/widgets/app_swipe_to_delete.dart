import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, AppColors.systemRed.withAlpha(220)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_rounded, color: Colors.white, size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
      onDismissed: onDismissed,
      child: child,
    );
  }
}
