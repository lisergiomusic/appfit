import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';

class AppAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double radius;
  final bool showBorder;
  final Color? borderColor;
  final bool isSquare;

  const AppAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 40,
    this.showBorder = true,
    this.borderColor,
    this.isSquare = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isSquare ? BorderRadius.zero : null,
        image: photoUrl != null && photoUrl!.isNotEmpty
            ? DecorationImage(
                image: CachedNetworkImageProvider(photoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: photoUrl == null || photoUrl!.isEmpty
          ? Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: radius * 0.6,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            )
          : null,
    );

    if (!showBorder) return avatar;

    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isSquare ? BorderRadius.zero : null,
        border: Border.all(
          color: borderColor ?? AppColors.primary.withAlpha(120),
          width: 1,
        ),
      ),
      child: avatar,
    );
  }
}