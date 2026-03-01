import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/app_theme.dart';
import 'main.dart'; // Precisamos disto para voltar à ChecagemPagina

class DashboardPage extends StatelessWidget {
  final String userType;

  const DashboardPage({super.key, required this.userType});

  // Função para terminar a sessão (Logout)
  Future<void> _sair(BuildContext context) async {
    // 1. Diz ao Firebase para terminar a sessão do utilizador atual
    await FirebaseAuth.instance.signOut();

    // 2. Remove todos os ecrãs anteriores da memória e volta ao Porteiro (ChecagemPagina)
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ChecagemPagina()),
        (Route<dynamic> route) => false, // Remove todo o histórico
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Apanhamos o utilizador que está autenticado neste momento
    final User? utilizadorAtual = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: FutureBuilder<DocumentSnapshot>(
          // Vai ao Firestore buscar o documento exato deste utilizador
          future: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(utilizadorAtual?.uid)
              .get(),
          builder: (context, snapshot) {
            // Enquanto espera pelos dados, mostra "A carregar..."
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                'A carregar...',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
              );
            }

            String nomeApresentacao = '';

            // Se os dados chegaram com sucesso e o documento existe
            if (snapshot.hasData && snapshot.data!.exists) {
              String nomeCompleto = snapshot.data!.get('nome');
              // Uma pequena magia: cortamos o nome nos espaços e apanhamos só o primeiro!
              nomeApresentacao = nomeCompleto.split(' ')[0];
            }

            // Define a saudação dinâmica
            String saudacao = userType == 'personal'
                ? 'Olá, Treinador $nomeApresentacao'
                : 'Olá, Atleta $nomeApresentacao';

            return Text(
              saudacao,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            );
          },
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
            icon: const Icon(
              Icons.logout,
              color: AppTheme.primary,
            ), // Ícone alterado para Sair
            onPressed: () => _sair(context), // Ligamos a função de logout aqui!
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
        color: AppTheme.surfaceLight,
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
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333)),
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
