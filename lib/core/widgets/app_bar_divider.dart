import 'package:flutter/material.dart';
import '../theme/tokens/app_colors.dart';

class AppBarDivider extends StatelessWidget implements PreferredSizeWidget {
  const AppBarDivider({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(0.5);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      color: AppColors.separator,
    );
  }
}
