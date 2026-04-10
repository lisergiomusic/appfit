import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/exercicio_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/exercise_service.dart';

/// Hevy-style exercise section header: thumbnail + name + muscles.
class ExercicioSectionHeader extends StatefulWidget {
  final ExercicioItem exercicio;
  final int exIdx;

  const ExercicioSectionHeader({
    super.key,
    required this.exercicio,
    required this.exIdx,
  });

  @override
  State<ExercicioSectionHeader> createState() => _ExercicioSectionHeaderState();
}

class _ExercicioSectionHeaderState extends State<ExercicioSectionHeader> {
  final ExerciseService _exerciseService = ExerciseService();
  late final Future<String?> _imagemUrlFuture;

  @override
  void initState() {
    super.initState();
    final localUrl = widget.exercicio.imagemUrl;
    final hasLocalGif =
        localUrl != null && localUrl.toLowerCase().contains('.gif');

    if (hasLocalGif) {
      _imagemUrlFuture = Future.value(localUrl);
    } else {
      _imagemUrlFuture = _exerciseService
          .buscarExercicioPorNome(widget.exercicio.nome)
          .then(
            (e) =>
                e?.imagemUrl != null &&
                    e!.imagemUrl!.toLowerCase().contains('.gif')
                ? e.imagemUrl
                : null,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercicio = widget.exercicio;
    final muscles = exercicio.grupoMuscular.join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.lg,
        SpacingTokens.xl,
        SpacingTokens.lg,
        SpacingTokens.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            child: SizedBox(
              width: 48,
              height: 48,
              child: FutureBuilder<String?>(
                future: _imagemUrlFuture,
                builder: (context, snapshot) {
                  final url = snapshot.data;
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: AppColors.surfaceLight,
                      child: const _ThumbnailPlaceholder(),
                    );
                  }
                  if (url == null || url.isEmpty) {
                    return Container(
                      color: AppColors.surfaceLight,
                      child: const _ThumbnailPlaceholder(),
                    );
                  }
                  return CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 200),
                    placeholder: (_, __) => Container(
                      color: AppColors.surfaceLight,
                      child: const _ThumbnailPlaceholder(),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.surfaceLight,
                      child: const _ThumbnailPlaceholder(),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          // Name + muscles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercicio.nome,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: AppColors.labelPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (muscles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      muscles,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.labelSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          // Accent bar as exercise number badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Center(
              child: Text(
                '${widget.exIdx + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.fitness_center_rounded,
      color: AppColors.labelTertiary,
      size: 22,
    );
  }
}
