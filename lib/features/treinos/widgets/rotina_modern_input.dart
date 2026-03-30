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
          padding: EdgeInsets.only(bottom: SpacingTokens.labelToField),
          child: Row(
            children: [
              SizedBox(width: 8),
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