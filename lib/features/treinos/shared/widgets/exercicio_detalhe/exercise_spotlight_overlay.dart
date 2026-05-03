import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/cloudinary.dart';

class ExerciseSpotlightOverlay extends StatefulWidget {
  final String mediaUrl;
  final String exerciseTitle;
  final String heroTag;

  const ExerciseSpotlightOverlay({
    super.key,
    required this.mediaUrl,
    required this.exerciseTitle,
    required this.heroTag,
  });

  static void show(BuildContext context, {
    required String mediaUrl,
    required String exerciseTitle,
    required String heroTag,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) => ExerciseSpotlightOverlay(
          mediaUrl: mediaUrl,
          exerciseTitle: exerciseTitle,
          heroTag: heroTag,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<ExerciseSpotlightOverlay> createState() => _ExerciseSpotlightOverlayState();
}

class _ExerciseSpotlightOverlayState extends State<ExerciseSpotlightOverlay> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(Cloudinary.video(widget.mediaUrl)),
    );

    try {
      await _controller.initialize();
      if (!mounted) return;
      await _controller.setLooping(true);
      await _controller.play();
      setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withAlpha(200),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Glass Backdrop
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.transparent),
            ),
          ),
          
          // Header info
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visualização',
                        style: AppTheme.caption.copyWith(
                          color: AppColors.labelTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.exerciseTitle,
                        style: AppTheme.title1.copyWith(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(30),
                  ),
                ),
              ],
            ),
          ),

          // Main Video
          Center(
            child: Hero(
              tag: widget.heroTag,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AspectRatio(
                  aspectRatio: 1, // Full square focus in spotlight
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(150),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildVideoContent(),
                  ),
                ),
              ),
            ),
          ),

          // Footer Controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 0,
            right: 0,
            child: Center(
              child: _buildControls(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_error) {
      return Container(
        color: AppColors.surfaceDark,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.white38, size: 48),
            SizedBox(height: 16),
            Text('Erro ao carregar vídeo', style: TextStyle(color: Colors.white60)),
          ],
        ),
      );
    }
    
    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return VideoPlayer(_controller);
  }

  Widget _buildControls() {
    if (!_initialized) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _controller.value.isPlaying ? _controller.pause() : _controller.play();
              });
            },
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: Colors.white.withAlpha(30)),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              _controller.seekTo(Duration.zero);
              _controller.play();
            },
            icon: const Icon(Icons.replay_rounded, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}