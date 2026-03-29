import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

InputDecoration rotinaInputDecoration({required String hintText}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTheme.inputPlaceHolder,
    filled: true,
    fillColor: AppTheme.surfaceDark,
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppTheme.space14,
      vertical: AppTheme.space12,
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
        color: AppTheme.primary.withAlpha(150),
        width: 0.5,
      ),
    ),
  );
}