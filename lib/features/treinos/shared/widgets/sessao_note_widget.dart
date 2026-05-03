import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../personal/controllers/configurar_treino_controller.dart';

class SessaoNoteWidget extends StatefulWidget {
  const SessaoNoteWidget({super.key});

  @override
  State<SessaoNoteWidget> createState() => _SessaoNoteWidgetState();
}

class _SessaoNoteWidgetState extends State<SessaoNoteWidget> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final initialNote = context.read<ConfigurarTreinoController>().sessaoNote;
    _controller = TextEditingController(text: initialNote);
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFocus = _focusNode.hasFocus;
    final configController = context.watch<ConfigurarTreinoController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Instruções da Sessão',
              style: AppTheme.sectionHeader,
            ),
            if (hasFocus)
              GestureDetector(
                onTap: () {
                  _focusNode.unfocus();
                  configController.updateSessaoNote(_controller.text.trim());
                },
                child: const Row(
                  children: [
                    Text(
                      'Concluir',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.check_rounded,
                      color: AppColors.primary,
                      size: 14,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: SpacingTokens.labelToField),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: 2,
          maxLength: 200,
          style: AppTheme.bodyText,
          cursorColor: AppColors.primary,
          onChanged: (val) => configController.updateSessaoNote(val.trim()),
          decoration: InputDecoration(
            hintText: 'Ex: Beber 500ml de água durante o treino e respeitar o descanso...',
            hintStyle: TextStyle(
              color: Colors.white.withAlpha(40),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            filled: true,
            fillColor: AppColors.surfaceDark,
            contentPadding: const EdgeInsets.all(16),
            counterText: hasFocus ? null : '',
            counterStyle: const TextStyle(
              color: AppColors.labelTertiary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              borderSide: const BorderSide(color: AppColors.primary, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}