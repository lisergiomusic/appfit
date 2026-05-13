import 'package:flutter/material.dart';
import 'app_colors.dart';

class GlassTokens {
  GlassTokens._();

  // Opacities (Alpha Values)
  static const double opacityAtmosphere = 0.18;
  static const double opacityAtmosphereSubtle = 0.05;
  static const double opacityConsole = 0.03;
  static const double opacityConsoleItems = 0.01;
  static const double opacityBorder = 0.05;
  static const double opacityHighBorder = 0.08;
  static const double opacitySurface = 0.02;
  static const double opacityBackdrop = 0.5;
  static const double opacityBadge = 0.04;
  static const double opacityBadgeBorder = 0.08;

  // Semantic Opacities
  static const double opacityLabel = 0.3;
  static const double opacitySecondaryText = 0.4;
  static const double opacityTertiaryText = 0.2;
  static const double opacityIconSubtle = 0.2;
  static const double opacityIconPrimary = 0.5;
  static const double opacityHint = 0.2;
  static const double opacitySeparator = 0.05;

  // Blur (Sigma Values)
  static const double blurStandard = 10.0;
  static const double blurHeader = 15.0;

  // Geometry
  static const double consoleRadius = 32.0;
  static const double itemRadius = 20.0;
  static const double consoleMarginH = 8.0;

  // Gradients
  static const Color modalGradientTop = AppColors.surfaceElevated;
  static const Color modalGradientBottom = AppColors.surfaceBlack;
}