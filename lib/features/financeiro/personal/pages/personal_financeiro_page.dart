import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../../../core/widgets/app_bar_text_button.dart';
import '../../../alunos/shared/widgets/app_avatar.dart';

/// Cockpit Financeiro - Uma visão executiva e de alta performance das finanças do Personal Trainer.
class PersonalFinanceiroPage extends StatefulWidget {
  const PersonalFinanceiroPage({super.key});

  @override
  State<PersonalFinanceiroPage> createState() => _PersonalFinanceiroPageState();
}

class _PersonalFinanceiroPageState extends State<PersonalFinanceiroPage> {
  // Mock Data
  final double mrr = 12450.0;
  final double recebido = 8500.0;
  final double aReceber = 2750.0;
  final double emAtraso = 1200.0;

  final List<Map<String, dynamic>> inadimplentes = [
    {'nome': 'Carlos Silva', 'vencimento': '05/05', 'valor': 400.0, 'foto': null},
    {'nome': 'Mariana Souza', 'vencimento': '10/05', 'valor': 800.0, 'foto': null},
  ];

  final List<Map<String, dynamic>> timeline = [
    {'tipo': 'RECEBIDO', 'nome': 'João Pedro', 'data': 'Hoje', 'valor': 450.0, 'metodo': 'PIX'},
    {'tipo': 'RECEBIDO', 'nome': 'Ana Clara', 'data': 'Ontem', 'valor': 400.0, 'metodo': 'CARTÃO'},
    {'tipo': 'PREVISTO', 'nome': 'Felipe Costa', 'data': 'Amanhã', 'valor': 500.0, 'metodo': 'PIX'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Atmosfera Superior (Glow sutil)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: SpacingTokens.atmosphereHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.accentMetrics.withValues(alpha: GlassTokens.opacityAtmosphere),
                    AppColors.accentMetrics.withValues(alpha: GlassTokens.opacityAtmosphereSubtle),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(CupertinoIcons.back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'COCKPIT FINANCEIRO',
                  style: AppTheme.pageTitle,
                ),
                centerTitle: true,
                actions: [
                  AppBarTextButton(
                    label: 'MAI 2026',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // Modal de seleção de mês (mock)
                    },
                  ),
                ],
              ),

              // Console de Vidro Infinito
              SliverFillRemaining(
                hasScrollBody: false,
                fillOverscroll: true,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: GlassTokens.consoleMarginH),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: GlassTokens.opacityConsole),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(GlassTokens.consoleRadius),
                      topRight: Radius.circular(GlassTokens.consoleRadius),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.white.withValues(alpha: GlassTokens.opacityBorder), width: 1),
                      left: BorderSide(color: Colors.white.withValues(alpha: GlassTokens.opacityBorder), width: 1),
                      right: BorderSide(color: Colors.white.withValues(alpha: GlassTokens.opacityBorder), width: 1),
                      bottom: BorderSide.none,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Secão 1: MRR & Meta
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MRR (RECEITA MENSAL RECORRENTE)',
                              style: AppTheme.technicalLabel.copyWith(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'R\$ ${mrr.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppColors.accentMetrics,
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                letterSpacing: -1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Divisor
                      Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),

                      // Secão 2: Distribuição do Fluxo
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DISTRIBUIÇÃO DE FLUXO',
                              style: AppTheme.technicalLabel.copyWith(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Barra Segmentada
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: recebido.toInt(),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    flex: aReceber.toInt(),
                                    child: Container(
                                      color: Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    flex: emAtraso.toInt(),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.systemRed,
                                        borderRadius: const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildLegendItem('RECEBIDO', recebido, AppColors.primary),
                                _buildLegendItem('A RECEBER', aReceber, Colors.white.withValues(alpha: 0.4)),
                                _buildLegendItem('EM ATRASO', emAtraso, AppColors.systemRed),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Divisor
                      Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),

                      // Secão 3: Inadimplência
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        title: 'RADAR DE INADIMPLÊNCIA',
                        onAction: () {
                          HapticFeedback.heavyImpact();
                          // Simulação de ação global
                        },
                        actionLabel: 'COBRAR TODOS',
                        actionColor: AppColors.systemRed,
                      ),
                      ...inadimplentes.map((aluno) => _buildInadimplenteItem(aluno)),

                      // Divisor
                      const SizedBox(height: 16),
                      Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),

                      // Secão 4: Timeline Financeira
                      const SizedBox(height: 24),
                      _buildSectionHeader(title: 'TIMELINE FINANCEIRA'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: timeline.map((event) => _buildTimelineItem(event)).toList(),
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: 120), // Buffer infinito
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.technicalLabel.copyWith(
                fontSize: 7,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'R\$ ${value.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildInadimplenteItem(Map<String, dynamic> aluno) {
    return AppTappable(
      onPressed: () {
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03), width: 1),
          ),
        ),
        child: Row(
          children: [
            AppAvatar(name: aluno['nome'], photoUrl: aluno['foto'], radius: 20, showBorder: false),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aluno['nome'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 10, color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(width: 4),
                      Text(
                        'VENCEU ${aluno['vencimento']}',
                        style: AppTheme.technicalLabel.copyWith(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              'R\$ ${aluno['valor'].toStringAsFixed(0)}',
              style: TextStyle(
                color: AppColors.systemRed,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> event) {
    final bool isRecebido = event['tipo'] == 'RECEBIDO';
    final Color dotColor = isRecebido ? AppColors.accentMetrics : Colors.white.withValues(alpha: 0.2);
    final IconData icon = isRecebido ? Icons.check_circle_rounded : Icons.schedule_rounded;

    return IntrinsicHeight(
      child: Row(
        children: [
          // Eixo da Timeline
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Icon(icon, size: 16, color: dotColor),
                Expanded(
                  child: Container(
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.1),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Conteúdo do Evento
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['nome'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              event['tipo'],
                              style: AppTheme.technicalLabel.copyWith(
                                color: dotColor,
                                fontSize: 8,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(width: 3, height: 3, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(
                              event['data'].toString().toUpperCase(),
                              style: AppTheme.technicalLabel.copyWith(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+ R\$ ${event['valor'].toStringAsFixed(0)}',
                        style: TextStyle(
                          color: isRecebido ? Colors.white : Colors.white.withValues(alpha: 0.4),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event['metodo'],
                          style: AppTheme.technicalLabel.copyWith(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, VoidCallback? onAction, String? actionLabel, Color? actionColor}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTheme.sectionHeader,
          ),
          if (onAction != null && actionLabel != null)
            AppTappable(
              onPressed: onAction,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  actionLabel,
                  style: AppTheme.technicalLabel.copyWith(
                    color: actionColor ?? AppColors.primary.withValues(alpha: 0.5),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}