import 'package:flutter/material.dart';

class AppUIUtils {
  /// Mostra um aviso informando que a funcionalidade ainda não está disponível.
  static void showFutureFeatureWarning(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento. Disponível em breve!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}