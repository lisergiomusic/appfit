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

    final pesoStr = pesoAtual != null
        ? '${pesoAtual!.toStringAsFixed(1)} kg'
        : 'Sem registros';

    final dataPrimeira =
        datas.isNotEmpty ? DateFormat('dd/MM', 'pt_BR').format(datas.first) : '';
    final dataUltima =
        datas.isNotEmpty ? DateFormat('dd/MM', 'pt_BR').format(datas.last) : '';
    final rangeLabel = datas.length > 1 ? '$dataPrimeira · $dataUltima' : 'Sem histórico';

    return Container(
      decoration: AppTheme.cardDecoration,
      padding: CardTokens.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Peso', style: AppTheme.caption2),
                  const SizedBox(height: SpacingTokens.xs),
                  Text(pesoStr, style: AppTheme.cardTitle),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded),
                color: AppColors.primary,
                onPressed: onAdicionarPeso,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ),
          if (pesos.isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.md),
            SizedBox(
              height: 50,
              child: CustomPaint(
                painter: SparkLinePainter(
                  pesos: pesos,
                  color: AppColors.primary,
                ),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Text(
              rangeLabel,
              style: AppTheme.caption2.copyWith(
                color: AppColors.labelSecondary.withAlpha(150),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: CardTokens.padding,
      child: Row(
        children: [
          Icon(
            Icons.monitor_weight_outlined,
            color: AppColors.labelSecondary,
            size: 20,
          ),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: AppColors.surfaceDark,
              highlightColor: AppColors.surfaceDark.withAlpha(150),
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.labelSecondary.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
