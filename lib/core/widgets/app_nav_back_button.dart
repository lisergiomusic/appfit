import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

class AppNavBackButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AppNavBackButton({super.key, this.label = '', this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.only(left: 8),
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.chevron_back,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(label, style: AppTheme.navBarAction),
        ],
      ),
    );
  }
}
