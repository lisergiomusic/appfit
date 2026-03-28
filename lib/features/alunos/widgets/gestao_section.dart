import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../gerenciar_planilhas_page.dart';
import '../feedback_historico_page.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Gestão', style: AppTheme.textSectionHeaderDark),
          ),
          Container(
            decoration: AppTheme.cardDecoration,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildManagementItem(
                  context,
                  icon: Icons.description_outlined,
                  title: 'Planilhas de Treino',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GerenciarPlanilhasPage(
                          alunoId: alunoId,
                          alunoNome: alunoNome,
                          photoUrl: photoUrl,
                          peso: peso,
                          idade: idade,
                        ),
                      ),
                    );
                  },
                  showBorder: true,
                ),
                _buildManagementItem(
                  context,
                  icon: Icons.history_edu_rounded,
                  title: 'Histórico de Feedbacks',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FeedbackHistoricoPage(alunoNome: alunoNome),
                      ),
                    );
                  },
                  showBorder: true,
                ),
                _buildManagementItem(
                  context,
                  icon: Icons.query_stats_rounded,
                  title: 'Avaliação Física',
                  onTap: () {},
                  showBorder: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool showBorder,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: showBorder ? Border(bottom: BorderSide(color: Colors.white.withAlpha(10), width: 1.0)) : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.textSecondary.withAlpha(150), size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary.withAlpha(80), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}