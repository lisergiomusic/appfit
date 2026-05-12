import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_ui_utils.dart';
import '../../personal/pages/personal_feedback_historico_page.dart';

class GestaoSection extends StatelessWidget {
  final String alunoId;
  final String alunoNome;
  final String? photoUrl;
  final String peso;
  final String idade;

  const GestaoSection({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    this.photoUrl,
    required this.peso,
    required this.idade,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GESTÃO', style: AppTheme.sectionHeader),
        const SizedBox(height: SpacingTokens.xxl),
        Column(
          children: [
            _buildManagementItem(
              context,
              icon: CupertinoIcons.graph_square,
              title: 'PROGRESSÃO DE CARGAS',
              onTap: () {
                HapticFeedback.lightImpact();
                AppUIUtils.showFutureFeatureWarning(context);
              },
            ),
            _buildManagementItem(
              context,
              icon: CupertinoIcons.chart_bar_alt_fill,
              title: 'AVALIAÇÃO FÍSICA',
              onTap: () {
                HapticFeedback.lightImpact();
                AppUIUtils.showFutureFeatureWarning(context);
              },
            ),
            _buildManagementItem(
              context,
              icon: CupertinoIcons.doc_text,
              title: 'HISTÓRICO DE FEEDBACKS',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PersonalFeedbackHistoricoPage(alunoId: alunoId, alunoNome: alunoNome),
                  ),
                );
              },
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(SpacingTokens.sm),
                  ),
                  child: Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 18),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: AppColors.labelPrimary,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_forward,
                  color: Colors.white.withValues(alpha: 0.1),
                  size: 14,
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(color: Colors.white.withValues(alpha: 0.03), height: 1),
        ],
      ),
    );
  }
}