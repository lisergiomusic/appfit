import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';

class AlunoAvatar extends StatelessWidget {
  final String alunoNome;
  final String? photoUrl;
  final double radius;

  const AlunoAvatar({
    super.key,
    required this.alunoNome,
    this.photoUrl,
    this.radius = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withAlpha(120), width: 2),
      ),
      child: Container(
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
                  alunoNome.isNotEmpty ? alunoNome[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
