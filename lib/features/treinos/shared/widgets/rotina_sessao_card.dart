import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_swipe_to_delete.dart';
import '../models/rotina_model.dart';

enum RotinaSessaoMenuAction { edit, delete }

class RotinaSessaoCard extends StatelessWidget {
  final SessaoTreinoModel sessao;
  final int index;
  final bool isReordering;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool readOnly;

  const RotinaSessaoCard({
    super.key,
    required this.sessao,
    required this.index,
    required this.isReordering,
    required this.onOpen,
    this.onEdit,
    this.onDelete,
    this.readOnly = false,
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
                  : (!readOnly && (onEdit != null || onDelete != null))
                  ? PopupMenuButton<RotinaSessaoMenuAction>(
                      icon: const Icon(
                        CupertinoIcons.ellipsis_vertical,
                        size: 20,
                        color: AppColors.labelTertiary,
                      ),
                      onSelected: (value) {
                        if (value == RotinaSessaoMenuAction.edit) {
                          onEdit?.call();
                        }

                        if (value == RotinaSessaoMenuAction.delete) {
                          onDelete?.call();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: RotinaSessaoMenuAction.edit,
                          child: Text('Editar'),
                        ),
                        PopupMenuItem(
                          value: RotinaSessaoMenuAction.delete,
                          child: Text('Excluir'),
                        ),
                      ],
                    )
                  : Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.labelSecondary,
                    ),
            ],
          ),
        ),
      ),
    );

    final Widget inner = ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      child: card,
    );

    Widget result;
    if (isReordering || readOnly || onDelete == null) {
      result = inner;
    } else {
      result = AppSwipeToDelete(
        dismissibleKey: ValueKey('dismiss-sessao-${identityHashCode(sessao)}'),
        onDismissed: (_) => onDelete?.call(),
        child: inner,
      );
    }

    return Padding(padding: EdgeInsets.zero, child: result);
  }
}

class _SessaoIndexBadge extends StatelessWidget {
  final int index;

  const _SessaoIndexBadge({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(40),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      child: Center(
        child: Text(
          String.fromCharCode(65 + index),
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
