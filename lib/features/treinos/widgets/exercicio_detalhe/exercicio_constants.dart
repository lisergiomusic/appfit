import 'package:flutter/material.dart';
import '../../models/exercicio_model.dart';

class ExercicioDetalheConstants {
  static const int instructionsMaxLength = 500;
  static const int warningRemainingChars = 50;
  static const Duration rowAnimationDuration = Duration(milliseconds: 300);
  static const Duration fadeAnimationDuration = Duration(milliseconds: 200);
  static const Duration flashAnimationDuration = Duration(milliseconds: 400);
  static const Duration newHintDelay = Duration(milliseconds: 400);
  static const Duration newHintAnimationDuration = Duration(milliseconds: 1200);
  static const Duration snackBarDuration = Duration(seconds: 4);
  static const double videoAspectRatio = 16 / 9;
}

class SerieTypeOption {
  final String title;
  final String subtitle;
  final TipoSerie type;
  final IconData icon;
  final Color color;

  const SerieTypeOption({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    required this.color,
  });
}

const List<SerieTypeOption> serieTypeOptions = [
  SerieTypeOption(
    title: 'Aquecimento',
    subtitle: 'Prepara as articulações e o sistema nervoso.',
    type: TipoSerie.aquecimento,
    icon: Icons.whatshot_rounded,
    color: Color(0xFF00B4D8),
  ),
  SerieTypeOption(
    title: 'Aproximação',
    subtitle: 'Sobe a carga progressivamente sem fadiga.',
    type: TipoSerie.feeder,
    icon: Icons.speed_rounded,
    color: Color(0xFFFFB703),
  ),
  SerieTypeOption(
    title: 'Série de Trabalho',
    subtitle: 'Série efetiva para hipertrofia ou força.',
    type: TipoSerie.trabalho,
    icon: Icons.fitness_center_rounded,
    color: Color(0xFFFF3366),
  ),
];
