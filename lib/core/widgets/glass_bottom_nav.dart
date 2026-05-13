import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'app_tappable.dart';

class GlassBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const GlassBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<GlassBottomNavItem> items;
  final Function(int) onTap;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        24, 
        0, 
        24, 
        bottomPadding > 0 ? bottomPadding : 12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: items.asMap().entries.map((entry) {
                final int idx = entry.key;
                final GlassBottomNavItem item = entry.value;
                final bool isSelected = currentIndex == idx;

                return Expanded(
                  child: AppTappable(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onTap(idx);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected ? AppColors.primary : AppColors.labelSecondary,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.labelSecondary,
                            fontSize: 9,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}