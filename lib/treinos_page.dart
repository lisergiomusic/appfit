import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

class TreinosPage extends StatelessWidget {
  const TreinosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // <-- ADICIONAMOS A APPBAR PARA TER O BOTÃO DE VOLTAR
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Biblioteca de Treinos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // O Flutter adiciona a setinha de voltar automaticamente aqui!
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Em breve: Modal para criar um novo template de treino
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Em breve: Criador de Fichas!'),
              backgroundColor: AppTheme.primary,
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhum treino na biblioteca.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Clique no botão + para criar sua primeira ficha padrão.',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
