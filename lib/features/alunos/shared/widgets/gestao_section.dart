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
        Text(
          'GESTÃO E DADOS',
          style: AppTheme.sectionHeader.copyWith(
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.01),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.03),
              width: 1,
            ),
          ),
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
              vertical: 18,
              horizontal: 16,
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_forward,
                  color: Colors.white.withValues(alpha: 0.15),
                  size: 14,
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              color: Colors.white.withValues(alpha: 0.03),
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
        ],
      ),
    );
  }
}