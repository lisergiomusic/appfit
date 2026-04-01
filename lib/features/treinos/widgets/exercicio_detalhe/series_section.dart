import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/exercicio_model.dart';
import '../../../../core/theme/app_theme.dart';
import 'exercicio_constants.dart';

class SeriesSection extends StatelessWidget {
  final String title;
  final List<MapEntry<int, SerieItem>> entries;
  final Color? titleColor;
  final bool isEditingSection;
  final VoidCallback onToggleEditing;
  final GlobalKey<AnimatedListState> animatedListKey;
  final Widget Function(
    BuildContext context,
    int index,
    Animation<double> animation,
    MapEntry<int, SerieItem> entry,
  ) itemBuilder;

  const SeriesSection({
    super.key,
    required this.title,
    required this.entries,
    this.titleColor,
    required this.isEditingSection,
    required this.onToggleEditing,
    required this.animatedListKey,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final accentColor = titleColor ?? AppColors.labelTertiary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(title, style: AppTheme.sectionHeader),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: onToggleEditing,
                  child: Icon(
                    isEditingSection ? Icons.check : Icons.more_vert,
                    color: AppColors.labelSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.labelToField),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(color: Colors.white.withAlpha(8), width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              child: Column(
                children: [
                  // Faixa de acento colorida no topo
                  Container(height: 3, color: accentColor.withAlpha(160)),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      left: 16,
                      right: 16,
                      bottom: 4,
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: ExercicioDetalheConstants.rowAnimationDuration,
                          curve: Curves.easeInOutCubic,
                          width: isEditingSection ? 36 : 0,
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedPadding(
                              duration: ExercicioDetalheConstants.rowAnimationDuration,
                              curve: Curves.easeInOutCubic,
                              padding: EdgeInsets.only(
                                left: isEditingSection ? 0 : 4,
                              ),
                              child: Text(
                                'SÉRIE',
                                style: AppTheme.microLabelTextStyle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Text(
                              'REPS',
                              style: AppTheme.microLabelTextStyle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Text(
                              'PESO',
                              style: AppTheme.microLabelTextStyle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Text(
                              'PAUSA',
                              style: AppTheme.microLabelTextStyle,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: ExercicioDetalheConstants.rowAnimationDuration,
                          curve: Curves.easeInOutCubic,
                          width: isEditingSection ? 34 : 0,
                        ),
                      ],
                    ),
                  ),
                  AnimatedList(
                    key: animatedListKey,
                    initialItemCount: entries.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index, animation) {
                      return itemBuilder(context, index, animation, entries[index]);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
