import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_section_link_button.dart';

class RotinaSectionHeader extends StatelessWidget {
  final bool isReordering;
  final bool canReorder;
  final VoidCallback onToggleReordering;

  const RotinaSectionHeader({
    super.key,
    required this.isReordering,
    required this.canReorder,
    required this.onToggleReordering,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 4),
        Text('Lista de treinos', style: AppTheme.sectionHeader),
        const Spacer(),
        AppSectionLinkButton(
          label: isReordering ? 'Concluir' : 'Reorganizar',
          onPressed: canReorder ? onToggleReordering : null,
        ),
      ],
    );
  }
}