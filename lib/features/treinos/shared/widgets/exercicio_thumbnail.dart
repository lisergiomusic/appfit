import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/exercise_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/cloudinary.dart';
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
  late Future<String?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = _resolveThumbnail(widget.exercicio);
  }

  @override
  void didUpdateWidget(covariant ExercicioThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldEx = oldWidget.exercicio;
    final newEx = widget.exercicio;
    if (oldEx.nome != newEx.nome || oldEx.mediaUrl != newEx.mediaUrl) {
      _thumbnailFuture = _resolveThumbnail(newEx);
    }
  }

  Future<String?> _resolveThumbnail(ExercicioItem exercicio) {
    if (exercicio.mediaUrl != null && exercicio.mediaUrl!.isNotEmpty) {
      return Future.value(Cloudinary.thumbnail(exercicio.mediaUrl!));
    }
    return _exerciseService
        .buscarExercicioPorNome(exercicio.nome)
        .then((base) => base?.mediaUrl != null ? Cloudinary.thumbnail(base!.mediaUrl!) : null);
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
          future: _thumbnailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary.withAlpha(100),
                ),
              );
            }

            final url = snapshot.data;
            if (url == null || url.isEmpty) {
              return Center(
                child: Icon(
                  Icons.fitness_center,
                  color: AppColors.primary,
                  size: widget.iconSize,
                ),
              );
            }

            return CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, _) => Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary.withAlpha(100),
                ),
              ),
              errorWidget: (_, _, _) => Center(
                child: Icon(
                  Icons.fitness_center,
                  color: AppColors.primary,
                  size: widget.iconSize,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}