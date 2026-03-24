import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fitness_center_rounded, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'AppFit',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                letterSpacing: -1.0,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_rounded, color: AppTheme.textPrimary, size: 26),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.background, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 0.5,
            color: Colors.white.withAlpha(15),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Perfil e Boas-vindas
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingScreen),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('usuarios')
                            .doc(user?.uid)
                            .get(),
                        builder: (context, snapshot) {
                          String? photoUrl;
                          if (snapshot.hasData && snapshot.data!.exists) {
                            photoUrl = (snapshot.data!.data() as Map<String, dynamic>)['photoUrl'];
                          }
                          return CircleAvatar(
                            radius: 34,
                            backgroundColor: AppTheme.surfaceLight,
                            backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                            child: photoUrl == null || photoUrl.isEmpty
                                ? const Icon(Icons.person_rounded, color: AppTheme.textSecondary, size: 34)
                                : null,
                          );
                        },
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.background, width: 2.5),
                        ),
                        child: const Icon(Icons.check_rounded, size: 10, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(user?.uid)
                              .get(),
                          builder: (context, snapshot) {
                            String nome = "...";
                            if (snapshot.hasData && snapshot.data!.exists) {
                              nome = snapshot.data!.get('nome').toString().split(' ')[0];
                            }
                            return Text(
                              '${_getSaudacao()}, $nome',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Plano Premium',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: 'Alunos ativos',
                      value: '42',
                      trendText: '+12% este mês',
                      trendIcon: Icons.trending_up_rounded,
                      trendColor: AppTheme.primary,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      label: 'Atenção necessária',
                      value: '05',
                      trendText: 'Pendentes',
                      trendIcon: Icons.error_rounded,
                      trendColor: AppTheme.accentMetrics,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 16),
                    child: Text(
                      'Ações rápidas',
                      style: AppTheme.textSectionHeaderDark,
                    ),
                  ),
                  Row(
                    children: [
                      _buildQuickActionButton(
                        icon: Icons.person_add_rounded,
                        label: 'Novo aluno',
                        color: AppTheme.primary,
                        onTap: () {},
                      ),
                      const SizedBox(width: 12),
                      _buildQuickActionButton(
                        icon: Icons.assignment_rounded,
                        label: 'Criar rotina',
                        color: AppTheme.iosBlue,
                        onTap: () {},
                      ),
                      const SizedBox(width: 12),
                      _buildQuickActionButton(
                        icon: Icons.bar_chart_rounded,
                        label: 'Relatórios',
                        color: AppTheme.accentMetrics,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Recent Activity
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Atividade recente',
                      style: AppTheme.textSectionHeaderDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Ver tudo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withAlpha(5)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _buildRecentActivityItem(
                      name: 'Cristiano Ronaldo',
                      action: 'Concluiu Treino A',
                      time: 'Há 2h',
                      showDivider: true,
                    ),
                    _buildRecentActivityItem(
                      name: 'Paola Oliveira',
                      action: 'Atualizou medidas',
                      time: 'Há 4h',
                      showDivider: true,
                    ),
                    _buildRecentActivityItem(
                      name: 'Everton Ribeiro',
                      action: 'Novo PR no Supino',
                      time: 'Ontem',
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  String _getSaudacao() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) return 'Bom dia';
    if (hora >= 12 && hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String trendText,
    required IconData trendIcon,
    required Color trendColor,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary.withAlpha(160),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(trendIcon, size: 12, color: trendColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              trendText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: trendColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppTheme.textSecondary.withAlpha(80),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityItem({
    required String name,
    required String action,
    required String time,
    required bool showDivider,
    String? photoUrl,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.surfaceLight,
                    backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null || photoUrl.isEmpty
                        ? const Icon(Icons.person_rounded, color: AppTheme.textSecondary, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          action,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary.withAlpha(180),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppTheme.textSecondary.withAlpha(80),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showDivider)
              Padding(
                padding: const EdgeInsets.only(left: 68),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Colors.white.withAlpha(10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}