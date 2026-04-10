import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PersonalFeedbackHistoricoPage extends StatelessWidget {
  final String alunoNome;

  const PersonalFeedbackHistoricoPage({super.key, required this.alunoNome});

  @override
  Widget build(BuildContext context) {
    // Mapa de seções da interface desta página:
    // 1) Estrutura superior: AppBar, título e ações de navegação.
    // 2) Conteúdo principal: blocos, listas, cards e estados da tela.
    // 3) Ações finais: botões primários, confirmadores e feedbacks.
    final List<Map<String, dynamic>> historico = [
      {
        'data': 'Hoje, 02 Mar',
        'treino': 'Treino A - Superiores',
        'esforço': '8/10',
        'status': 'Intenso',
        'comentario': 'Aumentei a carga no supino, senti um pouco o ombro.',
      },
      {
        'data': '28 Fev',
        'treino': 'Treino C - Core e Cardio',
        'esforço': '6/10',
        'status': 'Moderado',
        'comentario': 'Treino rendeu bem, cardio finalizado com sucesso.',
      },
      {
        'data': '26 Fev',
        'treino': 'Treino B - Inferiores',
        'esforço': '10/10',
        'status': 'Exaustivo',
        'comentario': 'Leg press foi no limite hoje. Pernas bambas!',
      },
    ];

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
      body: historico.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: historico.length,
              itemBuilder: (context, index) => _buildTimelineItem(
                historico[index],
                index == historico.length - 1,
              ),
            ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
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
                        item['data'],
                        style: const TextStyle(
                          color: AppColors.labelSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildEsforcoBadge(item['esforço'], item['status']),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['treino'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (item['comentario'] != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      item['comentario'],
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

  Widget _buildEsforcoBadge(String valor, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$valor $status',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Nenhum feedback registrado ainda.',
        style: TextStyle(color: AppColors.labelSecondary),
      ),
    );
  }
}
