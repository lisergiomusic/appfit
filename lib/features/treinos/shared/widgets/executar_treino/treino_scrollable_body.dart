import 'package:flutter/material.dart';
import '../../models/rotina_model.dart';
import '../../models/exercicio_model.dart';
import '../../models/historico_treino_model.dart';
import '../../../../../core/theme/app_theme.dart';
import 'exercicio_section_header.dart';
import 'workout_set_row.dart';
import 'orientacao_personal_banner.dart';

class TreinoScrollableBody extends StatelessWidget {
  /// Sessão que contém a lista de exercícios a ser exibida.
  final SessaoTreinoModel sessao;

  /// Dados gravados durante a execução. Estrutura esperada:
  /// { 'exercicio_<idx>': { 'series': [ { 'completa': bool, ... }, ... ] } }
  final Map<String, dynamic> recordedData;

  /// Controladores de texto para os campos de reps por exercício/serie.
  final List<List<TextEditingController>> repsControllers;

  /// Controladores de texto para os campos de peso por exercício/serie.
  final List<List<TextEditingController>> pesoControllers;

  /// Callback chamado quando uma série é marcada como concluída.
  /// Recebe os índices do exercício e da série (visual index na sessão).
  final void Function(int exercicioIndex, int serieIndex) onSerieCompleted;

  /// Opcional: id do aluno, usado por alguns componentes para permissões/ações.
  final String? alunoId;

  /// Histórico recente por nome de exercício, usado para preencher dicas (peso/reps).
  final Map<String, List<SerieHistorico>> ultimoHistorico;

  const TreinoScrollableBody({
    super.key,
    required this.sessao,
    required this.recordedData,
    required this.repsControllers,
    required this.pesoControllers,
    required this.onSerieCompleted,
    this.alunoId,
    this.ultimoHistorico = const {},
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: SpacingTokens.md, bottom: 160),
        itemCount: sessao.exercicios.length,
        itemBuilder: (context, exIdx) {
          final exercicio = sessao.exercicios[exIdx];
          final exData = recordedData['exercicio_$exIdx'] ?? {'series': []};
          final seriesList = (exData['series'] as List?) ?? [];

          // Conta quantas séries dessa execução foram marcadas como completas.
          final completedCount = seriesList
              .where((s) => (s as Map)['completa'] == true)
              .length;

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
                  // Cabeçalho que mostra nome do exercício, progresso (X/Y)
                  // e botões de ação (se aplicável).
                  ExercicioSectionHeader(
                    exercicio: exercicio,
                    exIdx: exIdx,
                    completedCount: completedCount,
                    alunoId: alunoId,
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
                  ...List.generate(exercicio.series.length, (sIdx) {
                    final isCompleted = seriesList.length > sIdx
                        ? (seriesList[sIdx] as Map)['completa'] == true
                        : false;

                    // Calcula o índice desta série entre outras do mesmo tipo
                    // (ex: 2ª série de aquecimento / 1ª série de trabalho).
                    final serieAtual = exercicio.series[sIdx];
                    final indexDentroDoTipo = exercicio.series
                        .take(sIdx)
                        .where((s) => s.tipo == serieAtual.tipo)
                        .length;

                    // Busca o histórico para este tipo e índice
                    final historicoDoExercicio =
                        ultimoHistorico[exercicio.nome] ?? [];
                    final historicoSerie = historicoDoExercicio.firstWhere(
                      (h) =>
                          h.tipo == serieAtual.tipo &&
                          h.indexDentroDoTipo == indexDentroDoTipo,
                      orElse: () => SerieHistorico(
                        tipo: serieAtual.tipo,
                        indexDentroDoTipo: indexDentroDoTipo,
                      ),
                    );

                    return WorkoutSetRow(
                      serie: exercicio.series[sIdx],
                      visualIndex: _calcWorkIndex(exercicio, sIdx),
                      repsController: repsControllers[exIdx][sIdx],
                      pesoController: pesoControllers[exIdx][sIdx],
                      isCompleted: isCompleted,
                      onCheck: () => onSerieCompleted(exIdx, sIdx),
                      historico: historicoSerie,
                    );
                  }),
                  const SizedBox(height: SpacingTokens.sm),
                ],
              ),
            ),
          );
        },
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

class _ColumnLabelsRow extends StatelessWidget {
  // Linha que exibe os rótulos das colunas acima das séries: Série, Alvo,
  // Reps e KG. Mantém a largura fixa onde necessário para alinhar as colunas.
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
