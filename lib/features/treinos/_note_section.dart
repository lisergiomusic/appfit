import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class NoteSection extends StatefulWidget {
  const NoteSection({super.key});

  @override
  State<NoteSection> createState() => _NoteSectionState();
}

class _NoteSectionState extends State<NoteSection> {
  String _notaSalva = '';
  bool _isEditing = false;

  void _abrirEditorModal(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    final screenWidth = MediaQuery.of(context).size.width;
    final modalWidth = screenWidth - 48;
    final leftPosition = 24.0;

    setState(() => _isEditing = true);

    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      barrierDismissible: true,
      barrierLabel: 'Fechar editor',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _EditorModal(
          initialTop: offset.dy,
          initialLeft: leftPosition,
          width: modalWidth,
          notaInicial: _notaSalva,
          onSave: (novaNota) {
            setState(() {
              _notaSalva = novaNota;
            });
          },
        );
      },
    ).then((_) {
      if (mounted) setState(() => _isEditing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: _isEditing ? 0.0 : 1.0,
      curve: Curves.easeInOut,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _notaSalva.isNotEmpty
            ? _buildInlineNote(context)
            : _buildAddNoteAction(context),
      ),
    );
  }

  Widget _buildInlineNote(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('saved_note_inline'),
      onTap: () => _abrirEditorModal(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Icon(
                Icons.sticky_note_2,
                size: 14,
                color: Color(0xFFFF6D00),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _notaSalva,
                softWrap: true,
                style: const TextStyle(
                  color: Color.fromARGB(160, 255, 255, 255),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNoteAction(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('empty_button_inline'),
      onTap: () => _abrirEditorModal(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center, // Alinhamento central
          children: const [
            Padding(
              padding: EdgeInsets.only(
                top: 3,
              ), // Ajuste fino para mover o ícone um pouco mais para cima
              child: Icon(
                Icons.sticky_note_2,
                size: 14,
                color: Color(0xFFFF6D00),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Adicionar observação do treino',
                softWrap: true,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === WIDGET DO MODAL DE EDIÇÃO ===
class _EditorModal extends StatefulWidget {
  final double initialTop;
  final double initialLeft;
  final double width;
  final String notaInicial;
  final ValueChanged<String> onSave;

  const _EditorModal({
    required this.initialTop,
    required this.initialLeft,
    required this.width,
    required this.notaInicial,
    required this.onSave,
  });

  @override
  State<_EditorModal> createState() => _EditorModalState();
}

class _EditorModalState extends State<_EditorModal> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.notaInicial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _salvarEFechar() {
    HapticFeedback.lightImpact();
    widget.onSave(_controller.text.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final screenHeight = MediaQuery.of(context).size.height;

    double topPosition = widget.initialTop;
    const estimatedHeight = 240.0;

    if (topPosition + estimatedHeight > screenHeight - viewInsets.bottom) {
      topPosition = screenHeight - viewInsets.bottom - estimatedHeight - 16;
      if (topPosition < MediaQuery.of(context).padding.top + 16) {
        topPosition = MediaQuery.of(context).padding.top + 16;
      }
    }

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              top: topPosition,
              left: widget.initialLeft,
              width: widget.width,
              child: GestureDetector(
                onTap: () {},
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 10),
                              child: Text(
                                'EDITOR DE OBSERVAÇÕES',
                                style: TextStyle(
                                  color: Color(0xFFD4D4D8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 4,
                              bottom: 10,
                            ),
                            child: GestureDetector(
                              onTap: _salvarEFechar,
                              child: const Icon(
                                Icons.check_circle,
                                color: AppTheme.primary,
                                size: 32,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 160),
                        decoration: BoxDecoration(
                          color: AppTheme
                              .buttonSurface, // O mesmo Cinza Sólido do HTML aqui no modal
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            height: 1.4,
                          ),
                          cursorColor: AppTheme.primary,
                          decoration: const InputDecoration(
                            filled: false,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            hintText: 'Digite uma nota sobre este treino...',
                            hintStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                            contentPadding: EdgeInsets.all(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
