import 'package:flutter/material.dart';
import 'app_avatar.dart';
import '../../../../core/theme/app_theme.dart';

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
        AppAvatar(
          name: alunoNome,
          photoUrl: photoUrl,
          radius: 36,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                alunoNome.toUpperCase(),
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildBadge(Icons.calendar_today_rounded, '$idade ANOS'),
                  const SizedBox(width: 8),
                  _buildBadge(Icons.fitness_center_rounded, '$peso KG'),
                ],
              ),
              if (actions != null) ...[const SizedBox(height: 12), actions!],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withAlpha(10), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.labelSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.premiumLabel.copyWith(
              fontSize: 10,
              color: AppColors.labelPrimary,
            ),
          ),
        ],
      ),
    );
  }
}