import 'package:flutter/material.dart';
import '../../models/rotina_model.dart';
import '../../models/exercicio_model.dart';
import '../../models/historico_treino_model.dart';
import '../../../../../core/theme/app_theme.dart';
import 'exercicio_section_header.dart'
    show ExercicioSectionHeader, ExercicioMenuAction;
import 'workout_set_row.dart';
import 'orientacao_personal_banner.dart';

/// Renderiza a lista completa de exercícios da sessão em execução.
class TreinoScrollableBody extends StatelessWidget {
  final SessaoTreinoModel sessao;

  final Map<String, dynamic> recordedData;

  final List<List<TextEditingController>> repsControllers;

  final List<List<TextEditingController>> pesoControllers;

  final void Function(int exercicioIndex, int serieIndex) onSerieCompleted;
  final void Function(String exercicioNome, List<SerieHistorico> historico) onVerHistorico;
  final void Function(int exercicioIndex) onSwapExercise;

  final String? alunoId;

  final Map<String, List<SerieHistorico>> ultimoHistorico;

  const TreinoScrollableBody({
    super.key,
    required this.sessao,
    required this.recordedData,
    required this.repsControllers,
    required this.pesoControllers,
    required this.onSerieCompleted,
    required this.onVerHistorico,
    required this.onSwapExercise,
    this.alunoId,
    this.ultimoHistorico = const {},
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: SpacingTokens.screenTopPadding,
          bottom: 128,
        ),
        itemCount: sessao.exercicios.length,
        itemBuilder: (context, exIdx) {
          final exercicio = sessao.exercicios[exIdx];
          final exData = recordedData['exercicio_$exIdx'] ?? {'series': []};
          final seriesList = (exData['series'] as List?) ?? [];

          return Padding(
            padding: const EdgeInsets.fromLTRB(
              SpacingTokens.lg,
              0,
              SpacingTokens.lg,
              SpacingTokens.listItemGap,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExercicioSectionHeader(
                    exercicio: exercicio,
                    exIdx: exIdx,
                    alunoId: alunoId,
                    onSwap: () => onSwapExercise(exIdx),
                    onMenuAction: (action) {
                      if (action == ExercicioMenuAction.verUltimoTreino) {
                        onVerHistorico(
                          exercicio.nome,
                          ultimoHistorico[exercicio.nome] ?? [],
                        );
                      }
                    },
                  ),
                  if (exercicio.instrucoesParaExibicao != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.lg,
                      ),
                      child: OrientacaoPersonalBanner(
                        orientacao: exercicio.instrucoesParaExibicao,
                      ),
                    ),
                  const SizedBox(height: SpacingTokens.sm),
                  _ColumnLabelsRow(),
                  const SizedBox(height: SpacingTokens.xs),
                  ..._buildSetsWithContextualRest(exercicio, exIdx, seriesList),
                  const SizedBox(height: SpacingTokens.xs),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSetsWithContextualRest(ExercicioItem exercicio, int exIdx, List seriesList) {
    final List<Widget> widgets = [];
    final rests = exercicio.series.map((s) => s.descanso.trim()).toSet();
    final isUniformRest = rests.length == 1;
    final standardRestOverall = rests.isNotEmpty ? rests.first : '60s';

    for (int i = 0; i < exercicio.series.length; i++) {
      final isCompleted = seriesList.length > i ? (seriesList[i] as Map)['completa'] == true : false;
      final serieAtual = exercicio.series[i];
      final indexDentroDoTipo = exercicio.series.take(i).where((s) => s.tipo == serieAtual.tipo).length;
      final historicoDoExercicio = ultimoHistorico[exercicio.nome] ?? [];
      final historicoSerie = historicoDoExercicio.firstWhere(
        (h) => h.tipo == serieAtual.tipo && h.indexDentroDoTipo == indexDentroDoTipo,
        orElse: () => SerieHistorico(tipo: serieAtual.tipo, indexDentroDoTipo: indexDentroDoTipo),
      );

      widgets.add(
        WorkoutSetRow(
          serie: serieAtual,
          visualIndex: _calcWorkIndex(exercicio, i),
          repsController: repsControllers[exIdx][i],
          pesoController: pesoControllers[exIdx][i],
          isCompleted: isCompleted,
          onCheck: () => onSerieCompleted(exIdx, i),
          historico: historicoSerie,
        ),
      );

      // Lógica de Bloco: Verifica se a próxima série é de tipo diferente ou se é a última
      final bool isLastOfBlock = (i == exercicio.series.length - 1) || (exercicio.series[i + 1].tipo != serieAtual.tipo);

      if (isLastOfBlock) {
        final bool isLastOverall = i == exercicio.series.length - 1;
        widgets.add(_buildBlockRestFooter(serieAtual.descanso, isLastOverall, serieAtual.tipo));
      }
    }

    return widgets;
  }

  Widget _buildBlockRestFooter(String rest, bool isLastOverall, TipoSerie tipo) {
    final cleanRest = RegExp(r'^\d+$').hasMatch(rest) ? '${rest}s' : rest;
    final label = tipo == TipoSerie.aquecimento ? "Aquecimento" : "Trabalho";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: isLastOverall
              ? Border(
                  top: BorderSide(
                    color: AppColors.labelPrimary.withAlpha(20),
                    width: 0.5,
                  ),
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 14,
              color: AppColors.labelSecondary.withAlpha(isLastOverall ? 180 : 120),
            ),
            const SizedBox(width: 6),
            Text(
              'Descanso ($label): $cleanRest',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isLastOverall ? FontWeight.w600 : FontWeight.w400,
                color: AppColors.labelSecondary.withAlpha(isLastOverall ? 180 : 120),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calcWorkIndex(ExercicioItem exercicio, int upToIdx) {
    int count = 0;

    for (int i = 0; i <= upToIdx; i++) {
      if (exercicio.series[i].tipo == TipoSerie.trabalho) count++;
    }
    return count;
  }
}

/// Cabeçalho fixo das colunas usadas em cada linha de série.
class _ColumnLabelsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: AppColors.labelTertiary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.screenHorizontalPadding,
      ),
      child: Row(
        children: const [
          SizedBox(
            width: 36,
            child: Text(
              'SÉRIE',
              style: labelStyle,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: SpacingTokens.md),
          SizedBox(
            width: 52,
            child: Text('ALVO', style: labelStyle, textAlign: TextAlign.center),
          ),
          SizedBox(width: SpacingTokens.md),

          Expanded(
            child: Text('REPS', style: labelStyle, textAlign: TextAlign.center),
          ),
          SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Text('KG', style: labelStyle, textAlign: TextAlign.center),
          ),
          SizedBox(width: SpacingTokens.sm),
          SizedBox(width: 44),
        ],
      ),
    );
  }
}