import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

InputDecoration rotinaInputDecoration({required String hintText}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTheme.inputPlaceHolder,
    filled: true,
    fillColor: AppColors.surfaceDark,
    contentPadding: EdgeInsets.symmetric(
      horizontal: SpacingTokens.lg,
      vertical: SpacingTokens.md,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      borderSide: BorderSide(
        color: AppColors.primary.withAlpha(150),
        width: 0.5,
      ),
    ),
  );
}
