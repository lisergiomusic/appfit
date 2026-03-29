import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RotinaModernInput extends StatelessWidget {
  final String label;
  final Widget child;

  const RotinaModernInput({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 0, bottom: AppTheme.space12),
          child: Row(
            children: [
              SizedBox(width: AppTheme.space8),
              Text(
                label,
                style: AppTheme.formLabel,
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}