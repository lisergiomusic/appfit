import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

/// Botão de link inline para seções ("Ver mais", "Ver tudo", "Ver todas").
class AppSectionLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AppSectionLinkButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 0),
      minimumSize: const Size(0, 0),
      onPressed: onPressed,
      child: Text(label, style: AppTheme.sectionAction),
    );
  }
}
