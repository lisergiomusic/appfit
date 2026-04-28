import 'package:flutter/material.dart';
import '../../../../core/services/exercise_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/appfit_sliver_app_bar.dart';
import '../../shared/models/exercicio_model.dart';
import '../../shared/widgets/exercicio_detalhe/exercise_video_card.dart';
import 'personal_criar_exercicio_page.dart';

class PersonalExercicioViewPage extends StatefulWidget {
  final ExercicioItem exercicio;
  final bool isSelected;
  final bool isAdmin;

  const PersonalExercicioViewPage({
    super.key,
    required this.exercicio,
    required this.isSelected,
    required this.isAdmin,
  });

  @override
  State<PersonalExercicioViewPage> createState() => _PersonalExercicioViewPageState();
}

class _PersonalExercicioViewPageState extends State<PersonalExercicioViewPage> {
  final ExerciseService _exerciseService = ExerciseService();
  late bool _isSelected;
  late final Future<ExercicioItem?> _exercicioBaseParaMidiaFuture;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.isSelected;
    
    final hasLocalMedia = widget.exercicio.mediaUrl != null && widget.exercicio.mediaUrl!.isNotEmpty;
    _exercicioBaseParaMidiaFuture = hasLocalMedia
        ? Future.value(null)
        : _exerciseService.buscarExercicioPorNome(widget.exercicio.nome);
  }

  @override
  Widget build(BuildContext context) {
    final temMusculos = widget.exercicio.grupoMuscular.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                AppFitSliverAppBar(
                  title: widget.exercicio.nome,
                  expandedHeight: 160,
                  background: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: SpacingTokens.screenHorizontalPadding,
                        right: SpacingTokens.screenHorizontalPadding,
                        bottom: SpacingTokens.sm,
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
                                  .map((grupo) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: SpacingTokens.sm,
                                          vertical: SpacingTokens.xs,
                                        ),
                                        decoration: PillTokens.decoration,
                                        child: Text(grupo, style: PillTokens.text),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
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
                        FutureBuilder<ExercicioItem?>(
                          future: _exercicioBaseParaMidiaFuture,
                          builder: (context, snapshot) {
                            final hasLocalMedia = widget.exercicio.mediaUrl != null && widget.exercicio.mediaUrl!.isNotEmpty;
                            final resolvedMedia = hasLocalMedia ? widget.exercicio.mediaUrl : snapshot.data?.mediaUrl;
                            
                            return ExerciseVideoCard(
                              mediaUrl: resolvedMedia,
                              exerciseTitle: widget.exercicio.nome,
                            );
                          },
                        ),
                        const SizedBox(height: SpacingTokens.sectionGap),
                        const Text(
                          'Instruções',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withAlpha(10)),
                          ),
                          child: Text(
                            widget.exercicio.instrucoes ?? 'Nenhuma instrução disponível.',
                            style: const TextStyle(
                              color: AppColors.labelSecondary,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (widget.isAdmin) ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PersonalCriarExercicioPage(
                                      exercicioParaEditar: widget.exercicio,
                                    ),
                                  ),
                                );
                                if (result != null && mounted) {
                                  // Se editou, recarregamos as informações (ou voltamos para a lista)
                                  Navigator.pop(context, 'reload');
                                }
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Editar Exercício (Admin)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 100), // Espaço para não ficar colado no botão inferior
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: Colors.white.withAlpha(10))),
            ),
            child: ElevatedButton(
              onPressed: () {
                setState(() => _isSelected = !_isSelected);
                Navigator.pop(context, _isSelected ? 'select' : 'unselect');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSelected ? AppColors.surfaceLight : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _isSelected ? 'Remover do Treino' : 'Adicionar ao Treino',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _isSelected ? Colors.redAccent : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}