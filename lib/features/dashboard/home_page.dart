import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../treinos/treinos_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? personalId = FirebaseAuth.instance.currentUser?.uid;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VISÃO GERAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // --- CARD DE ALUNOS ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('usuarios')
                      .where('tipoUsuario', isEqualTo: 'aluno')
                      .where('personalId', isEqualTo: personalId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String quantidadeAlunos = '-';
                    if (snapshot.hasData) {
                      quantidadeAlunos = snapshot.data!.docs.length
                          .toString()
                          .padLeft(2, '0');
                    }
                    return _buildPremiumSummaryCard(
                      title: 'Alunos',
                      value: quantidadeAlunos,
                      icon: Icons.people_alt_outlined,
                      color: AppTheme.primary,
                      onTap: null, // Ação acontece na aba inferior
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),

              // --- CARD DE TREINOS (CONECTADO E CLICÁVEL) ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rotinas')
                      .where('personalId', isEqualTo: personalId)
                      .where('alunoId', isNull: true) // Conta só os templates!
                      .snapshots(),
                  builder: (context, snapshot) {
                    String quantidadeTreinos = '-';
                    if (snapshot.hasData) {
                      quantidadeTreinos = snapshot.data!.docs.length
                          .toString()
                          .padLeft(2, '0');
                    }
                    return _buildPremiumSummaryCard(
                      title: 'Templates',
                      value: quantidadeTreinos,
                      icon: Icons.collections_bookmark_outlined,
                      color: AppTheme.success,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TreinosPage(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          const Text(
            'AÇÕES RÁPIDAS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          _buildPremiumActionCard(
            title: 'Adicionar Aluno',
            subtitle: 'Enviar convite de acesso',
            icon: Icons.person_add_alt_1_outlined,
            onTap: () {
              // Modal abrirá aqui em breve
            },
          ),
          const SizedBox(height: 10),
          _buildPremiumActionCard(
            title: 'Biblioteca de Treinos',
            subtitle: 'Gerir os seus templates base',
            icon: Icons.layers_outlined,
            onTap: () {
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

  Widget _buildPremiumSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(10), width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24, // Fim da fonte gigante 32
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(10), width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.textSecondary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
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
            Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary.withAlpha(100),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
