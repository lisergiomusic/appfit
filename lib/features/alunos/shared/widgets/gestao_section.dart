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
        Align(
          alignment: Alignment.centerLeft,
          child: Text('GESTÃO', style: AppTheme.sectionHeader),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: AppTheme.premiumCardDecoration,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildManagementItem(
                context,
                icon: CupertinoIcons.graph_square,
                title: 'PROGRESSÃO DE CARGAS',
                onTap: () {
                  HapticFeedback.lightImpact();
                  AppUIUtils.showFutureFeatureWarning(context);
                },
                showBorder: true,
              ),
              _buildManagementItem(
                context,
                icon: CupertinoIcons.chart_bar_alt_fill,
                title: 'AVALIAÇÃO FÍSICA',
                onTap: () {
                  HapticFeedback.lightImpact();
                  AppUIUtils.showFutureFeatureWarning(context);
                },
                showBorder: true,
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
              vertical: 16,
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.labelTertiary, size: 20),
                const SizedBox(width: SpacingTokens.md),
                Expanded(child: Text(title, style: AppTheme.sectionAction.copyWith(fontSize: 11, color: AppColors.labelPrimary))),
                Icon(
                  CupertinoIcons.chevron_forward,
                  color: AppColors.labelQuaternary.withAlpha(100),
                  size: 14,
                ),
              ],
            ),
          ),
          if (showBorder)
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Container(height: 0.5, color: Colors.white.withAlpha(10)),
            ),
        ],
      ),
    );
  }
}