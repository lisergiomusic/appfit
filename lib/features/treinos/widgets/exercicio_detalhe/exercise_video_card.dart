import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import 'exercicio_constants.dart';

class ExerciseVideoCard extends StatefulWidget {
  final String? imageUrl;
  final String exerciseTitle;

  const ExerciseVideoCard({
    super.key,
    required this.imageUrl,
    required this.exerciseTitle,
  });

  @override
  State<ExerciseVideoCard> createState() => _ExerciseVideoCardState();
}

class _ExerciseVideoCardState extends State<ExerciseVideoCard> {
  bool _paused = false;
  ui.Image? _frozenFrame;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  bool get _isGif {
    final url = widget.imageUrl;
    if (url == null) return false;
    return url.toLowerCase().contains('.gif');
  }

  String? _getYoutubeId(String? url) {
    if (url == null) return null;
    final RegExp regExp = RegExp(
      r"(?<=vi/|v/|vi=|/v/|youtu\.be/|/embed/|v=).+?(?=\?|#|&|$)",
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(0);
  }

  @override
  void initState() {
    super.initState();
    _syncInitialGifState();
  }

  @override
  void didUpdateWidget(covariant ExerciseVideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _syncInitialGifState();
    }
  }

  void _syncInitialGifState() {
    _imageStreamListener != null
        ? _imageStream?.removeListener(_imageStreamListener!)
        : null;
    _imageStreamListener = null;
    _imageStream = null;

    if (!_isGif || widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      setState(() {
        _paused = false;
        _frozenFrame = null;
      });
      return;
    }

    setState(() {
      _paused = true;
      _frozenFrame = null;
    });

    final imageProvider = NetworkImage(widget.imageUrl!);
    final config = ImageConfiguration.empty;
    _imageStream = imageProvider.resolve(config);
    _imageStreamListener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() {
        _frozenFrame = info.image;
      });
      _imageStream?.removeListener(_imageStreamListener!);
    });
    _imageStream!.addListener(_imageStreamListener!);
  }

  void _togglePause() {
    if (!_isGif) return;

    if (_paused) {
      setState(() {
        _paused = false;
        _frozenFrame = null;
      });
      return;
    }

    // Captura o frame atual do GIF e congela
    final imageProvider = NetworkImage(widget.imageUrl!);
    final config = ImageConfiguration(
      devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
    );
    _imageStream = imageProvider.resolve(config);

    _imageStreamListener = ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _frozenFrame = info.image;
          _paused = true;
        });
      }
      _imageStream?.removeListener(_imageStreamListener!);
    });

    _imageStream!.addListener(_imageStreamListener!);
  }

  @override
  void dispose() {
    if (_imageStreamListener != null) {
      _imageStream?.removeListener(_imageStreamListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(10), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: ExercicioDetalheConstants.videoAspectRatio,
          child: Stack(
            children: [
              Positioned.fill(child: _buildMedia()),
              if (_isGif)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _togglePause,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(140),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedia() {
    final url = widget.imageUrl;

    if (url == null || url.isEmpty) {
      return Container(
        color: AppColors.surfaceDark,
        child: const Icon(Icons.videocam_off, color: Colors.white38),
      );
    }

    // GIF pausado: mostra o frame congelado
    if (_isGif && _paused && _frozenFrame != null) {
      return RawImage(image: _frozenFrame, fit: BoxFit.cover);
    }

    if (_isGif && _paused) {
      return Container(
        color: AppColors.surfaceDark,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // GIF animando: usa Image.network para suportar animação
    if (_isGif) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: AppColors.surfaceDark,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const SizedBox.shrink();
            },
            errorBuilder: (context, url, stack) => Container(
              color: AppColors.surfaceDark,
              child: const Icon(Icons.videocam_off, color: Colors.white38),
            ),
          ),
        ],
      );
    }

    // YouTube thumbnail ou imagem estática
    final youtubeId = _getYoutubeId(url);
    final resolvedUrl = youtubeId != null
        ? 'https://img.youtube.com/vi/$youtubeId/0.jpg'
        : url;

    return CachedNetworkImage(
      imageUrl: resolvedUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppColors.surfaceDark,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.surfaceDark,
        child: const Icon(Icons.videocam_off, color: Colors.white38),
      ),
    );
  }
}
