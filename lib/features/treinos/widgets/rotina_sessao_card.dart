import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_swipe_to_delete.dart';
import '../models/rotina_model.dart';

enum RotinaSessaoMenuAction { edit, delete }

class RotinaSessaoCard extends StatelessWidget {
  final SessaoTreinoModel sessao;
  final int index;
  final bool isReordering;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RotinaSessaoCard({
    super.key,
    required this.sessao,
    required this.index,
    required this.isReordering,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        onTap: isReordering ? null : onOpen,
        child: Padding(
          padding: CardTokens.padding,
          child: Row(
            children: [
              _SessaoIndexBadge(index: index),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sessao.nome,
                      style: CardTokens.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: SpacingTokens.titleToSubtitle),
                    Text(
                      '${sessao.exercicios.length} ${sessao.exercicios.length == 1 ? 'exercício' : 'exercícios'}',
                      style: CardTokens.cardSubtitle,
                    ),
                  ],
                ),
              ),
              isReordering
                  ? ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.drag_handle_rounded,
                          color: AppColors.labelSecondary,
                          size: 24,
                        ),
                      ),
                    )
                  : PopupMenuButton<RotinaSessaoMenuAction>(
                      icon: const Icon(
                        CupertinoIcons.ellipsis_vertical,
                        size: 20,
                        color: AppColors.labelTertiary,
                      ),
                      onSelected: (value) {
                        if (value == RotinaSessaoMenuAction.edit) {
                          onEdit();
                        }

                        if (value == RotinaSessaoMenuAction.delete) {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: RotinaSessaoMenuAction.edit,
                          child: Text('Renomear'),
                        ),
                        PopupMenuItem(
                          value: RotinaSessaoMenuAction.delete,
                          child: Text('Excluir'),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: isReordering
            ? card
            : AppSwipeToDelete(
                dismissibleKey: ValueKey(
                  'dismiss-sessao-${identityHashCode(sessao)}',
                ),
                onDismissed: (_) => onDelete(),
                child: card,
              ),
      ),
    );
  }
}

class _SessaoIndexBadge extends StatelessWidget {
  final int index;

  const _SessaoIndexBadge({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(40),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      child: Center(
        child: Text(
          String.fromCharCode(65 + index),
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
