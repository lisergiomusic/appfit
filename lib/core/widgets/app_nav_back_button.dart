import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';

import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

/// Botão "← Voltar" para o leading de AppBar.
/// Encapsula o padrão CupertinoButton + chevron_back + texto.
class AppNavBackButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AppNavBackButton({super.key, this.label = 'Voltar', this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.chevron_back,
            size: 17,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(label, style: AppTheme.navBarAction),
        ],
      ),
    );
  }
}
