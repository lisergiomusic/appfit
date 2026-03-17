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
        backgroundColor: AppTheme.background.withAlpha(230),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.white.withAlpha(12), height: 1.0),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(50),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary.withAlpha(76)),
              ),
              child: const Icon(Icons.fitness_center, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: AppTheme.space12),
            const Text(
              'AppFit',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(icon: const Icon(Icons.notifications_none, color: AppTheme.textSecondary), onPressed: () {}),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: AppTheme.space8,
                  height: AppTheme.space8,
                  decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppTheme.space8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.space24, AppTheme.space32, AppTheme.space24, AppTheme.space16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary, width: 2),
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
                              radius: 30,
                              backgroundImage: photoUrl != null
                                  ? NetworkImage(photoUrl)
                                  : const NetworkImage('https://i.pravatar.cc/150?img=11'),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: AppTheme.space20,
                          height: AppTheme.space20,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.background, width: 2),
                          ),
                          child: const Icon(Icons.check, size: 12, color: AppTheme.background),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Column(
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
                          final saudacao = _getSaudacao();
                          return Text(
                            '$saudacao, $nome',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          );
                        },
                      ),
                      const Text(
                        'Nível Premium',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: 'ALUNOS ATIVOS',
                      value: '42',
                      trendText: '+12%',
                      trendIcon: Icons.trending_up,
                      trendColor: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: _buildStatCard(
                      label: 'FEEDBACK',
                      value: '5',
                      trendText: 'Pendente',
                      trendIcon: Icons.pending_actions,
                      trendColor: AppTheme.accentMetrics,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.space32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
              child: Text(
                'ATIVIDADE RECENTE',
                style: AppTheme.textSectionHeaderDark,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
              child: Column(
                children: [
                  _buildRecentActivityListTile(
                    name: 'Jordan Smith',
                    action: 'Concluiu Treino A',
                    time: 'Há 2h',
                    icon: Icons.local_fire_department,
                    iconColor: AppTheme.accentMetrics,
                  ),
                  const SizedBox(height: AppTheme.space12),
                  _buildRecentActivityListTile(
                    name: 'Sarah Williams',
                    action: 'Atualizou as medidas',
                    time: 'Há 4h',
                    icon: Icons.straighten,
                    iconColor: AppTheme.iosBlue,
                  ),
                  const SizedBox(height: AppTheme.space12),
                  _buildRecentActivityListTile(
                    name: 'Marcus Chen',
                    action: 'Novo PR no Supino',
                    time: 'Ontem',
                    icon: Icons.emoji_events,
                    iconColor: Colors.amber,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  String _getSaudacao() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) {
      return 'Bom dia';
    } else if (hora >= 12 && hora < 18) {
      return 'Boa tarde';
    } else {
      return 'Boa noite';
    }
  }

  Widget _buildStatCard({required String label, required String value, required String trendText, required IconData trendIcon, required Color trendColor}) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.microLabelTextStyle),
          const SizedBox(height: AppTheme.space4),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -1.0)),
          const SizedBox(height: AppTheme.space8),
          Row(
            children: [
              Icon(trendIcon, size: 14, color: trendColor),
              const SizedBox(width: AppTheme.space4),
              Text(trendText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: trendColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityListTile({required String name, required String action, required String time, required IconData icon, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withAlpha(30), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(action, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}