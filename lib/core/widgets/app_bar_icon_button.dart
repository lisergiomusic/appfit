import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

/// Botão de ícone para actions de AppBar (ex: ícone de adicionar).
class AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final double size;
  final EdgeInsetsGeometry padding;

  const AppBarIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.primary,
    this.size = 24,
    this.padding = const EdgeInsets.only(right: 16),
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: padding,
      onPressed: onPressed,
      child: Icon(icon, color: color, size: size),
    );
  }
}
