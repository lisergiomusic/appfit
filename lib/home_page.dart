import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- NOVO: Para saber quem é o Personal
import 'theme/app_theme.dart';

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
              // --- A MÁGICA ACONTECE AQUI NO CARD DE ALUNOS ---
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
                    // Enquanto carrega, mostramos uns pontinhos
                    String quantidadeAlunos = '...';

                    // Se a busca deu certo, contamos o tamanho da lista (docs.length)
                    if (snapshot.hasData) {
                      // O padLeft(2, '0') garante que o número 5 fique "05", mantendo o visual elegante!
                      quantidadeAlunos = snapshot.data!.docs.length
                          .toString()
                          .padLeft(2, '0');
                    }

                    return _buildSummaryCard(
                      'Alunos',
                      quantidadeAlunos,
                      Icons.people_outline,
                      AppTheme.primary,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),

              // O card de Treinos continua estático até criarmos a aba dele
              Expanded(
                child: _buildSummaryCard(
                  'Treinos',
                  '00',
                  Icons.fitness_center,
                  AppTheme.success,
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
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            'Novo Treino',
            'Crie uma ficha',
            Icons.note_add_outlined,
          ),
        ],
      ),
    );
  }

  // Retirei o Expanded de dentro da função para podermos usar o StreamBuilder em volta dele com segurança
  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon) {
    return Container(
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
    );
  }
}
