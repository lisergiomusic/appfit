import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'treinos_page.dart'; // <-- IMPORTANTE: Importamos a tela de treinos aqui!

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Pegamos o ID do Personal para buscar apenas os alunos dele
    final String? personalId = FirebaseAuth.instance.currentUser?.uid;

    return SingleChildScrollView(
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
              // --- CARD DE ALUNOS ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('usuarios')
                      .where('tipoUsuario', isEqualTo: 'aluno')
                      .where(
                        'personalId',
                        isEqualTo: personalId,
                      ) // Filtra os SEUS alunos
                      .snapshots(),
                  builder: (context, snapshot) {
                    String quantidadeAlunos = '...';

                    if (snapshot.hasData) {
                      quantidadeAlunos = snapshot.data!.docs.length
                          .toString()
                          .padLeft(2, '0');
                    }

                    return _buildSummaryCard(
                      'Alunos',
                      quantidadeAlunos,
                      Icons.people_outline,
                      AppTheme.primary,
                      null, // <-- null porque a aba alunos já está lá embaixo
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),

              // --- CARD DE TREINOS (AGORA CLICÁVEL) ---
              Expanded(
                child: _buildSummaryCard(
                  'Treinos',
                  '00',
                  Icons.fitness_center,
                  AppTheme.success,
                  () {
                    // <-- Ação para abrir a página de treinos
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TreinosPage(),
                      ),
                    );
                  },
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
            'Adicionar Aluno',
            'Envie um convite',
            Icons.person_add_outlined,
            () {
              // Em breve podemos abrir o modal direto daqui!
            },
          ),
          const SizedBox(height: 12),

          // --- BOTÃO DE NOVO TREINO (AGORA CLICÁVEL) ---
          _buildActionCard(
            'Biblioteca de Treinos',
            'Gerencie seus templates',
            Icons.note_add_outlined,
            () {
              // <-- Ação para abrir a página de treinos
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TreinosPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  // <-- ADICIONAMOS O PARÂMETRO 'VoidCallback? onTap'
  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      // <-- Ouve o toque na tela
      onTap: onTap,
      child: Container(
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // <-- ADICIONAMOS O PARÂMETRO 'VoidCallback onTap'
  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      // <-- Ouve o toque na tela e dá um efeitinho visual
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
            Icon(icon, color: AppTheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
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
