import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_theme.dart';
import 'spark_line_painter.dart';

class PesoHistoricoCard extends StatelessWidget {
  final double? pesoAtual;
  final List<Map<String, dynamic>>? historico;
  final VoidCallback onAdicionarPeso;

  const PesoHistoricoCard({
    super.key,
    this.pesoAtual,
    this.historico,
    required this.onAdicionarPeso,
  });

  @override
  Widget build(BuildContext context) {
    if (historico == null) {
      return _buildLoadingState();
    }

    if (historico!.isEmpty || pesoAtual == null) {
      return _buildEmptyState();
    }

    final pesos = historico!
        .take(8)
        .map((doc) => (doc['peso'] as num).toDouble())
        .toList()
        .reversed
        .toList();

    final datas = historico!
        .take(8)
        .map((doc) => (doc['dataHora'] as Timestamp).toDate())
        .toList()
        .reversed
        .toList();

    final pesoAtualVal = pesos.last;
    final pesoAnterior = pesos.length > 1
        ? pesos[pesos.length - 2]
        : pesos.last;
    final diferenca = pesoAtualVal - pesoAnterior;
    final tendencia = _buildTendencia(diferenca);

    final dataPrimeira = DateFormat('dd/MM', 'pt_BR').format(datas.first);
    final dataUltima = DateFormat('dd/MM', 'pt_BR').format(datas.last);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Peso corporal', style: AppTheme.sectionHeader),
        const SizedBox(height: SpacingTokens.labelToField),
        Container(
          decoration: AppTheme.cardDecoration,
          padding: CardTokens.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(pesoAtualVal.toStringAsFixed(1), style: AppTheme.bigTitle),
                  const SizedBox(width: 4),
                  Text(
                    'kg',
                    style: AppTheme.caption.copyWith(
                      color: AppColors.labelSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  tendencia,
                ],
              ),
              const SizedBox(height: SpacingTokens.lg),
              SizedBox(
                height: 64,
                child: CustomPaint(
                  painter: SparkLinePainter(pesos: pesos, color: AppColors.primary),
                  size: Size.infinite,
                ),
              ),
              const SizedBox(height: SpacingTokens.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$dataPrimeira → $dataUltima',
                    style: AppTheme.caption2.copyWith(
                      color: AppColors.labelSecondary.withAlpha(150),
                    ),
                  ),
                  Text(
                    '${historico!.length} ${historico!.length == 1 ? "registro" : "registros"}',
                    style: AppTheme.caption2.copyWith(
                      color: AppColors.labelSecondary.withAlpha(150),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SpacingTokens.lg),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onAdicionarPeso,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Registrar novo peso',
                            style: AppTheme.caption2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTendencia(double diferenca) {
    late IconData icon;
    late Color cor;
    late String label;

    if (diferenca.abs() < 0.1) {
      icon = Icons.remove_rounded;
      cor = AppColors.labelSecondary.withAlpha(150);
      label = 'Estável';
    } else if (diferenca > 0) {
      icon = Icons.trending_up_rounded;
      cor = AppColors.iosBlue;
      label = '+${diferenca.toStringAsFixed(1)} kg';
    } else {
      icon = Icons.trending_down_rounded;
      cor = AppColors.iosBlue;
      label = '${diferenca.toStringAsFixed(1)} kg';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cor, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.caption2.copyWith(
              color: cor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: CardTokens.padding,
      child: Column(
        children: [
          Icon(
            Icons.monitor_weight_outlined,
            color: AppColors.labelSecondary.withAlpha(150),
            size: 32,
          ),
          const SizedBox(height: SpacingTokens.sm),
          const Text('Registre seu primeiro peso', style: AppTheme.cardTitle),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            'Acompanhe a evolução de seu peso ao longo do tempo',
            style: AppTheme.cardSubtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacingTokens.md),
          ElevatedButton.icon(
            onPressed: onAdicionarPeso,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Registrar agora'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: CardTokens.padding,
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: AppColors.surfaceDark,
            highlightColor: AppColors.surfaceDark.withAlpha(150),
            child: Container(
              height: 36,
              width: 120,
              decoration: BoxDecoration(
                color: AppColors.labelSecondary.withAlpha(30),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          Shimmer.fromColors(
            baseColor: AppColors.surfaceDark,
            highlightColor: AppColors.surfaceDark.withAlpha(150),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.labelSecondary.withAlpha(30),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
