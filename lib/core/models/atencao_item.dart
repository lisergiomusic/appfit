import 'package:flutter/material.dart';
import '../theme/tokens/app_colors.dart';

enum TipoAtencao {
  inatividade,
  vencimento,
  semPlanejamento,
  feedbackCritico;

  String get label {
    return switch (this) {
      TipoAtencao.inatividade => 'Inatividade',
      TipoAtencao.vencimento => 'Vencimento',
      TipoAtencao.semPlanejamento => 'Sem Planejamento',
      TipoAtencao.feedbackCritico => 'Feedback Crítico',
    };
  }

  IconData get icon {
    return switch (this) {
      TipoAtencao.inatividade => Icons.timer_off_outlined,
      TipoAtencao.vencimento => Icons.event_busy_outlined,
      TipoAtencao.semPlanejamento => Icons.assignment_late_outlined,
      TipoAtencao.feedbackCritico => Icons.error_outline_rounded,
    };
  }

  Color get color {
    return switch (this) {
      TipoAtencao.inatividade => AppColors.labelSecondary,
      TipoAtencao.vencimento => AppColors.accentMetrics,
      TipoAtencao.semPlanejamento => AppColors.iosBlue,
      TipoAtencao.feedbackCritico => AppColors.systemRed,
    };
  }
}

class AtencaoItem {
  final String alunoId;
  final String alunoNome;
  final String? alunoPhotoUrl;
  final TipoAtencao tipo;
  final String descricao;
  final DateTime dataReferencia;

  const AtencaoItem({
    required this.alunoId,
    required this.alunoNome,
    this.alunoPhotoUrl,
    required this.tipo,
    required this.descricao,
    required this.dataReferencia,
  });
}