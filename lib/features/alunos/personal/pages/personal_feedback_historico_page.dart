import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/treino_service.dart';
import '../../../../core/theme/app_theme.dart';

class PersonalFeedbackHistoricoPage extends StatefulWidget {
  final String alunoId;
  final String alunoNome;

  const PersonalFeedbackHistoricoPage({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  State<PersonalFeedbackHistoricoPage> createState() =>
      _PersonalFeedbackHistoricoPageState();
}

class _PersonalFeedbackHistoricoPageState
    extends State<PersonalFeedbackHistoricoPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _future = TreinoService().fetchLogsAluno(widget.alunoId);
  }

  void _retry() => setState(_carregar);

  String _labelEsforco(int v) {
    if (v <= 3) return 'Fácil';
    if (v <= 5) return 'Moderado';
    if (v <= 7) return 'Intenso';
    if (v <= 9) return 'Muito intenso';
    return 'Exaustivo';
  }

  Color _corEsforco(int v) {
    if (v <= 5) return AppColors.primary;
    if (v <= 7) return AppColors.accentMetrics;
    if (v <= 9) return const Color(0xFFFF6B35);
    return AppColors.systemRed;
  }

  String _formatarData(dynamic dataHora) {
    if (dataHora == null) return '';
    final dt = (dataHora as Timestamp).toDate();
    final hoje = DateTime.now();
    final ontem = hoje.subtract(const Duration(days: 1));
    if (dt.year == hoje.year && dt.month == hoje.month && dt.day == hoje.day) {
      return 'Hoje, ${DateFormat('dd MMM', 'pt_BR').format(dt)}';
    }
    if (dt.year == ontem.year &&
        dt.month == ontem.month &&
        dt.day == ontem.day) {
      return 'Ontem, ${DateFormat('dd MMM', 'pt_BR').format(dt)}';
    }
    return DateFormat('dd MMM yyyy', 'pt_BR').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Histórico de Feedbacks',
          style: TextStyle(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final logs = (snapshot.data ?? [])
              .where((log) => (log['esforco'] as int? ?? 0) > 0)
              .toList();

          if (logs.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) => _buildTimelineItem(
              logs[index],
              index == logs.length - 1,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> log, bool isLast) {
    final esforco = log['esforco'] as int;
    final sessaoNome = log['sessaoNome'] as String? ?? 'Treino';
    final observacoes = log['observacoes'] as String?;
    final dataFormatada = _formatarData(log['dataHora']);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _corEsforco(esforco),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.white.withAlpha(13)),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(13)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dataFormatada,
                        style: const TextStyle(
                          color: AppColors.labelSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildEsforcoBadge(esforco),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sessaoNome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (observacoes != null && observacoes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      observacoes,
                      style: TextStyle(
                        color: AppColors.labelSecondary.withAlpha(200),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEsforcoBadge(int esforco) {
    final cor = _corEsforco(esforco);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$esforco/10 ${_labelEsforco(esforco)}',
        style: TextStyle(
          color: cor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Nenhum feedback registrado ainda.',
        style: TextStyle(color: AppColors.labelSecondary),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Erro ao carregar feedbacks.',
            style: TextStyle(color: AppColors.labelSecondary),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            label: const Text(
              'Tentar novamente',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
