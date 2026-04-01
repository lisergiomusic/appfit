import 'package:flutter/cupertino.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import '../theme/app_theme.dart';

class NoteDisplayField extends StatelessWidget {
  final String? text;
  final String label;
  final String addLabel;
  final VoidCallback onTap;
  final bool showInsetShadow;

  const NoteDisplayField({
    super.key,
    required this.text,
    required this.label,
    required this.addLabel,
    required this.onTap,
    this.showInsetShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = text?.trim().isEmpty ?? true;

    if (isEmpty) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.doc_text,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                addLabel,
                style: AppTheme.bodyText.copyWith(
                  color: AppColors.primary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.sectionHeader),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              boxShadow: showInsetShadow
                  ? [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                        inset: true,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(
                    CupertinoIcons.doc_text,
                    size: 16,
                    color: AppColors.labelTertiary,
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Text(
                    text ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyText.copyWith(
                      color: AppColors.labelSecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(
                    CupertinoIcons.pencil,
                    size: 16,
                    color: AppColors.labelTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
