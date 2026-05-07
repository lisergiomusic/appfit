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
  static const double videoAspectRatio = 1 / 1;
}

class SerieTypeOption {
  final String title;
  final String subtitlePersonal;
  final String subtitleAluno;
  final TipoSerie type;
  final IconData icon;
  final Color color;

  const SerieTypeOption({
    required this.title,
    required this.subtitlePersonal,
    required this.subtitleAluno,
    required this.type,
    required this.icon,
    required this.color,
  });
}

const List<SerieTypeOption> serieTypeOptions = [
  SerieTypeOption(
    title: 'Série de aquecimento',
    subtitlePersonal:
        'Preparação articular e neuromuscular. Carga mínima, foco em '
        'lubrificação e técnica, sem gerar fadiga residual.',
    subtitleAluno:
        'Use uma carga bem leve — o objetivo não é se cansar, mas preparar '
        'os músculos e articulações para o esforço que vem a seguir. '
        'Execute com atenção ao movimento.',
    type: TipoSerie.aquecimento,
    icon: Icons.whatshot_rounded,
    color: Color(0xFF00B4D8),
  ),
  SerieTypeOption(
    title: 'Série de trabalho',
    subtitlePersonal:
        'Séries efetivas de treinamento. Foco em máxima intensidade, '
        'técnica rigorosa e cumprimento do volume planejado.',
    subtitleAluno:
        'Execute com o máximo de qualidade: peso desafiador, foco no movimento '
        'e sem encurtar o descanso entre elas.',
    type: TipoSerie.trabalho,
    icon: Icons.fitness_center_rounded,
    color: Color(0xFFFF3366),
  ),
];