import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../note_editor_modal.dart';

class SessaoNoteWidget extends StatefulWidget {
  const SessaoNoteWidget({super.key});

  @override
  State<SessaoNoteWidget> createState() => _SessaoNoteWidgetState();
}

class _SessaoNoteWidgetState extends State<SessaoNoteWidget> {
  String _noteText = '';

  void _openEditModal() {
    HapticFeedback.lightImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar editor de notas',
      barrierColor: Colors.black.withAlpha(220),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return NoteEditorModal(
          initialText: _noteText,
          onSave: (newText) {
            setState(() {
              _noteText = newText;
            });
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<double>(begin: 0.9, end: 1.0);
        return ScaleTransition(
          scale: tween.animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEmpty = _noteText.trim().isEmpty;

    return GestureDetector(
      onTap: _openEditModal,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topLeft,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: isEmpty ? _buildEmptyState() : _buildFilledState(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return KeyedSubtree(
      key: const ValueKey('note_empty'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            Icons.add_comment_outlined,
            color: AppTheme.textSecondary.withAlpha(180),
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            'Clique para adicionar observações',
            style: TextStyle(
              color: AppTheme.textSecondary.withAlpha(180),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilledState() {
    return KeyedSubtree(
      key: const ValueKey('note_filled'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.sticky_note_2, color: AppTheme.primary, size: 16),
              SizedBox(width: 8),
              Text(
                'OBSERVAÇÕES DA SESSÃO',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _noteText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
