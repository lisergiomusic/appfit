import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'detalhe_treino_page.dart'; // Reutilizamos para ver os exercícios

class RotinaDetalhePage extends StatelessWidget {
  final String rotinaTitulo;
  final String? objetivo;

  const RotinaDetalhePage({
    super.key,
    required this.rotinaTitulo,
    this.objetivo,
  });

  @override
  Widget build(BuildContext context) {
    // Mock das sessões que compõem esta rotina
    final List<Map<String, dynamic>> sessoes = [
      {
        'letra': 'A',
        'nome': 'Membros Superiores',
        'exercicios': 6,
        'status': 'sugerido',
      },
      {
        'letra': 'B',
        'nome': 'Membros Inferiores',
        'exercicios': 8,
        'status': 'pendente',
      },
      {
        'letra': 'C',
        'nome': 'Core e Cardio',
        'exercicios': 5,
        'status': 'pendente',
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Minha Rotina', style: TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CABEÇALHO DA ROTINA
            Text(
              rotinaTitulo,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              objetivo ?? 'Foco em ganho de massa muscular',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              'SESSÕES DE TREINO',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // 2. LISTA DE CARDS DE SESSÃO
            ...sessoes
                .map((sessao) => _buildSessaoCard(context, sessao))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessaoCard(BuildContext context, Map<String, dynamic> sessao) {
    bool isSugerido = sessao['status'] == 'sugerido';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Navega para ver os exercícios (Vista do Aluno)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalheTreinoPage(
                treinoId: 'mock_id',
                treinoTitulo: sessao['nome'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSugerido
                  ? AppTheme.primary.withAlpha(100)
                  : Colors.white.withAlpha(13),
              width: 1.5,
            ),
            gradient: isSugerido
                ? LinearGradient(
                    colors: [
                      AppTheme.primary.withAlpha(20),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Badge de Letra
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSugerido ? AppTheme.primary : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    sessao['letra'],
                    style: TextStyle(
                      color: isSugerido ? Colors.white : AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Informações do Treino
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sessao['nome'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sessao['exercicios']} exercícios',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Ícone de Ação
              Icon(
                Icons.play_circle_fill,
                color: isSugerido
                    ? AppTheme.primary
                    : AppTheme.textSecondary.withAlpha(100),
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
