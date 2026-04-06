import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bar_divider.dart';
import 'models/rotina_model.dart';
import 'models/exercicio_model.dart';
import 'executar_treino_page.dart';

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
  int? _expandedSessionIndex;

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
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.background,
            bottom: const AppBarDivider(),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _rotina.nome,
                style: AppTheme.title1,
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingScreen,
                vertical: SpacingTokens.sectionGap,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_rotina.objetivo.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Objetivo', style: AppTheme.formLabel),
                        const SizedBox(height: SpacingTokens.sm),
                        Text(
                          _rotina.objetivo,
                          style: AppTheme.cardSubtitle,
                        ),
                        const SizedBox(height: SpacingTokens.sectionGap),
                      ],
                    ),
                  _buildProgressSection(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.paddingScreen,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final sessao = _rotina.sessoes[index];
                  final isExpanded = _expandedSessionIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                    child: _buildSessionCard(
                      sessao: sessao,
                      index: index,
                      isExpanded: isExpanded,
                    ),
                  );
                },
                childCount: _rotina.sessoes.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: SpacingTokens.screenBottomPadding,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final tipoVencimento = widget.rotinaData['tipoVencimento'] as String? ?? 'data';
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
            Text('Progresso', style: AppTheme.formLabel),
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
    required int index,
    required bool isExpanded,
  }) {
    final letra = String.fromCharCode(65 + (index % 26));

    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedSessionIndex = isExpanded ? null : index;
              });
            },
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusXL),
              topRight: Radius.circular(AppTheme.radiusXL),
              bottomLeft: Radius.circular(isExpanded ? 0 : AppTheme.radiusXL),
              bottomRight: Radius.circular(isExpanded ? 0 : AppTheme.radiusXL),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      letra,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sessao.nome,
                          style: AppTheme.cardTitle,
                        ),
                        if (sessao.diaSemana != null && sessao.diaSemana!.isNotEmpty)
                          Text(
                            sessao.diaSemana!,
                            style: AppTheme.caption,
                          ),
                        Text(
                          '${sessao.exercicios.length} exercício${sessao.exercicios.length != 1 ? 's' : ''}',
                          style: AppTheme.caption2.copyWith(
                            color: AppColors.labelSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.labelSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.primary.withAlpha(15),
                  ),
                ),
              ),
              child: Column(
                children: [
                  if (sessao.orientacoes != null && sessao.orientacoes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(30),
                          ),
                        ),
                        child: Text(
                          sessao.orientacoes!,
                          style: AppTheme.bodyText,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: List.generate(
                        sessao.exercicios.length,
                        (exIndex) => _buildExerciseItem(
                          sessao.exercicios[exIndex],
                          exIndex,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExecutarTreinoPage(
                                sessao: sessao,
                                rotinaId: widget.rotinaId,
                                alunoId: widget.alunoId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Iniciar treino'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(ExercicioItem exercise, int exIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.nome,
            style: AppTheme.cardTitle,
          ),
          if (exercise.grupoMuscular.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                children: exercise.grupoMuscular
                    .map(
                      (grupo) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          grupo,
                          style: AppTheme.caption2,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: List.generate(
                exercise.series.length,
                (sIndex) {
                  final serie = exercise.series[sIndex];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            'S${sIndex + 1}',
                            style: AppTheme.caption2.copyWith(
                              color: AppColors.labelSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${serie.alvo} reps | ${serie.carga}kg | ${serie.descanso}s',
                            style: AppTheme.bodyText,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (exIndex < exercise.series.length - 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Divider(
                color: AppColors.primary.withAlpha(15),
                height: 1,
              ),
            ),
        ],
      ),
    );
  }
}
