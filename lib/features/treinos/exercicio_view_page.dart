import 'package:flutter/material.dart';
import '../../core/services/exercise_service.dart';
import '../../core/services/treino_service.dart';
import '../../core/theme/app_theme.dart';
import 'models/exercicio_model.dart';
import 'widgets/exercicio_detalhe/exercise_video_card.dart';
import 'widgets/exercicio_detalhe/recordes_pessoais_section.dart';

class ExercicioViewPage extends StatefulWidget {
  final ExercicioItem exercicio;
  final String? alunoId;

  const ExercicioViewPage({super.key, required this.exercicio, this.alunoId});

  @override
  State<ExercicioViewPage> createState() => _ExercicioViewPageState();
}

class _ExercicioViewPageState extends State<ExercicioViewPage> {
  final ExerciseService _exerciseService = ExerciseService();
  final TreinoService _treinoService = TreinoService();
  late final Future<Map<String, double?>>? _recordesFuture;
  late final Future<ExercicioItem?>? _exercicioBaseFuture;

  @override
  void initState() {
    super.initState();
    _recordesFuture = widget.alunoId != null
        ? _treinoService.calcularRecordesPessoais(
            alunoId: widget.alunoId!,
            exercicioNome: widget.exercicio.nome,
          )
        : null;
    _exercicioBaseFuture = widget.exercicio.hasInstrucoesPadrao
        ? null
        : _exerciseService.buscarExercicioPorNome(widget.exercicio.nome);
  }

  @override
  Widget build(BuildContext context) {
    final temImagem =
        widget.exercicio.imagemUrl != null &&
        widget.exercicio.imagemUrl!.isNotEmpty;
    final temInstrucoesPadrao = widget.exercicio.hasInstrucoesPadrao;
    final temInstrucoesPersonalizadas =
        widget.exercicio.hasInstrucoesPersonalizadas;
    final temMusculos = widget.exercicio.grupoMuscular.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            title: Text(widget.exercicio.nome, style: AppTheme.pageTitle),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: AppColors.primary,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.screenHorizontalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: SpacingTokens.sm),

                  ExerciseVideoCard(
                    imageUrl: widget.exercicio.imagemUrl,
                    exerciseTitle: widget.exercicio.nome,
                  ),

                  if (temMusculos) ...[
                    const SizedBox(height: SpacingTokens.sm),
                    Wrap(
                      spacing: SpacingTokens.xs,
                      runSpacing: SpacingTokens.xs,
                      children: widget.exercicio.grupoMuscular
                          .map(
                            (grupo) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacingTokens.sm,
                                vertical: SpacingTokens.xs,
                              ),
                              decoration: PillTokens.decoration,
                              child: Text(grupo, style: PillTokens.text),
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: SpacingTokens.sectionGap),

                  Text('Instruções', style: AppTheme.sectionHeader),
                  const SizedBox(height: SpacingTokens.labelToField),
                  FutureBuilder<ExercicioItem?>(
                    future: _exercicioBaseFuture,
                    builder: (context, snapshot) {
                      final instrucoesPadrao =
                          widget.exercicio.instrucoesPadraoTexto ??
                          snapshot.data?.instrucoesPadraoTexto;
                      final temAlgumaInstrucao =
                          instrucoesPadrao != null ||
                          temInstrucoesPersonalizadas;

                      if (!temAlgumaInstrucao &&
                          snapshot.connectionState == ConnectionState.waiting) {
                        return const _InstructionLoadingCard();
                      }

                      if (temAlgumaInstrucao) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (instrucoesPadrao != null)
                              _InstructionCard(text: instrucoesPadrao),
                            if (instrucoesPadrao != null &&
                                temInstrucoesPersonalizadas)
                              const SizedBox(height: SpacingTokens.md),
                            if (temInstrucoesPersonalizadas)
                              _InstructionCard(
                                title: 'Instruções do personal',
                                text: widget
                                    .exercicio
                                    .instrucoesPersonalizadasTexto!,
                                highlighted: true,
                              ),
                          ],
                        );
                      }

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: SpacingTokens.xl,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLG,
                          ),
                          border: Border.all(
                            color: Colors.white.withAlpha(10),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 32,
                              color: AppColors.labelTertiary,
                            ),
                            const SizedBox(height: SpacingTokens.sm),
                            Text(
                              'Nenhuma instrução disponível',
                              style: AppTheme.cardSubtitle.copyWith(
                                color: AppColors.labelTertiary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: SpacingTokens.sectionGap),

                  if (_recordesFuture != null) ...[
                    FutureBuilder<Map<String, double?>>(
                      future: _recordesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const _RecordesLoadingPlaceholder();
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        return RecordesPessoaisSection(
                          recordes: snapshot.data!,
                        );
                      },
                    ),
                    const SizedBox(height: SpacingTokens.sectionGap),
                  ],

                  if (!temImagem && !temMusculos && _recordesFuture == null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Icon(
                              Icons.fitness_center_rounded,
                              size: 48,
                              color: AppColors.labelTertiary,
                            ),
                            const SizedBox(height: SpacingTokens.sm),
                            Text(
                              'Sem informações adicionais',
                              style: AppTheme.cardSubtitle.copyWith(
                                color: AppColors.labelTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: SpacingTokens.screenBottomPadding),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordesLoadingPlaceholder extends StatelessWidget {
  const _RecordesLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: AppTheme.cardDecoration,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _InstructionLoadingCard extends StatelessWidget {
  const _InstructionLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: Colors.white.withAlpha(10), width: 0.5),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  final String? title;
  final String text;
  final bool highlighted;

  const _InstructionCard({
    this.title,
    required this.text,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingTokens.cardPaddingH),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primary.withAlpha(10)
            : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withAlpha(30)
              : Colors.white.withAlpha(10),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTheme.cardTitle.copyWith(
                color: AppColors.labelSecondary,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
          ],
          Text(text, style: AppTheme.bodyText),
        ],
      ),
    );
  }
}
