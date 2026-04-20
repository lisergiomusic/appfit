import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/exercicio_model.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/exercise_service.dart';
import '../../../../../core/utils/cloudinary.dart';

class ExercicioOverviewCard extends StatefulWidget {
  final ExercicioItem exercicio;
  final int exercicioIndex;
  final Map<String, dynamic> exercicioData;
  final VoidCallback onTap;
  final bool isActive;

  const ExercicioOverviewCard({
    super.key,
    required this.exercicio,
    required this.exercicioIndex,
    required this.exercicioData,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<ExercicioOverviewCard> createState() => _ExercicioOverviewCardState();
}

class _ExercicioOverviewCardState extends State<ExercicioOverviewCard> {
  final ExerciseService _exerciseService = ExerciseService();
  late final Future<String?> _thumbnailFuture;

  ExercicioItem get exercicio => widget.exercicio;

  @override
  void initState() {
    super.initState();
    if (exercicio.mediaUrl != null && exercicio.mediaUrl!.isNotEmpty) {
      _thumbnailFuture = Future.value(Cloudinary.thumbnail(exercicio.mediaUrl!));
    } else {
      _thumbnailFuture = _exerciseService
          .buscarExercicioPorNome(exercicio.nome)
          .then((base) => base?.mediaUrl != null ? Cloudinary.thumbnail(base!.mediaUrl!) : null);
    }
  }

  int get _completedCount {
    final series = widget.exercicioData['series'] as List? ?? [];
    return series.where((s) => (s as Map)['completa'] == true).length;
  }

  int get _totalCount => exercicio.series.length;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: CardTokens.cardRadius,
        child: Padding(
          padding: CardTokens.padding,
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(right: SpacingTokens.lg),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: Colors.black.withAlpha(40),
                    child: FutureBuilder<String?>(
                      future: _thumbnailFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary.withAlpha(100),
                            ),
                          );
                        }
                        final url = snapshot.data;
                        if (url == null || url.isEmpty) {
                          return Center(
                            child: Icon(
                              Icons.fitness_center,
                              color: AppColors.labelSecondary,
                              size: 26,
                            ),
                          );
                        }
                        return CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary.withAlpha(100),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Center(
                            child: Icon(
                              Icons.fitness_center,
                              color: AppColors.labelSecondary,
                              size: 26,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercicio.nome,
                      style: AppTheme.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercicio.grupoMuscular.join(', '),
                      style: AppTheme.caption2.copyWith(
                        color: AppColors.labelTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildSeriesProgress(),
                  ],
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.labelSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesProgress() {
    return Row(
      children: [
        Wrap(
          spacing: 4,
          children: List.generate(
            _totalCount,
            (i) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _completedCount
                    ? AppColors.primary
                    : AppColors.primary.withAlpha(25),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$_completedCount/$_totalCount séries',
          style: AppTheme.caption2.copyWith(color: AppColors.labelTertiary),
        ),
      ],
    );
  }
}
