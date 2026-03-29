import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class NoteEditorModal extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onSave;

  const NoteEditorModal({
    super.key,
    required this.initialText,
    required this.onSave,
  });

  @override
  State<NoteEditorModal> createState() => _NoteEditorModalState();
}

class _NoteEditorModalState extends State<NoteEditorModal> {
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
    HapticFeedback.lightImpact();
    widget.onSave(_controller.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
        border: Border(
          top: BorderSide(color: Colors.white.withAlpha(15), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle (Pill)
            Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(100),
              ),
            ),

            // Cabeçalho
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'NOTAS DA SESSÃO',
                    style: TextStyle(
                      color: AppTheme.labelSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleSave,
                      borderRadius: BorderRadius.circular(100),
                      splashColor: AppTheme.primary.withAlpha(30),
                      highlightColor: AppTheme.primary.withAlpha(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: AppTheme.primary.withAlpha(40),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Salvar',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.3,
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

            const SizedBox(height: 16),

            Divider(height: 1, thickness: 1, color: Colors.white.withAlpha(10)),

            // Área do Texto
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                  minHeight: 120,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  // Adicionado padding para a caixa de texto não tocar nas laterais do ecrã
                   padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    maxLines: null,
                    maxLength: 250,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                    cursorColor: AppTheme.primary,
                    cursorWidth: 2.5,
                    cursorRadius: const Radius.circular(2),
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) {
                          final bool isLimitReached =
                              currentLength == maxLength;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '$currentLength / $maxLength',
                              style: TextStyle(
                                color: isLimitReached
                                    ? Colors.redAccent
                                    : AppTheme.labelSecondary.withAlpha(120),
                                fontSize: 13,
                                fontWeight: isLimitReached
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          );
                        },
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.black.withAlpha(
                        60,
                      ), // Fundo translúcido escuro
                      hintText:
                          'Digite as instruções, foco ou detalhes aqui...',
                      hintStyle: TextStyle(
                        color: AppTheme.labelSecondary.withAlpha(120),
                        fontSize: 17,
                        fontStyle: FontStyle.italic,
                      ),
                      contentPadding: const EdgeInsets.all(
                        20,
                      ), // Espaçamento interno da caixa
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide.none, // Sem borda quando não está focado
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppTheme.primary.withAlpha(
                            120,
                          ), // Borda neon ao focar
                          width: 1.5,
                        ),
                      ),
                    ),
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