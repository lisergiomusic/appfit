import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/appfit_sliver_app_bar.dart';
import 'models/rotina_model.dart';
import 'sessao_detalhe_aluno_page.dart';
import 'widgets/rotina_sessao_card.dart';

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
    _rotina = RotinaModel.fromFirestore(widget.rotinaData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          AppFitSliverAppBar(
            title: _rotina.nome,
            expandedHeight: _rotina.objetivo.isNotEmpty ? 148 : 120,
            background: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: SpacingTokens.screenHorizontalPadding,
                  right: SpacingTokens.screenHorizontalPadding,
                  bottom: SpacingTokens.sectionGap,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_rotina.nome, style: AppTheme.title1),
                    if (_rotina.objetivo.isNotEmpty) ...[
                      const SizedBox(height: SpacingTokens.titleToSubtitle),
                      Text(_rotina.objetivo, style: AppTheme.cardSubtitle),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingScreen,
                vertical: 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildProgressSection()],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.screenHorizontalPadding,
              ),
              child: Text('Sessões de Treino', style: AppTheme.sectionHeader),
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
      final dataCriacao =
          (widget.rotinaData['dataCriacao'] as dynamic)?.toDate() ?? hoje;
      final dataVencimento =
          (widget.rotinaData['dataVencimento'] as dynamic)?.toDate() ??
          hoje.add(const Duration(days: 30));
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
            Text('Progresso', style: AppTheme.sectionHeader),
            Text(
              legenda,
              style: AppTheme.caption2.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progresso,
            minHeight: 6,
            backgroundColor: AppColors.primary.withAlpha(15),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: SpacingTokens.sectionGap),
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
            builder: (context) => SessaoDetalheViewPage(
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
