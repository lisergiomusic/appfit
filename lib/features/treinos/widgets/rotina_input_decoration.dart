import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

InputDecoration rotinaInputDecoration({required String hintText}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      color: AppTheme.textSecondary.withAlpha(128),
      fontSize: 13,
    ),
    filled: true,
    fillColor: AppTheme.surfaceDark,
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppTheme.space14,
      vertical: AppTheme.space12,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      borderSide: BorderSide(color: Colors.white.withAlpha(20), width: 0.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      borderSide: BorderSide(color: Colors.white.withAlpha(20), width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      borderSide: BorderSide(
        color: AppTheme.primary.withAlpha(150),
        width: 1,
      ),
    ),
  );
}