import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../models/exercicio_model.dart';
import '../exercicio_detalhe/exercicio_constants.dart';

/// Abre o dialog informativo do tipo de série (aquecimento, aproximação, trabalho).
void showSerieBadgeInfo(BuildContext context, TipoSerie tipo) {
  final option = serieTypeOptions.firstWhere(
    (opt) => opt.type == tipo,
    orElse: () => serieTypeOptions.last,
  );
  showDialog<void>(
    context: context,
    builder: (_) => SerieBadgeInfoDialog(option: option),
  );
}

class SerieBadgeInfoDialog extends StatelessWidget {
  final SerieTypeOption option;

  const SerieBadgeInfoDialog({super.key, required this.option});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: option.color.withAlpha(28),
                shape: BoxShape.circle,
              ),
              child: Icon(option.icon, color: option.color, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              option.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.labelPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              option.subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.labelSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 46,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Center(
                  child: Text(
                    'Ok',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.labelPrimary,
                    ),
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
