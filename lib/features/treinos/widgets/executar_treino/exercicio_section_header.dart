import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../models/exercicio_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/exercise_service.dart';

/// Modern card header: large GIF thumbnail + name + muscles + progress ring.
class ExercicioSectionHeader extends StatefulWidget {
  final ExercicioItem exercicio;
  final int exIdx;
  final int completedCount;
  final int totalCount;

  const ExercicioSectionHeader({
    super.key,
    required this.exercicio,
    required this.exIdx,
    required this.completedCount,
    required this.totalCount,
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
    final isCompleto =
        widget.completedCount == widget.totalCount && widget.totalCount > 0;
    final progress = widget.totalCount > 0
        ? widget.completedCount / widget.totalCount
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.lg,
        SpacingTokens.lg,
        SpacingTokens.lg,
        SpacingTokens.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail with progress ring
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              children: [
                // Progress ring
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 2.5,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleto
                            ? AppColors.primary
                            : AppColors.primary.withAlpha(160),
                      ),
                    ),
                  ),
                ),
                // Thumbnail
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: FutureBuilder<String?>(
                        future: _imagemUrlFuture,
                        builder: (context, snapshot) {
                          final url = snapshot.data;
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
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
                          return _GifFirstFrame(url: url);
                        },
                      ),
                    ),
                  ),
                ),
                // Checkmark overlay when complete
                if (isCompleto)
                  Center(
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(200),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
              ],
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
                    padding: const EdgeInsets.only(top: 3),
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
          // Series counter badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isCompleto
                  ? AppColors.primary.withAlpha(25)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              '${widget.completedCount}/${widget.totalCount}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isCompleto
                    ? AppColors.primary
                    : AppColors.labelSecondary,
                letterSpacing: 0.2,
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

class _GifFirstFrame extends StatefulWidget {
  final String url;

  const _GifFirstFrame({required this.url});

  @override
  State<_GifFirstFrame> createState() => _GifFirstFrameState();
}

class _GifFirstFrameState extends State<_GifFirstFrame> {
  ui.Image? _frame;
  bool _error = false;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _GifFirstFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _cleanupListener();
      _frame = null;
      _error = false;
      _load();
    }
  }

  void _load() {
    final provider = NetworkImage(widget.url);
    _stream = provider.resolve(ImageConfiguration.empty);
    _listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() => _frame = info.image);
        _cleanupListener();
      },
      onError: (_, _) {
        if (!mounted) return;
        setState(() => _error = true);
        _cleanupListener();
      },
    );
    _stream!.addListener(_listener!);
  }

  void _cleanupListener() {
    final listener = _listener;
    if (listener != null) {
      _stream?.removeListener(listener);
      _listener = null;
    }
  }

  @override
  void dispose() {
    _cleanupListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error || _frame == null) {
      return Container(
        color: AppColors.surfaceLight,
        child: const _ThumbnailPlaceholder(),
      );
    }
    return RawImage(image: _frame, fit: BoxFit.cover);
  }
}
