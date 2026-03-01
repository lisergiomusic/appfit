import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

class DashboardPage extends StatelessWidget {
  final String userType;

  const DashboardPage({super.key, required this.userType});

  @override
  Widget build(BuildContext context) {
    String saudacao = userType == 'personal' ? 'Olá, Treinador' : 'Olá, Atleta';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme
            .surfaceDark, // Deixei a AppBar levemente destacada do fundo
        title: Text(
          saudacao,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: AppTheme.textPrimary,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: AppTheme.primary),
            onPressed: () {},
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Visão Geral',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Alunos Ativos',
                      value: '14',
                      icon: Icons.people_outline,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Treinos Hoje',
                      value: '08',
                      icon: Icons.fitness_center,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const Text(
                'Ações Rápidas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              _buildActionCard(
                title: 'Adicionar Novo Aluno',
                subtitle: 'Envie um convite para o app',
                icon: Icons.person_add_outlined,
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                title: 'Montar Novo Treino',
                subtitle: 'Crie uma ficha do zero',
                icon: Icons.note_add_outlined,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight, // Usando a cor do tema
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark, // Usando a cor do tema
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333)), // Borda sutil
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
