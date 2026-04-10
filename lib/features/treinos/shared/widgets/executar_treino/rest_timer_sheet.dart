import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

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

  double get _progress =>
      totalSeconds > 0 ? remainingSeconds / totalSeconds : 1.0;

  @override
  Widget build(BuildContext context) {
    final isUrgent = remainingSeconds <= 5 && remainingSeconds > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        SpacingTokens.lg,
        0,
        SpacingTokens.lg,
        SpacingTokens.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
        border: Border.all(
          color: isUrgent
              ? AppColors.accentMetrics.withAlpha(80)
              : AppColors.primary.withAlpha(40),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.lg,
          vertical: SpacingTokens.md,
        ),
        child: Row(
          children: [
            // Circular progress
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 3,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isUrgent ? AppColors.accentMetrics : AppColors.primary,
                      ),
                    ),
                  ),
                  Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isUrgent
                            ? AppColors.accentMetrics
                            : AppColors.primary,
                        letterSpacing: 0.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      child: Text(_timeString),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: SpacingTokens.lg),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Descansando',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.labelPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    exercicioNome,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.labelTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Skip
            GestureDetector(
              onTap: onSkip,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: const Text(
                  'Pular',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.labelSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
