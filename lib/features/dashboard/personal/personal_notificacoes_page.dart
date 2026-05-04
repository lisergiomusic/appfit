import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bar_divider.dart';

class PersonalNotificationsPage extends StatelessWidget {
  const PersonalNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: const Text('Notificações'),
        bottom: const AppBarDivider(),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.screenTopPadding),
        children: [
          _buildSectionHeader('Recentes'),
          _NotificationTile(
            title: 'Campanha Black AppFit ⚡',
            description: 'Garanta 30% de desconto na renovação do seu plano anual. Oferta por tempo limitado!',
            time: 'Agora',
            icon: Icons.local_offer_rounded,
            iconColor: AppColors.accentMetrics,
            isNew: true,
          ),
          _NotificationTile(
            title: 'Novidade na Equipe',
            description: 'Agora você pode exportar relatórios de evolução em PDF diretamente do perfil do aluno.',
            time: '2h atrás',
            icon: Icons.rocket_launch_rounded,
            iconColor: AppColors.iosBlue,
            isNew: true,
          ),
          const SizedBox(height: 12),
          _buildSectionHeader('Anteriores'),
          _NotificationTile(
            title: 'Bem-vindo ao AppFit Pro!',
            description: 'Explore todas as ferramentas para gerenciar seus alunos com alta performance.',
            time: 'Ontem',
            icon: Icons.celebration_rounded,
            iconColor: AppColors.primary,
          ),
          _NotificationTile(
            title: 'Sistema Financeiro',
            description: 'O resumo mensal de pagamentos dos seus alunos já está disponível para conferência.',
            time: '2 dias atrás',
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Você chegou ao fim das notificações',
              style: AppTheme.caption.copyWith(color: AppColors.labelTertiary),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        title.toUpperCase(),
        style: AppTheme.microLabelTextStyle.copyWith(
          color: AppColors.labelTertiary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isNew;

  const _NotificationTile({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isNew ? AppColors.primary.withAlpha(5) : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.white.withAlpha(5), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTheme.cardTitle.copyWith(
                          fontSize: 15,
                          color: isNew ? AppColors.labelPrimary : AppColors.labelSecondary,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: AppTheme.caption2.copyWith(color: AppColors.labelTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTheme.bodyText.copyWith(
                    color: isNew ? AppColors.labelSecondary : AppColors.labelTertiary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (isNew)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 12, top: 4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}