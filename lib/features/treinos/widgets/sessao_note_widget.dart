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

    return Material(
      color: AppTheme.surfaceDark,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: _openEditModal,
        borderRadius: BorderRadius.circular(18),
        hoverColor: Colors.white.withAlpha(13),
        splashColor: Colors.white.withAlpha(26),
        highlightColor: Colors.white.withAlpha(13),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withAlpha(13)),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.edit_note,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOTAS DA SESSÃO',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Text(
                        isEmpty
                            ? 'Toque para adicionar instruções gerais...'
                            : _noteText,
                        style: TextStyle(
                          color: isEmpty
                              ? const Color(0xFF64748b)
                              : AppTheme.textPrimary.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: isEmpty
                              ? FontWeight.normal
                              : FontWeight.w700,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
