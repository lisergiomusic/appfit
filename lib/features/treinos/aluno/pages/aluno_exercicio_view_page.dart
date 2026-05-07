import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../../../../core/services/exercise_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/appfit_sliver_app_bar.dart';
import '../../shared/models/exercicio_model.dart';
import '../../shared/widgets/exercicio_detalhe/exercicio_constants.dart';
import '../../shared/widgets/exercicio_detalhe/exercise_video_card.dart';

class AlunoExercicioViewPage extends StatefulWidget {
  final ExercicioItem exercicio;
  final String? alunoId;

  const AlunoExercicioViewPage({
    super.key,
    required this.exercicio,
    this.alunoId,
  });

  @override
  State<AlunoExercicioViewPage> createState() => _AlunoExercicioViewPageState();
}

class _AlunoExercicioViewPageState extends State<AlunoExercicioViewPage> {
  final ExerciseService _exerciseService = ExerciseService();
  late final Future<ExercicioItem?>? _exercicioBaseFuture;
  late final Future<ExercicioItem?> _exercicioBaseParaMidiaFuture;
  String? _selectedCoverGroup;

  @override
  void initState() {
    super.initState();
    _exercicioBaseFuture = widget.exercicio.hasInstrucoesPadrao
        ? null
        : _exerciseService.buscarExercicioPorNome(widget.exercicio.nome);

    final hasLocalMedia =
        widget.exercicio.mediaUrl != null &&
        widget.exercicio.mediaUrl!.isNotEmpty;
    _exercicioBaseParaMidiaFuture = hasLocalMedia
        ? Future.value(null)
        : _exerciseService.buscarExercicioPorNome(widget.exercicio.nome);

    _definirCapa();
  }

  static const Map<String, String> _muscleImageMap = {
    'peito': 'chest.jpg',
    'costas': 'back.jpg',
    'pernas': 'legs.jpg',
    'deltóides': 'deltoides.jpg',
    'deltoides': 'deltoides.jpg',
    'glúteos': 'gluteos.jpg',
    'gluteos': 'gluteos.jpg',
    'triceps': 'triceps.jpg',
    'tríceps': 'triceps.jpg',
    'biceps': 'biceps.jpg',
    'bíceps': 'biceps.jpg',
  };

  void _definirCapa() {
    final grupos = widget.exercicio.grupoMuscular;
    if (grupos.isEmpty) return;

    // Sempre usa o primeiro grupo definido como primário
    final primeiroGrupo = grupos.first;
    if (_muscleImageMap.containsKey(primeiroGrupo.toLowerCase())) {
      setState(() {
        _selectedCoverGroup = primeiroGrupo;
      });
    }
  }
  Color _getGrupoColor(String? grupo) {
    if (grupo == null) return AppColors.primary;

    final g = grupo.toLowerCase();
    if (g.contains('peito')) return Colors.redAccent;
    if (g.contains('costas')) return Colors.blueAccent;
    if (g.contains('perna') || g.contains('glúteo')) return Colors.orangeAccent;
    if (g.contains('deltoide')) return Colors.purpleAccent;
    if (g.contains('braço') || g.contains('triceps') || g.contains('biceps')) return Colors.greenAccent;

    return AppColors.primary;
  }

  String? _getCoverImageUrl(String? grupo) {
    if (grupo == null) return null;

    final fileName = _muscleImageMap[grupo.toLowerCase()];
    if (fileName == null) return null;

    const supabaseUrl = 'https://rqsonrzagxvmmkjzshcl.supabase.co';
    return '$supabaseUrl/storage/v1/object/public/workout_covers/$fileName';
  }

  void _mostrarAvisoInstrucoes(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: AppColors.labelSecondary,
            ),
            const SizedBox(width: SpacingTokens.sm),
            Text('Sobre estas instruções', style: AppTheme.cardTitle),
          ],
        ),
        content: Text(
          'As instruções exibidas aqui são orientações gerais e educativas sobre o exercício, '
          'fornecidas como referência básica. Elas não substituem as orientações individualizadas '
          'do seu personal trainer.\n\n'
          'Antes de executar qualquer exercício, considere:\n\n'
          '• Suas condições físicas e limitações pessoais\n'
          '• Lesões ou restrições médicas preexistentes\n'
          '• As instruções específicas passadas pelo seu personal\n\n'
          'Em caso de dúvida, consulte sempre um profissional de educação física habilitado '
          'antes de iniciar ou modificar sua prática.',
          style: AppTheme.bodyText.copyWith(
            color: AppColors.labelSecondary,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
              ),
              child: const Text(
                'Entendi',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temMusculos = widget.exercicio.grupoMuscular.isNotEmpty;
    final coverUrl = _getCoverImageUrl(_selectedCoverGroup);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          AppFitSliverAppBar(
            title: widget.exercicio.nome,
            expandedHeight: 180,
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (coverUrl != null)
                  CachedNetworkImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: const Color(0xFF121212)),
                    errorWidget: (context, url, error) => const SizedBox.shrink(),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        (_getGrupoColor(_selectedCoverGroup)).withAlpha(coverUrl != null ? 100 : 40),
                        const Color(0xFF121212),
                      ],
                      stops: const [0.0, 0.9],
                    ),
                  ),
                ),
                if (coverUrl != null)
                  Container(color: Colors.black.withAlpha(40)),
                Align(
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
                        Text(widget.exercicio.nome, style: AppTheme.bigTitle),
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
                                    decoration: PillTokens.decoration.copyWith(
                                      color: Colors.white.withAlpha(10),
                                    ),
                                    child: Text(grupo, style: PillTokens.text),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
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
                  const SizedBox(height: SpacingTokens.sectionGap),

                  // Bloco de Vídeo
                  FutureBuilder<ExercicioItem?>(
                    future: _exercicioBaseParaMidiaFuture,
                    builder: (context, snapshot) {
                      final hasLocalMedia =
                          widget.exercicio.mediaUrl != null &&
                          widget.exercicio.mediaUrl!.isNotEmpty;

                      if (!hasLocalMedia &&
                          snapshot.connectionState == ConnectionState.waiting) {
                        return const _VideoCardLoadingPlaceholder();
                      }

                      final resolvedMedia = hasLocalMedia
                          ? widget.exercicio.mediaUrl
                          : snapshot.data?.mediaUrl;

                      return ExerciseVideoCard(
                        mediaUrl: resolvedMedia,
                        exerciseTitle: widget.exercicio.nome,
                      );
                    },
                  ),

                  const SizedBox(height: SpacingTokens.sectionGap),

                  // Cabeçalho de Instruções
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Instruções'.toUpperCase(),
                        style: AppTheme.formLabel.copyWith(
                          fontSize: 10,
                          letterSpacing: 0.5,
                          color: AppColors.labelSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _mostrarAvisoInstrucoes(context),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 11,
                            color: AppColors.labelSecondary.withAlpha(120),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Conteúdo de Instruções
                  FutureBuilder<ExercicioItem?>(
                    future: _exercicioBaseFuture,
                    builder: (context, snapshot) {
                      final instrucoesPadrao =
                          widget.exercicio.instrucoesPadraoTexto ??
                          snapshot.data?.instrucoesPadraoTexto;

                      if (instrucoesPadrao == null &&
                          snapshot.connectionState == ConnectionState.waiting) {
                        return const _InstructionLoadingCard();
                      }

                      if (instrucoesPadrao != null) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            instrucoesPadrao,
                            style: AppTheme.bodyText.copyWith(
                              color: AppColors.labelPrimary.withAlpha(200),
                              height: 1.4,
                            ),
                          ),
                        );
                      }

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: SpacingTokens.xl,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 32,
                              color: AppColors.labelSecondary.withAlpha(80),
                            ),
                            const SizedBox(height: SpacingTokens.sm),
                            Text(
                              'Nenhuma instrução disponível',
                              style: AppTheme.caption.copyWith(
                                color: AppColors.labelSecondary.withAlpha(120),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

class _VideoCardLoadingPlaceholder extends StatelessWidget {
  const _VideoCardLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: AspectRatio(
        aspectRatio: ExercicioDetalheConstants.videoAspectRatio,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      ),
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
        color: Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      ),
    );
  }
}