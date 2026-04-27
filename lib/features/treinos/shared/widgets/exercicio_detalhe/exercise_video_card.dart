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
      if (mounted) {
        setState(() => _initialized = true);
        // Se o usuário já clicou em play enquanto inicializava, começa a tocar
        if (_userStarted) {
          _controller?.play();
          _scheduleHide();
        }
      }
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
    if (_error) return;
    final ctrl = _controller;

    // Se ainda não inicializou, marca que o usuário quer começar
    // O _initVideo vai cuidar de dar play quando terminar
    if (ctrl == null || !_initialized) {
      if (!_userStarted) {
        setState(() {
          _userStarted = true;
          _controlsVisible = true;
        });
      }
      return;
    }

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
    final hasMedia = widget.mediaUrl != null && widget.mediaUrl!.isNotEmpty;

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
                if (hasMedia && !_error) _buildControlsOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    final ctrl = _controller;

    // Se ainda não temos o controller ou não inicializou, mostramos o botão de play
    // ou um loading se o usuário já clicou.
    if (ctrl == null || !_initialized) {
      return _buildPlayButtonIcon(
        show: true,
        isPlaying: false,
        isBuffering: _userStarted,
      );
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: ctrl,
      builder: (_, value, _) {
        final isPlaying = value.isPlaying;
        // Mostra controles se pausado, se o usuário ainda não começou,
        // ou se explicitamente visível por tap ou buffering
        final show =
            _controlsVisible || !isPlaying || !_userStarted || value.isBuffering;

        return _buildPlayButtonIcon(
          show: show,
          isPlaying: isPlaying,
          isBuffering: value.isBuffering,
        );
      },
    );
  }

  Widget _buildPlayButtonIcon({
    required bool show,
    required bool isPlaying,
    required bool isBuffering,
  }) {
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
            child: isBuffering
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
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
        placeholder: (_, _) => Container(color: AppColors.surfaceDark),
        errorWidget: (_, _, _) => _emptyState(),
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