import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class AppSectionLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AppSectionLinkButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.only(left: 8, right: 0, top: 4, bottom: 0),
      minimumSize: const Size(0, 0),
      onPressed: onPressed != null ? () {
        HapticFeedback.lightImpact();
        onPressed!();
      } : null,
      child: Text(
        label.toUpperCase(),
        style: AppTheme.sectionAction,
      ),
    );
  }
}
