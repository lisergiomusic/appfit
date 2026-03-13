import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../core/theme/app_theme.dart';

class NoteSection extends StatefulWidget {
  const NoteSection({super.key});

  @override
  State<NoteSection> createState() => _NoteSectionState();
}

class _NoteSectionState extends State<NoteSection> {
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
        return _NoteEditorModal(
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
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEmpty = _noteText.trim().isEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openEditModal,
        borderRadius: BorderRadius.circular(20),
        splashColor: AppTheme.primary.withAlpha(30),
        highlightColor: AppTheme.primary.withAlpha(20),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.space16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(15), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    const Text(
                      'NOTAS DA SESSÃO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),
                // Corpo (texto ou placeholder)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isEmpty
                      ? Text(
                          'Toque para adicionar instruções, foco excêntrico ou detalhes deste treino...',
                          key: const ValueKey('empty_note'),
                          style: TextStyle(
                            color: AppTheme.textSecondary.withAlpha(140),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        )
                      : Text(
                          _noteText,
                          key: const ValueKey('filled_note'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteEditorModal extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onSave;

  const _NoteEditorModal({required this.initialText, required this.onSave});

  @override
  State<_NoteEditorModal> createState() => _NoteEditorModalState();
}

class _NoteEditorModalState extends State<_NoteEditorModal> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSave() {
    widget.onSave(_controller.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            // Evita que o teclado sobreponha o modal
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: GestureDetector(
                onTap: () {}, // Impede que toques no modal o fechem
                child: Container(
                  constraints: const BoxConstraints(
                    maxHeight: 300,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withAlpha(25),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(102),
                        blurRadius: 30,
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'EDITOR DE NOTAS',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            InkWell(
                              onTap: _handleSave,
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(40),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_rounded,
                                      color: AppTheme.primary,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Salvar',
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          maxLines: null,
                          scrollPadding: const EdgeInsets.all(20.0),
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                          ),
                          cursorColor: AppTheme.primary,
                          decoration: const InputDecoration(
                            isDense: true,
                            filled: false,
                            border: InputBorder.none,
                            hintText: 'Digite aqui...',
                            hintStyle: TextStyle(color: AppTheme.textSecondary),
                            contentPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
