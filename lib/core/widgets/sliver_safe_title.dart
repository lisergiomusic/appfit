import 'package:flutter/material.dart';

class SliverSafeTitle extends StatelessWidget {
  final String title;
  final bool isVisible;
  final TextStyle style;
  final double reservedHorizontalSpace;
  final Duration duration;

  const SliverSafeTitle({
    super.key,
    required this.title,
    required this.isVisible,
    this.style = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 18,
    ),
    this.reservedHorizontalSpace = 220,
    this.duration = const Duration(milliseconds: 200),
  });

  static String safeTitle(String value, {required String fallback}) {
    final normalized = value.trim();
    return normalized.isEmpty ? fallback : normalized;
  }

  @override
  Widget build(BuildContext context) {
    final constrainedWidth =
        (MediaQuery.sizeOf(context).width - reservedHorizontalSpace)
            .clamp(80.0, double.infinity)
            .toDouble();

    return AnimatedOpacity(
      duration: duration,
      opacity: isVisible ? 1.0 : 0.0,
      child: SizedBox(
        width: constrainedWidth,
        child: Text(
          title,
          textAlign: TextAlign.center,
          softWrap: false,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }
}
