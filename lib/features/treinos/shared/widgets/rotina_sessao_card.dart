import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        onTap: isReordering ? null : () {
          HapticFeedback.lightImpact();
          onOpen();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                      style: AppTheme.title1.copyWith(fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${sessao.exercicios.length} EXERCÍCIOS',
                      style: AppTheme.premiumLabel.copyWith(
                        color: AppColors.primary,
                        fontSize: 9,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              isReordering
                  ? ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
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
                      color: AppColors.labelSecondary.withAlpha(100),
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          String.fromCharCode(65 + index),
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
