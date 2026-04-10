import 'package:flutter/material.dart';
import '../../models/exercicio_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/exercise_service.dart';
import '../exercicio_detalhe/exercise_video_card.dart';
import 'workout_set_row.dart';

class ExercicioExecutionBody extends StatefulWidget {
  final ExercicioItem exercicio;
  final int exercicioIndex;
  final List<SerieItem> series;
  final List<TextEditingController> repsControllers;
  final List<TextEditingController> pesoControllers;
  final Map<String, dynamic> exercicioData;
  final void Function(int serieIndex) onSerieCompleted;

  const ExercicioExecutionBody({
    super.key,
    required this.exercicio,
    required this.exercicioIndex,
    required this.series,
    required this.repsControllers,
    required this.pesoControllers,
    required this.exercicioData,
    required this.onSerieCompleted,
  });

  @override
  State<ExercicioExecutionBody> createState() => _ExercicioExecutionBodyState();
}

class _ExercicioExecutionBodyState extends State<ExercicioExecutionBody> {
  final ExerciseService _exerciseService = ExerciseService();
  late final Future<ExercicioItem?> _exercicioBaseFuture;

  ExercicioItem get exercicio => widget.exercicio;
  List<SerieItem> get series => widget.series;
  List<TextEditingController> get repsControllers => widget.repsControllers;
  List<TextEditingController> get pesoControllers => widget.pesoControllers;
  Map<String, dynamic> get exercicioData => widget.exercicioData;
  void Function(int serieIndex) get onSerieCompleted => widget.onSerieCompleted;

  @override
  void initState() {
    super.initState();
    final hasLocalImage =
        widget.exercicio.imagemUrl != null &&
        widget.exercicio.imagemUrl!.isNotEmpty;

    _exercicioBaseFuture = hasLocalImage
        ? Future.value(null)
        : _exerciseService.buscarExercicioPorNome(widget.exercicio.nome);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.screenHorizontalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise image/video
            Padding(
              padding: const EdgeInsets.only(bottom: SpacingTokens.lg),
              child: _buildExerciseHeaderMedia(),
            ),
            // Exercise header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercicio.nome, style: AppTheme.title1),
                if (exercicio.grupoMuscular.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: SpacingTokens.md),
                    child: Wrap(
                      spacing: SpacingTokens.xs,
                      runSpacing: SpacingTokens.xs,
                      children: exercicio.grupoMuscular
                          .map(
                            (g) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacingTokens.sm,
                                vertical: SpacingTokens.xs,
                              ),
                              decoration: PillTokens.decoration,
                              child: Text(g, style: PillTokens.text),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: SpacingTokens.xl),
            // Instructions section (collapsible)
            if (exercicio.hasInstrucoesPadrao ||
                exercicio.hasInstrucoesPersonalizadas) ...[
              _buildInstrucoesSection(),
              const SizedBox(height: SpacingTokens.sectionGap),
            ],
            // Sets grouped by type
            Column(children: [..._buildGroupedSetSections()]),
            const SizedBox(height: SpacingTokens.screenBottomPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseHeaderMedia() {
    return FutureBuilder<ExercicioItem?>(
      future: _exercicioBaseFuture,
      builder: (context, snapshot) {
        final temImagemPropria =
            exercicio.imagemUrl != null && exercicio.imagemUrl!.isNotEmpty;

        if (!temImagemPropria &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const _VideoCardLoadingPlaceholder();
        }

        final resolvedImage = temImagemPropria
            ? exercicio.imagemUrl
            : snapshot.data?.imagemUrl;

        return ExerciseVideoCard(
          imageUrl: resolvedImage,
          exerciseTitle: exercicio.nome,
        );
      },
    );
  }

  List<Widget> _buildGroupedSetSections() {
    final aquecimento = _entriesForTipo(TipoSerie.aquecimento);
    final aproximacao = _entriesForTipo(TipoSerie.feeder);
    final trabalho = _entriesForTipo(TipoSerie.trabalho);

    return [
      ..._buildSection(
        title: 'Aquecimento',
        accent: const Color(0xFF00B4D8),
        entries: aquecimento,
      ),
      ..._buildSection(
        title: 'Aproximação',
        accent: const Color(0xFFFFB703),
        entries: aproximacao,
      ),
      ..._buildSection(
        title: 'Séries de trabalho',
        accent: const Color(0xFFFF3366),
        entries: trabalho,
      ),
    ];
  }

  List<_SerieEntry> _entriesForTipo(TipoSerie tipo) {
    final entries = <_SerieEntry>[];

    for (var i = 0; i < series.length; i++) {
      final serie = series[i];
      if (serie.tipo != tipo) {
        continue;
      }

      entries.add(
        _SerieEntry(
          index: i,
          serie: serie,
          visualIndex: _resolveVisualIndex(i, serie),
        ),
      );
    }

    return entries;
  }

  int _resolveVisualIndex(int serieIndex, SerieItem serie) {
    if (serie.tipo != TipoSerie.trabalho) {
      return serieIndex + 1;
    }

    var count = 0;
    for (var i = 0; i <= serieIndex; i++) {
      if (series[i].tipo == TipoSerie.trabalho) {
        count++;
      }
    }
    return count;
  }

  List<Widget> _buildSection({
    required String title,
    required Color accent,
    required List<_SerieEntry> entries,
  }) {
    if (entries.isEmpty) {
      return const [];
    }

    return [
      Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(title, style: AppTheme.sectionHeader),
            ],
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(color: accent.withAlpha(90), width: 0.6),
        ),
        child: Column(
          children: [
            Container(
              height: 3,
              width: double.infinity,
              decoration: BoxDecoration(
                color: accent.withAlpha(160),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLG),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingTokens.lg,
                SpacingTokens.sm,
                SpacingTokens.lg,
                SpacingTokens.xs,
              ),
              child: _buildSetsTableHeader(),
            ),
            ...entries.map(_buildRowForEntry),
            const SizedBox(height: SpacingTokens.sm),
          ],
        ),
      ),
      const SizedBox(height: SpacingTokens.lg),
    ];
  }

  Widget _buildInstrucoesSection() {
    final hasPersonalized = exercicio.hasInstrucoesPersonalizadas;
    final hasPadrao = exercicio.hasInstrucoesPadrao;

    if (!hasPadrao && !hasPersonalized) return const SizedBox.shrink();

    return ExpansionTile(
      title: const Text(
        'Instruções',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      children: [
        if (hasPersonalized)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: SpacingTokens.md),
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              border: Border.all(color: AppColors.primary.withAlpha(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Do seu personal',
                  style: AppTheme.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  exercicio.instrucoesPersonalizadasTexto!,
                  style: AppTheme.cardSubtitle,
                ),
              ],
            ),
          ),
        if (hasPadrao)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              border: Border.all(color: AppColors.labelQuaternary),
            ),
            child: Text(
              exercicio.instrucoesPadraoTexto!,
              style: AppTheme.cardSubtitle,
            ),
          ),
      ],
    );
  }

  Widget _buildSetsTableHeader() {
    return Row(
      children: [
        const SizedBox(width: 40, child: Text('SET')),
        const SizedBox(width: 50, child: Text('ALVO')),
        Expanded(child: Text('REPS', textAlign: TextAlign.center)),
        const SizedBox(width: SpacingTokens.sm),
        Expanded(child: Text('PESO', textAlign: TextAlign.center)),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildRowForEntry(_SerieEntry entry) {
    final seriesData = exercicioData['series'] as List? ?? [];

    final isCompleted =
        entry.index < seriesData.length &&
        seriesData[entry.index]['completa'] == true;

    return WorkoutSetRow(
      serie: entry.serie,
      visualIndex: entry.visualIndex,
      repsController: repsControllers[entry.index],
      pesoController: pesoControllers[entry.index],
      isCompleted: isCompleted,
      onCheck: () => onSerieCompleted(entry.index),
    );
  }
}

class _VideoCardLoadingPlaceholder extends StatelessWidget {
  const _VideoCardLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(10), width: 0.5),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}

class _SerieEntry {
  final int index;
  final int visualIndex;
  final SerieItem serie;

  const _SerieEntry({
    required this.index,
    required this.visualIndex,
    required this.serie,
  });
}
