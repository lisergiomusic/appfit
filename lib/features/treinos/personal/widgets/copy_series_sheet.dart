import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../shared/models/exercicio_model.dart';
import '../../shared/widgets/exercicio_thumbnail.dart';

class CopySeriesSheet extends StatelessWidget {
  final List<ExercicioItem> otherExercises;
  final String currentExerciseName;

  const CopySeriesSheet({
    super.key,
    required this.otherExercises,
    required this.currentExerciseName,
  });

  static Future<List<SerieItem>?> show(
    BuildContext context, {
    required List<ExercicioItem> otherExercises,
    required String currentExerciseName,
  }) {
    return showModalBottomSheet<List<SerieItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CopySeriesSheet(
        otherExercises: otherExercises,
        currentExerciseName: currentExerciseName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withAlpha(240),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Copiar séries de...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecione um exercício da mesma sessão para copiar suas séries para o exercício atual.',
                    style: TextStyle(
                      color: Colors.white.withAlpha(120),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: otherExercises.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ex = otherExercises[index];
                  return _buildExerciseOption(context, ex);
                },
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseOption(BuildContext context, ExercicioItem ex) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Senior UX: Clone series to avoid reference issues
          final clonedSeries = ex.series.map((s) => s.clone(sameId: false)).toList();
          Navigator.pop(context, clonedSeries);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(15), width: 1),
          ),
          child: Row(
            children: [
              ExercicioThumbnail(
                exercicio: ex,
                width: 56,
                height: 56,
                borderRadius: 12,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ex.series.length} ${ex.series.length == 1 ? 'série' : 'séries'} planejadas',
                      style: TextStyle(
                        color: AppColors.primary.withAlpha(180),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.copy_rounded,
                color: Colors.white.withAlpha(40),
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}