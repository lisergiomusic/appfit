import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/cloudinary.dart';
import 'exercicio_constants.dart';

class ExerciseVideoCard extends StatefulWidget {
  final String? mediaUrl;
  final String exerciseTitle;

  const ExerciseVideoCard({
    super.key,
    required this.mediaUrl,
    required this.exerciseTitle,
  });

  @override
  State<ExerciseVideoCard> createState() => _ExerciseVideoCardState();
}

class _ExerciseVideoCardState extends State<ExerciseVideoCard> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant ExerciseVideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaUrl != widget.mediaUrl) {
      _disposeController();
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final media = widget.mediaUrl;
    if (media == null || media.isEmpty) return;

    final videoUrl = Cloudinary.video(media);
    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setLooping(true);
      await controller.play();
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _initialized = false;
    _error = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _togglePlayPause() {
    final ctrl = _controller;
    if (ctrl == null || !_initialized) return;
    setState(() {
      ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
    });
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
            fit: StackFit.expand,
            children: [
              _buildContent(),
              if (_initialized && _controller != null)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: _controller!,
                      builder: (_, value, __) => Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(140),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
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

  Widget _buildContent() {
    final media = widget.mediaUrl;
    if (_error || media == null || media.isEmpty) {
      return _buildThumbnailOrEmpty();
    }

    if (!_initialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildThumbnailOrEmpty(),
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      );
    }

    return VideoPlayer(_controller!);
  }

  Widget _buildThumbnailOrEmpty() {
    final media = widget.mediaUrl;
    if (media != null && media.isNotEmpty) {
      final thumbUrl = Cloudinary.thumbnail(media);
      return CachedNetworkImage(
        imageUrl: thumbUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.surfaceDark),
        errorWidget: (_, __, ___) => _emptyState(),
      );
    }
    return _emptyState();
  }

  Widget _emptyState() {
    return Container(
      color: AppColors.surfaceDark,
      child: const Icon(Icons.videocam_off, color: Colors.white38),
    );
  }
}
