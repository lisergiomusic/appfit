import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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
                  return _GifFirstFrame(url: url);
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
