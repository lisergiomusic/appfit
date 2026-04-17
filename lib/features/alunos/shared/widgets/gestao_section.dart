import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Gestão', style: AppTheme.sectionHeader),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildManagementItem(
                context,
                icon: CupertinoIcons.graph_square,
                title: 'Progressão de Cargas',
                onTap: () => AppUIUtils.showFutureFeatureWarning(context),
                showBorder: true,
              ),
              _buildManagementItem(
                context,
                icon: CupertinoIcons.chart_bar_alt_fill,
                title: 'Avaliação Física',
                onTap: () => AppUIUtils.showFutureFeatureWarning(context),
                showBorder: true,
              ),
              _buildManagementItem(
                context,
                icon: CupertinoIcons.doc_text,
                title: 'Histórico de Feedbacks',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PersonalFeedbackHistoricoPage(alunoNome: alunoNome),
                    ),
                  );
                },
                showBorder: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManagementItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool showBorder,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.lg,
              vertical: 13,
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.labelTertiary, size: 22),
                const SizedBox(width: SpacingTokens.md),
                Expanded(child: Text(title, style: AppTheme.bodyText)),
                Icon(
                  CupertinoIcons.chevron_forward,
                  color: AppColors.labelQuaternary,
                  size: 16,
                ),
              ],
            ),
          ),
          if (showBorder)
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Container(height: 0.5, color: AppColors.separator),
            ),
        ],
      ),
    );
  }
}