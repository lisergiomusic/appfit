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
                alunoNome,
                style: AppTheme.heroTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
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

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md, 
        vertical: SpacingTokens.space6
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: GlassTokens.opacityBadge),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: Colors.white.withValues(alpha: GlassTokens.opacityBadgeBorder),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Text(
            label,
            style: AppTheme.technicalLabel.copyWith(
              fontSize: 10,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}