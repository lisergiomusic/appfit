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
        backgroundColor: AppTheme.background.withAlpha(200),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fitness_center, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: AppTheme.space12),
            const Text(
              'AppFit',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_outlined, color: AppTheme.textPrimary, size: 28),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.background, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          const SizedBox(width: AppTheme.space12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withAlpha(0),
                  Colors.white.withAlpha(25),
                  Colors.white.withAlpha(0),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
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
              padding: const EdgeInsets.fromLTRB(AppTheme.space24, AppTheme.space24, AppTheme.space24, AppTheme.space24),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppTheme.primary, AppTheme.iosBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: FutureBuilder<DocumentSnapshot>(
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
                                  ? const Icon(Icons.person, color: AppTheme.textSecondary, size: 34)
                                  : null,
                            );
                          },
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.background, width: 3),
                        ),
                        child: const Icon(Icons.check, size: 12, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppTheme.space16),
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
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: -1.0,
                              ),
                            );
                          },
                        ),
                        const Text(
                          'Plano Premium',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
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
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: 'ALUNOS ATIVOS',
                      value: '42',
                      trendText: '+12% este mês',
                      trendIcon: Icons.trending_up,
                      trendColor: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: _buildStatCard(
                      label: 'ATENÇÃO NECESSÁRIA',
                      value: '05',
                      trendText: 'Pendentes',
                      trendIcon: Icons.error_outline,
                      trendColor: AppTheme.accentMetrics,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.space32),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('AÇÕES RÁPIDAS', style: AppTheme.textSectionHeaderDark),
                      const Icon(Icons.keyboard_arrow_right, color: AppTheme.textSecondary, size: 18),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionSquare(
                          icon: Icons.person_add_rounded,
                          text: 'CADASTRAR\nALUNO',
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: _buildQuickActionSquare(
                          icon: Icons.assignment_add,
                          text: 'CRIAR\nROTINA',
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: _buildQuickActionSquare(
                          icon: Icons.bar_chart_rounded,
                          text: 'VER\nRELATÓRIOS',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.space32),

            // Recent Activity
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ATIVIDADE RECENTE', style: AppTheme.textSectionHeaderDark),
                  TextButton(
                    onPressed: () {},
                    child: const Text('VER TUDO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
              child: Column(
                children: [
                  _buildRecentActivityListTile(
                    name: 'Cristiano Ronaldo',
                    action: 'Concluiu Treino A',
                    time: 'Há 2h',
                    photoUrl: null,
                  ),
                  const SizedBox(height: AppTheme.space12),
                  _buildRecentActivityListTile(
                    name: 'Paola Oliveira',
                    action: 'Atualizou medidas',
                    time: 'Há 4h',
                    photoUrl: null,
                  ),
                  const SizedBox(height: AppTheme.space12),
                  _buildRecentActivityListTile(
                    name: 'Everton Ribeiro',
                    action: 'Novo PR no Supino',
                    time: 'Ontem',
                    photoUrl: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 120),
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

  Widget _buildStatCard({required String label, required String value, required String trendText, required IconData trendIcon, required Color trendColor}) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: Colors.white.withAlpha(10)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.microLabelTextStyle.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: AppTheme.space8),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -1.5)),
          const SizedBox(height: AppTheme.space12),
          Row(
            children: [
              Icon(trendIcon, size: 14, color: trendColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trendText,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: trendColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionSquare({required IconData icon, required String text}) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.primary.withAlpha(40)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.primary, size: 28),
              const SizedBox(height: AppTheme.space8),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityListTile({
    required String name,
    required String action,
    required String time,
    String? photoUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withAlpha(180),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.white.withAlpha(15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.textSecondary.withAlpha(40)),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.surfaceLight,
                    backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null || photoUrl.isEmpty
                        ? const Icon(Icons.person, color: AppTheme.textSecondary, size: 22)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                // Informações Centrais
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
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        action,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary.withAlpha(200),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Tempo alinhado à direita e centralizado verticalmente
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}