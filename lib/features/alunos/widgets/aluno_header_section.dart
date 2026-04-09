import 'package:flutter/material.dart';
import 'aluno_avatar.dart';
import '../../../core/theme/app_theme.dart';

class AlunoHeaderSection extends StatelessWidget {
  final String alunoId;
  final String alunoNome;
  final String? photoUrl;
  final String idade;
  final String peso;
  final Widget? actions;

  const AlunoHeaderSection({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    this.photoUrl,
    required this.idade,
    required this.peso,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AlunoAvatar(
          alunoNome: alunoNome,
          photoUrl: photoUrl,
          radius: AvatarTokens.lg,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(alunoNome, style: AppTheme.title1),
              const SizedBox(height: SpacingTokens.titleToSubtitle),
              Row(
                children: [
                  _buildBadge(Icons.calendar_today_rounded, '$idade anos'),
                  const SizedBox(width: 8),
                  _buildBadge(Icons.fitness_center_rounded, '$peso kg'),
                ],
              ),
              if (actions != null) ...[const SizedBox(height: 12), actions!],
            ],
          ),
        ),
      ],
    );
  }

  // ...existing code...

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: PillTokens.radius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.labelSecondary),
          const SizedBox(width: 6),
          Text(label, style: PillTokens.text),
        ],
      ),
    );
  }
}
