import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/exercicio_model.dart';
import '../../../../../core/theme/app_theme.dart';
import 'exercicio_constants.dart';

class SeriesSection extends StatelessWidget {
  final String title;
  final List<MapEntry<int, SerieItem>> entries;
  final Color? titleColor;
  final Function({bool reps, bool carga, bool descanso})? onEqualize;
  final VoidCallback? onClearAll;
  final GlobalKey<AnimatedListState> animatedListKey;
  final Widget Function(
    BuildContext context,
    int index,
    Animation<double> animation,
    MapEntry<int, SerieItem> entry,
  )
  itemBuilder;

  const SeriesSection({
    super.key,
    required this.title,
    required this.entries,
    this.titleColor,
    this.onEqualize,
    this.onClearAll,
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
                if (entries.isNotEmpty)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'clear_all') {
                        onClearAll?.call();
                      } else if (onEqualize != null) {
                        if (value == 'equalize_reps') onEqualize!(reps: true);
                        if (value == 'equalize_carga') onEqualize!(carga: true);
                        if (value == 'equalize_descanso') {
                          onEqualize!(descanso: true);
                        }
                      }
                    },
                    color: AppColors.surfaceDark,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Colors.white.withAlpha(10),
                        width: 1,
                      ),
                    ),
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: AppColors.labelSecondary,
                      size: 20,
                    ),
                    itemBuilder: (context) {
                      final hasMany = entries.length >= 2;
                      return [
                        if (hasMany) ...[
                          const PopupMenuItem(
                            value: 'equalize_reps',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sync_rounded,
                                  size: 18,
                                  color: Colors.white70,
                                ),
                                SizedBox(width: 12),
                                Text('Igualar Repetições'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'equalize_carga',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.fitness_center_rounded,
                                  size: 18,
                                  color: Colors.white70,
                                ),
                                SizedBox(width: 12),
                                Text('Igualar Cargas'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'equalize_descanso',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.timer_rounded,
                                  size: 18,
                                  color: Colors.white70,
                                ),
                                SizedBox(width: 12),
                                Text('Igualar Descanso'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(height: 1),
                        ],
                        const PopupMenuItem(
                          value: 'clear_all',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_sweep_rounded,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Remover todas as séries',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.labelToField),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              child: Column(
                children: [
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
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
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
                      ],
                    ),
                  ),
                  AnimatedList(
                    key: animatedListKey,
                    initialItemCount: entries.length,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index, animation) {
                      return itemBuilder(
                        context,
                        index,
                        animation,
                        entries[index],
                      );
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