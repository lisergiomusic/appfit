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
                        imageUrl: _getYoutubeId(imageUrl) != null
                            ? 'https://img.youtube.com/vi/${_getYoutubeId(imageUrl)}/0.jpg'
                            : imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.surfaceDark,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.surfaceDark,
                          child: Image.network(
                            url ?? '',
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, err, stack) => const Center(
                              child: Icon(
                                Icons.videocam_off,
                                color: Colors.white38,
                              ),
                            ),
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
            ],
          ),
        ),
      ),
    );
  }
}
