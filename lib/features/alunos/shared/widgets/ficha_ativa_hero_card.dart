import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/app_section_link_button.dart';
import '../../../../core/widgets/app_tappable.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/rotina_service.dart';
import '../../../treinos/personal/pages/personal_rotina_detalhe_page.dart';
import '../../personal/pages/personal_gerenciar_planilhas_page.dart';

/// Card principal que exibe o resumo da planilha (rotina) ativa do aluno.
/// Implementa telemetria de progresso (conclusão por sessões ou tempo) com estética Neo-Industrial.
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
    // Se não houver planilha ativa, renderiza o "Hardware Slot" vazio.
    if (widget.rotinaAtiva == null || widget.rotinaId == null) {
      return _buildEmptyState();
    }

    final rotina = widget.rotinaAtiva!;
    final rotinaId = widget.rotinaId!;

    // Cálculo da telemetria de progresso baseada no tipo de vencimento.
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
            const Text(
              'PLANILHA ATUAL',
              style: AppTheme.sectionHeader,
            ),
            const Spacer(),
            AppSectionLinkButton(
              label: 'HISTÓRICO',
              onPressed: () {
                HapticFeedback.lightImpact();
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
        const SizedBox(height: SpacingTokens.md),
        // Módulo de telemetria integrado com animação de preenchimento.
        AppTappable(
          onPressed: () {
            HapticFeedback.lightImpact();
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
          child: Container(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: GlassTokens.opacitySurface),
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(
                color: Colors.white.withValues(alpha: GlassTokens.opacityBorder),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Indicador de progresso circular animado.
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0, end: progressoAtual),
                        builder: (context, value, child) {
                          return CircularProgressIndicator(
                            value: value,
                            strokeWidth: 2,
                            backgroundColor: Colors.white.withValues(alpha: GlassTokens.opacityAtmosphereSubtle),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          );
                        },
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0, end: progressoAtual),
                      builder: (context, value, child) {
                        return Text(
                          '${(value * 100).toInt()}%',
                          style: AppTheme.telemetryValue,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(width: SpacingTokens.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (rotina['nome'] ?? 'Ficha de Treino').toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 10,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(width: SpacingTokens.xs),
                          Text(
                            legendaVencimento.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white.withValues(alpha: 0.4),
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.2),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Constrói o estado vazio técnico ("Hardware Slot") quando não há planilha vinculada.
  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'PLANILHA ATUAL',
              style: AppTheme.sectionHeader,
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.md),
        AppTappable(
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onPrescreverTreino();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SpacingTokens.xxl),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: GlassTokens.opacitySurface),
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(
                color: Colors.white.withValues(alpha: GlassTokens.opacityBorder),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Soquete visual circular pontilhado para indicar slot disponível.
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: GlassTokens.opacityHighBorder),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.add,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(width: SpacingTokens.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NENHUMA PLANILHA ATIVA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.xs),
                      Text(
                        'CLIQUE PARA PRESCREVER',
                        style: AppTheme.telemetryValue.copyWith(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          fontSize: 9,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}