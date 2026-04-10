import 'package:flutter/material.dart';
import '../../models/exercicio_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../exercicio_detalhe/exercicio_constants.dart';

class WorkoutSetRow extends StatelessWidget {
  final SerieItem serie;
  final int visualIndex;
  final TextEditingController repsController;
  final TextEditingController pesoController;
  final bool isCompleted;
  final VoidCallback onCheck;

  const WorkoutSetRow({
    super.key,
    required this.serie,
    required this.visualIndex,
    required this.repsController,
    required this.pesoController,
    required this.isCompleted,
    required this.onCheck,
  });

  void _showBadgeInfo(BuildContext context) {
    final option = serieTypeOptions.firstWhere(
      (opt) => opt.type == serie.tipo,
      orElse: () => serieTypeOptions.last,
    );
    showDialog<void>(
      context: context,
      builder: (_) => _BadgeInfoDialog(option: option),
    );
  }

  String get _serieLabel {
    switch (serie.tipo) {
      case TipoSerie.aquecimento:
      case TipoSerie.feeder:
        return '';
      case TipoSerie.trabalho:
        return visualIndex.toString();
    }
  }

  IconData? get _badgeIcon {
    final option = serieTypeOptions.firstWhere(
      (opt) => opt.type == serie.tipo,
      orElse: () => serieTypeOptions.last,
    );
    return serie.tipo != TipoSerie.trabalho ? option.icon : null;
  }

  Color get _serieColor {
    final option = serieTypeOptions.firstWhere(
      (opt) => opt.type == serie.tipo,
      orElse: () => serieTypeOptions.last,
    );
    return option.color;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.primary.withAlpha(14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      child: Row(
        children: [
          // Serie badge
          SizedBox(
            width: 36,
            child: GestureDetector(
              onTap: serie.tipo != TipoSerie.trabalho
                  ? () => _showBadgeInfo(context)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.primary.withAlpha(30)
                      : _serieColor.withAlpha(22),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Center(
                  child: _badgeIcon != null
                      ? Icon(
                          _badgeIcon,
                          size: 16,
                          color: isCompleted
                              ? AppColors.primary
                              : _serieColor,
                        )
                      : Text(
                          _serieLabel,
                          style: TextStyle(
                            color: isCompleted
                                ? AppColors.primary
                                : _serieColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          // Target
          SizedBox(
            width: 52,
            child: Text(
              serie.alvo,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isCompleted
                    ? AppColors.labelSecondary
                    : AppColors.labelSecondary,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Reps input
          Expanded(
            child: _SetInputField(
              controller: repsController,
              isCompleted: isCompleted,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          // Peso input
          Expanded(
            child: _SetInputField(
              controller: pesoController,
              isCompleted: isCompleted,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          // Check button
          SizedBox(
            width: 44,
            child: GestureDetector(
              onTap: onCheck,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: isCompleted
                    ? Container(
                        key: const ValueKey('checked'),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.black,
                          size: 18,
                        ),
                      )
                    : Container(
                        key: const ValueKey('unchecked'),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.labelTertiary,
                            width: 1.5,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Input compacto para série — fundo sutil, borda ao focar.
class _SetInputField extends StatefulWidget {
  final TextEditingController controller;
  final bool isCompleted;
  final TextInputType keyboardType;

  const _SetInputField({
    required this.controller,
    required this.isCompleted,
    required this.keyboardType,
  });

  @override
  State<_SetInputField> createState() => _SetInputFieldState();
}

class _SetInputFieldState extends State<_SetInputField> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 40,
      decoration: BoxDecoration(
        color: widget.isCompleted
            ? AppColors.primary.withAlpha(20)
            : _focused
                ? AppColors.surfaceLight
                : AppColors.background.withAlpha(200),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(
          color: _focused
              ? AppColors.primary.withAlpha(160)
              : Colors.white.withAlpha(10),
          width: 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        keyboardType: widget.keyboardType,
        textAlign: TextAlign.center,
        enabled: !widget.isCompleted,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: widget.isCompleted
              ? AppColors.primary
              : AppColors.labelPrimary,
          letterSpacing: -0.2,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          hintText: '—',
          hintStyle: const TextStyle(
            fontSize: 15,
            color: AppColors.labelTertiary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _BadgeInfoDialog extends StatelessWidget {
  final SerieTypeOption option;

  const _BadgeInfoDialog({required this.option});

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
