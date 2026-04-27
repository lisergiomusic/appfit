import 'package:flutter/material.dart';
import '../../../../core/widgets/app_section_link_button.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/rotina_service.dart';
import '../../../treinos/personal/pages/personal_rotina_detalhe_page.dart';
import '../../personal/pages/personal_gerenciar_planilhas_page.dart';

class FichaAtivaHeroCard extends StatefulWidget {
  final String alunoId;
  final String alunoNome;
  final String? photoUrl;
  final String peso;
  final String idade;
  final Map<String, dynamic>? rotinaAtiva;
  final String? rotinaId;
  final VoidCallback onPrescreverTreino;

  const FichaAtivaHeroCard({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    this.photoUrl,
    required this.peso,
    required this.idade,
    required this.rotinaAtiva,
    required this.rotinaId,
    required this.onPrescreverTreino,
  });

  @override
  State<FichaAtivaHeroCard> createState() => _FichaAtivaHeroCardState();
}

class _FichaAtivaHeroCardState extends State<FichaAtivaHeroCard> {
  late final RotinaService _rotinaService;

  @override
  void initState() {
    super.initState();
    _rotinaService = RotinaService();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rotinaAtiva == null || widget.rotinaId == null) {
      return _buildEmptyState();
    }

    final rotina = widget.rotinaAtiva!;
    final rotinaId = widget.rotinaId!;

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
      final dataCriacaoRaw = rotina['dataCriacao'];
      final dataVencimentoRaw = rotina['dataVencimento'];
      
      DateTime dataCriacao = dataCriacaoRaw != null ? DateTime.tryParse(dataCriacaoRaw.toString()) ?? hoje : hoje;
      DateTime dataVencimento = dataVencimentoRaw != null ? DateTime.tryParse(dataVencimentoRaw.toString()) ?? hoje.add(const Duration(days: 30)) : hoje.add(const Duration(days: 30));

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
                    builder: (context) => PersonalGerenciarPlanilhasPage(
                      alunoId: widget.alunoId,
                      alunoNome: widget.alunoNome,
                      photoUrl: widget.photoUrl,
                      peso: widget.peso,
                      idade: widget.idade,
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
                  builder: (context) => PersonalRotinaDetalhePage(
                    rotinaData: rotina,
                    rotinaId: rotinaId,
                    alunoId: widget.alunoId,
                    alunoNome: widget.alunoNome,
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
                          backgroundColor: AppColors.primary.withAlpha(15),
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
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.labelSecondary.withAlpha(80),
                      size: 24,
                    ),
                    color: AppColors.surfaceDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusLarge,
                      ),
                    ),
                    onSelected: (value) {
                      if (value == 'editar') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PersonalRotinaDetalhePage(
                              rotinaData: rotina,
                              rotinaId: rotinaId,
                              alunoId: widget.alunoId,
                              alunoNome: widget.alunoNome,
                            ),
                          ),
                        );
                      } else if (value == 'remover') {
                        _confirmarRemoverRotina(context, rotinaId);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 18),
                            SizedBox(width: 10),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'remover',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Remover',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmarRemoverRotina(
    BuildContext context,
    String rotinaId,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        title: const Text(
          'Remover planilha?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Essa ação remove a planilha permanentemente.',
          style: TextStyle(color: AppColors.labelSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.labelSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Remover',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await _rotinaService.excluirRotina(rotinaId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover planilha: $e')),
      );
    }
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Planilha atual', style: AppTheme.sectionHeader),
        const SizedBox(height: SpacingTokens.labelToField),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: CardTokens.cardRadius,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPrescreverTreino,
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