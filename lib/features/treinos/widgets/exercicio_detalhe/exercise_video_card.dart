import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import 'exercicio_constants.dart';

class ExerciseVideoCard extends StatelessWidget {
  final String? imageUrl;
  final String exerciseTitle;

  const ExerciseVideoCard({
    super.key,
    required this.imageUrl,
    required this.exerciseTitle,
  });

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
              Positioned.fill(
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.surfaceDark,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.surfaceDark,
                          child: const Icon(
                            Icons.videocam_off,
                            color: Colors.white38,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceDark,
                        child: const Icon(
                          Icons.videocam_off,
                          color: Colors.white38,
                        ),
                      ),
              ),
              if (imageUrl != null && imageUrl!.isNotEmpty)
                Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(64),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.play_fill,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
