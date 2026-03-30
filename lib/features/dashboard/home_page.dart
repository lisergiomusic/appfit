import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: Row(
          children: [
            const SizedBox(width: 10),
            const Text('Painel de Controle'),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.systemRed,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 1.5,
                      ),
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
            height: 1.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withAlpha(0),
                  Colors.white.withAlpha(20),
                  Colors.white.withAlpha(0),
                ],
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
            FutureBuilder<Map<String, dynamic>?>(
              future: authService.getCurrentUserData(),
              builder: (context, snapshot) {
                String nome = "...";
                String? photoUrl;

                if (snapshot.hasData && snapshot.data != null) {
                  final data = snapshot.data!;
                  nome = data['nome']?.toString().split(' ')[0] ?? "Usuário";
                  photoUrl = data['photoUrl'] as String?;
                }

                return Padding(
                  padding: const EdgeInsets.all(AppTheme.paddingScreen),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: AvatarTokens.lg,
                            backgroundColor: AppColors.surfaceLight,
                            backgroundImage:
                                photoUrl != null && photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null || photoUrl.isEmpty
                                ? const Icon(
                                    Icons.person_rounded,
                                    color: AppColors.labelSecondary,
                                    size: 34,
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getSaudacao()}, $nome',
                              style: AppTheme.bigTitle,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Plano Premium',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingScreen,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: 'Alunos ativos',
                      value: '42',
                      trendText: '+12% este mês',
                      trendIcon: Icons.trending_up_rounded,
                      trendColor: AppColors.primary,
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
                      trendColor: AppColors.accentMetrics,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpacingTokens.xxl),
            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingScreen,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 4,
                      bottom: SpacingTokens.sm,
                    ),
                    child: Text('Ações rápidas', style: AppTheme.sectionHeader),
                  ),
                  Row(
                    children: [
                      _buildQuickActionButton(
                        icon: Icons.person_add_rounded,
                        label: 'Novo aluno',
                        color: AppColors.primary,
                        onTap: () {},
                      ),
                      const SizedBox(width: 12),
                      _buildQuickActionButton(
                        icon: Icons.assignment_rounded,
                        label: 'Criar rotina',
                        color: AppColors.iosBlue,
                        onTap: () {},
                      ),
                      const SizedBox(width: 12),
                      _buildQuickActionButton(
                        icon: Icons.bar_chart_rounded,
                        label: 'Relatórios',
                        color: AppColors.accentMetrics,
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingScreen,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Atividade recente',
                      style: AppTheme.sectionHeader,
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size(0, 0),
                    onPressed: () {},
                    child: const Text(
                      'Ver tudo',
                      style: AppTheme.sectionAction,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingScreen,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
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
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: Padding(
          padding: CardTokens.padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTheme.formLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(value, style: AppTheme.title1),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(trendIcon, size: 12, color: trendColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            trendText,
                            style: AppTheme.caption.copyWith(color: trendColor),
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
                  color: AppColors.labelSecondary.withAlpha(80),
                ),
              ],
            ],
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
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.fillSecondary,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTheme.caption.copyWith(color: AppColors.labelPrimary),
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
    return InkWell(
      onTap: () {},
      child: Column(
        children: [
          Padding(
            padding: CardTokens.padding,
            child: Row(
              children: [
                CircleAvatar(
                  radius: AvatarTokens.md,
                  backgroundColor: AppColors.surfaceLight,
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          color: AppColors.labelSecondary,
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTheme.cardTitle),
                      const SizedBox(height: 1),
                      Text(
                        action,
                        style: AppTheme.cardSubtitle,
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
                    Text(time, style: AppTheme.caption),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.labelSecondary.withAlpha(80),
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
                color: AppColors.separator,
              ),
            ),
        ],
      ),
    );
  }
}