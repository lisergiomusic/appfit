import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/services/exercise_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/exercicio_model.dart';

class ExercicioThumbnail extends StatefulWidget {
  final ExercicioItem exercicio;
  final double width;
  final double height;
  final double borderRadius;
  final double iconSize;
  final Color? backgroundColor;

  const ExercicioThumbnail({
    super.key,
    required this.exercicio,
    this.width = 56,
    this.height = 56,
    this.borderRadius = 10,
    this.iconSize = 26,
    this.backgroundColor,
  });

  @override
  State<ExercicioThumbnail> createState() => _ExercicioThumbnailState();
}

class _ExercicioThumbnailState extends State<ExercicioThumbnail> {
  final ExerciseService _exerciseService = ExerciseService();
  late Future<String?> _imagemUrlFuture;

  @override
  void initState() {
    super.initState();
    _imagemUrlFuture = _resolveImagemUrl(widget.exercicio);
  }

  @override
  void didUpdateWidget(covariant ExercicioThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldEx = oldWidget.exercicio;
    final newEx = widget.exercicio;

    if (oldEx.nome != newEx.nome || oldEx.imagemUrl != newEx.imagemUrl) {
      _imagemUrlFuture = _resolveImagemUrl(newEx);
    }
  }

  bool _isGif(String? url) => url != null && url.toLowerCase().contains('.gif');

  Future<String?> _resolveImagemUrl(ExercicioItem exercicio) {
    if (_isGif(exercicio.imagemUrl)) {
      return Future.value(exercicio.imagemUrl);
    }

    return _exerciseService
        .buscarExercicioPorNome(exercicio.nome)
        .then((base) => _isGif(base?.imagemUrl) ? base!.imagemUrl : null);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? Colors.black.withAlpha(40);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        width: widget.width,
        height: widget.height,
        color: bgColor,
        child: FutureBuilder<String?>(
          future: _imagemUrlFuture,
          builder: (context, snapshot) {
            final url = snapshot.data;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary.withAlpha(100),
                ),
              );
            }

            if (url == null || url.isEmpty) {
              return Center(
                child: Icon(
                  Icons.fitness_center,
                  color: AppColors.labelSecondary,
                  size: widget.iconSize,
                ),
              );
            }

            return _GifFirstFrame(url: url);
          },
        ),
      ),
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
    if (_error) {
      return Center(
        child: Icon(
          Icons.fitness_center,
          color: AppColors.labelSecondary,
          size: 26,
        ),
      );
    }

    if (_frame == null) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary.withAlpha(100),
        ),
      );
    }

    return RawImage(image: _frame, fit: BoxFit.cover);
  }
}
