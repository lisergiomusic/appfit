import 'package:appfit/core/widgets/sliver_safe_title.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppFitSliverAppBar extends StatelessWidget {
  final String title;
  final Widget background;
  final List<Widget>? actions;
  final double expandedHeight;
  final bool isPinned;
  final Widget? leading;
  final VoidCallback? onBackPressed;

  const AppFitSliverAppBar({
    super.key,
    required this.title,
    required this.background,
    this.actions,
    this.expandedHeight = 138,
    this.isPinned = true,
    this.leading,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Widget effectiveLeading = leading ??
        Align(
          alignment: Alignment.centerLeft,
          child: CupertinoButton(
            onPressed: onBackPressed ?? () => Navigator.pop(context),
            padding: const EdgeInsets.only(left: 8),
            child: const Icon(
              CupertinoIcons.back,
              color: AppTheme.labelPrimary,
              size: 24,
            ),
          ),
        );

    return SliverAppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.background,
      surfaceTintColor: Colors.transparent,
      pinned: isPinned,
      expandedHeight: expandedHeight,
      leadingWidth: 100,
      leading: effectiveLeading,
      actions: actions,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double collapsedHeight =
              MediaQuery.of(context).padding.top + kToolbarHeight;
          final bool isCollapsed =
              constraints.biggest.height <= collapsedHeight + 20;

          return FlexibleSpaceBar(
            centerTitle: true,
            titlePadding: const EdgeInsets.only(bottom: 18),
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final offsetAnimation =
                    Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        )
                        .chain(CurveTween(curve: Curves.easeOutCubic))
                        .animate(animation);

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: isCollapsed
                  ? SliverSafeTitle(
                      key: const ValueKey('collapsed_title'),
                      title: title,
                      isVisible: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : const SizedBox(key: ValueKey('empty_title'), height: 0),
            ),
            background: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isCollapsed ? 0.0 : 1.0,
              child: background,
            ),
          );
        },
      ),
    );
  }
}