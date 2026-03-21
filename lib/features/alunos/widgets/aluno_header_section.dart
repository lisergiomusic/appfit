import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';

class AlunoHeaderSection extends StatelessWidget {
  final String alunoId;
  final String alunoNome;
  final String? photoUrl;
  final String idade;
  final String peso;
  final Widget? actions;

  const AlunoHeaderSection({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    this.photoUrl,
    required this.idade,
    required this.peso,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Hero(
            tag: 'avatar_$alunoId',
            child: _buildAvatar(),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alunoNome,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip('$idade anos'),
                    const SizedBox(width: 8),
                    _buildDot(),
                    const SizedBox(width: 8),
                    _buildInfoChip('$peso kg'),
                  ],
                ),
                if (actions != null) ...[
                  const SizedBox(height: 12),
                  actions!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primary, width:2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 40,
        backgroundColor: AppTheme.surfaceLight,
        backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
            ? CachedNetworkImageProvider(photoUrl!)
            : null,
        child: photoUrl == null || photoUrl!.isEmpty
            ? Text(
          alunoNome.isNotEmpty ? alunoNome[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppTheme.primary,
          ),
        )
            : null,
      ),
    );
  }

  Widget _buildInfoChip(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: AppTheme.textSecondary.withAlpha(100),
        shape: BoxShape.circle,
      ),
    );
  }
}