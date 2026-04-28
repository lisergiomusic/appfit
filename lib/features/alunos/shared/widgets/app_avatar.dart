import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';

class AppAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double radius;
  final bool showBorder;
  final Color? borderColor;

  const AppAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 40,
    this.showBorder = true,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surfaceLight,
        backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
            ? CachedNetworkImageProvider(photoUrl!)
            : null,
        child: photoUrl == null || photoUrl!.isEmpty
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              )
            : null,
      ),
    );

    if (!showBorder) return avatar;

    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? AppColors.primary.withAlpha(120),
          width: 1,
        ),
      ),
      child: avatar,
    );
  }
}