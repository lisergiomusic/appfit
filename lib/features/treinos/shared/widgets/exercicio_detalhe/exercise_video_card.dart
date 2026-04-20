import 'dart:async';
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
  bool _userStarted = false;
  bool _controlsVisible = true;
  Timer? _hideTimer;

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

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(Cloudinary.video(media)),
    );
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setLooping(true);
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _disposeController() {
    _hideTimer?.cancel();
    _controller?.dispose();
    _controller = null;
    _initialized = false;
    _error = false;
    _userStarted = false;
    _controlsVisible = true;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _disposeController();
    super.dispose();
  }

  void _onTap() {
    final ctrl = _controller;
    if (ctrl == null || !_initialized) return;

    if (!_userStarted) {
      ctrl.play();
      setState(() {
        _userStarted = true;
        _controlsVisible = true;
      });
      _scheduleHide();
      return;
    }

    if (ctrl.value.isPlaying) {
      ctrl.pause();
      _hideTimer?.cancel();
      setState(() => _controlsVisible = true);
    } else {
      ctrl.play();
      setState(() => _controlsVisible = true);
      _scheduleHide();
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsVisible = false);
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
          child: GestureDetector(
            onTap: _onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildVideoOrThumbnail(),
                if (_initialized && _controller != null)
                  ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: _controller!,
                    builder: (_, value, __) {
                      final isPlaying = value.isPlaying;
                      final show = _controlsVisible || !_userStarted;
                      return AnimatedOpacity(
                        opacity: show ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          color: Colors.black.withAlpha(_userStarted ? 60 : 0),
                          child: Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(110),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withAlpha(180),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoOrThumbnail() {
    final media = widget.mediaUrl;
    if (_error || media == null || media.isEmpty) return _buildThumbnailOrEmpty();
    if (!_initialized || !_userStarted) return _buildThumbnailOrEmpty();
    return VideoPlayer(_controller!);
  }

  Widget _buildThumbnailOrEmpty() {
    final media = widget.mediaUrl;
    if (media != null && media.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: Cloudinary.thumbnail(media),
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
