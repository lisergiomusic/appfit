import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class RestTimerSheet extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final String exercicioNome;
  final VoidCallback onSkip;

  const RestTimerSheet({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.exercicioNome,
    required this.onSkip,
  });

  String get _timeString {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withAlpha(40),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Row(
        children: [
          // Circular progress arc
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: totalSeconds > 0
                      ? remainingSeconds / totalSeconds
                      : 1.0,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primary.withAlpha(25),
                  strokeWidth: 4,
                ),
                Center(
                  child: Text(
                    _timeString,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: SpacingTokens.lg),
          // Exercise info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Descansando',
                  style: AppTheme.formLabel,
                ),
                const SizedBox(height: 4),
                Text(
                  'Próximo: $exercicioNome',
                  style: AppTheme.caption2.copyWith(
                    color: AppColors.labelTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Skip button
          TextButton(
            onPressed: onSkip,
            child: const Text(
              'Pular',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
