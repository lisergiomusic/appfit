import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/app_section_link_button.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../treinos/rotina_detalhe_page.dart';
import '../../../core/services/aluno_service.dart';
import '../gerenciar_planilhas_page.dart';

class FichaAtivaHeroCard extends StatelessWidget {
  final String alunoId;
  final String alunoNome;
  final String? photoUrl;
  final String peso;
  final String idade;
  final VoidCallback onPrescreverTreino;

  const FichaAtivaHeroCard({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    this.photoUrl,
    required this.peso,
    required this.idade,
    required this.onPrescreverTreino,
  });

  @override
  Widget build(BuildContext context) {
    final AlunoService alunoService = AlunoService();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen),
      child: StreamBuilder<QuerySnapshot>(
        stream: alunoService.getRotinaAtivaStream(alunoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          var treinoDoc = snapshot.data!.docs.first;
          var rotina = treinoDoc.data() as Map<String, dynamic>;
          String objetivo = rotina['objetivo'] ?? 'Objetivo não definido';

          String tipoVencimento = rotina['tipoVencimento'] ?? 'data';
          double progressoAtual = 0.0;
          String legendaVencimento = '';

          if (tipoVencimento == 'sessoes') {
            int totalSessoes = rotina['vencimentoSessoes'] ?? 1;
            int concluidas = rotina['sessoesConcluidas'] ?? 0;
            progressoAtual = (concluidas / totalSessoes).clamp(0.0, 1.0);
            legendaVencimento =
                '$concluidas de $totalSessoes ${totalSessoes == 1 ? 'sessão' : 'sessões'}';
          } else {
            DateTime hoje = DateTime.now();
            DateTime dataCriacao =
                (rotina['dataCriacao'] as Timestamp?)?.toDate() ?? hoje;
            DateTime dataVencimento =
                (rotina['dataVencimento'] as Timestamp?)?.toDate() ??
                hoje.add(const Duration(days: 30));
            int totalDias = dataVencimento.difference(dataCriacao).inDays;
            if (totalDias <= 0) totalDias = 1;
            int diasPassados = hoje.difference(dataCriacao).inDays;
            progressoAtual = (diasPassados / totalDias).clamp(0.0, 1.0);
            legendaVencimento =
                'Vencimento em ${DateFormat('dd/MM').format(dataVencimento)}';
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Planilha atual', style: AppTheme.sectionHeader),
                  const Spacer(),
                  AppSectionLinkButton(
                    label: 'Ver todas',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GerenciarPlanilhasPage(
                            alunoId: alunoId,
                            alunoNome: alunoNome,
                            photoUrl: photoUrl,
                            peso: peso,
                            idade: idade,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: AppTheme.cardDecoration,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RotinaDetalhePage(
                          rotinaData: rotina,
                          rotinaId: treinoDoc.id,
                          alunoId: alunoId,
                          alunoNome: alunoNome,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                value: progressoAtual,
                                strokeWidth: 6,
                                backgroundColor: AppColors.primary.withAlpha(
                                  15,
                                ),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            const Icon(
                              Icons.fitness_center_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rotina['nome'] ?? 'Ficha de Treino',
                                style: CardTokens.cardTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                objetivo,
                                style: AppTheme.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                legendaVencimento,
                                style: AppTheme.caption2.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.labelSecondary.withAlpha(80),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Planilha atual',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.labelPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: CardTokens.cardRadius,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPrescreverTreino,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Prescrever novo treino',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'O aluno ainda não possui uma ficha ativa',
                      style: TextStyle(
                        color: AppColors.labelSecondary.withAlpha(150),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
