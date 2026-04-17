import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../../main.dart';
import '../theme/app_theme.dart';

class AuthUtils {
  static Future<void> confirmarESair(BuildContext context) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.systemRed),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirma ?? false) {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ChecagemPagina()),
          (route) => false,
        );
      }
    }
  }
}