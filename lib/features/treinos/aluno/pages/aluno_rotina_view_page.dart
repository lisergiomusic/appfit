import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/appfit_sliver_app_bar.dart';
import '../../shared/models/rotina_model.dart';
import '../../shared/widgets/rotina_sessao_card.dart';
import 'aluno_sessao_detalhe_page.dart';

class AlunoRotinaViewPage extends StatefulWidget {
  final Map<String, dynamic> rotinaData;
  final String rotinaId;
  final String alunoId;

  const AlunoRotinaViewPage({
    super.key,
    required this.rotinaData,
    required this.rotinaId,
    required this.alunoId,
  });

  @override
  State<AlunoRotinaViewPage> createState() => _AlunoRotinaViewPageState();
}

class _AlunoRotinaViewPageState extends State<AlunoRotinaViewPage> {
  late RotinaModel _rotina;

  @override
  void initState() {
    super.initState();
    _rotina = RotinaModel.fromMap(widget.rotinaData);
  }

  @override
  Widget build(BuildContext context) {
    // Mapa de seções da interface desta página:
    // 1) Estrutura superior: AppBar, título e ações de navegação.
    // 2) Conteúdo principal: blocos, listas, cards e estados da tela.
    // 3) Ações finais: botões primários, confirmadores e feedbacks.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: _rotina.objetivo.isNotEmpty ? 140 : 120,
            collapsedHeight: 70,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: BackButton(color: AppColors.labelPrimary),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
              background: Container(
                decoration: BoxDecoration(gradient: AppTheme.premiumGradient),
              ),
              titlePadding: const EdgeInsets.only(left: SpacingTokens.screenHorizontalPadding, bottom: 16),
              centerTitle: false,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _rotina.nome,
                    style: AppTheme.pageTitle.copyWith(fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_rotina.objetivo.isNotEmpty)
                    Text(
                      _rotina.objetivo.toUpperCase(),
                      style: AppTheme.premiumLabel.copyWith(
                        fontSize: 7,
                        color: AppColors.labelSecondary.withAlpha(150),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.screenHorizontalPadding,
              ),
              child: Text('PROGRESSO', style: AppTheme.sectionHeader),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: SpacingTokens.labelToField)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingScreen,
              ),
              child: _buildProgressSection(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.screenHorizontalPadding,
              ),
              child: Text('SESSÕES DE TREINO', style: AppTheme.sectionHeader),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: SpacingTokens.labelToField),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.paddingScreen,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final sessao = _rotina.sessoes[index];
                final letra = String.fromCharCode(65 + index);

                return Padding(
                  padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                  child: _buildSessionCard(
                    sessao: sessao,
                    letra: letra,
                    index: index,
                  ),
                );
              }, childCount: _rotina.sessoes.length),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: SpacingTokens.screenBottomPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final tipoVencimento =
        widget.rotinaData['tipoVencimento'] as String? ?? 'data';
    String legenda = '';
    double progresso = 0.0;

    if (tipoVencimento == 'sessoes') {
      final total = (widget.rotinaData['vencimentoSessoes'] as int?) ?? 1;
      final concluidas = (widget.rotinaData['sessoesConcluidas'] as int?) ?? 0;
      progresso = (concluidas / total).clamp(0.0, 1.0);
      legenda = '$concluidas de $total ${total == 1 ? 'sessão' : 'sessões'}';
    } else {
      final hoje = DateTime.now();
      final dataCriacao = widget.rotinaData['dataCriacao'] != null
          ? DateTime.tryParse(widget.rotinaData['dataCriacao'].toString()) ?? hoje
          : hoje;
      final dataVencimento = widget.rotinaData['dataVencimento'] != null
          ? DateTime.tryParse(widget.rotinaData['dataVencimento'].toString()) ??
              hoje.add(const Duration(days: 30))
          : hoje.add(const Duration(days: 30));
      int totalDias = dataVencimento.difference(dataCriacao).inDays;
      if (totalDias <= 0) totalDias = 1;
      final diasPassados = hoje.difference(dataCriacao).inDays;
      progresso = (diasPassados / totalDias).clamp(0.0, 1.0);
      legenda = 'Vencimento em ${DateFormat('dd/MM').format(dataVencimento)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              legenda.toUpperCase(),
              style: AppTheme.premiumLabel.copyWith(
                color: AppColors.primary,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '${(progresso * 100).toInt()}%',
              style: AppTheme.premiumLabel.copyWith(
                color: AppColors.labelSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progresso,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(100),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.xxl),
      ],
    );
  }

  Widget _buildSessionCard({
    required SessaoTreinoModel sessao,
    required String letra,
    required int index,
  }) {
    return RotinaSessaoCard(
      sessao: sessao,
      index: index,
      isReordering: false,
      onOpen: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlunoSessaoDetalhePage(
              sessao: sessao,
              letra: letra,
              rotinaId: widget.rotinaId,
              alunoId: widget.alunoId,
            ),
          ),
        );
      },
      readOnly: true,
    );
  }
}