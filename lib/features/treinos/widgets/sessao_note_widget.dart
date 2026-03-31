import 'package:appfit/core/widgets/app_section_link_button.dart';
import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter/cupertino.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../configurar_treino_controller.dart';

class SessaoNoteWidget extends StatelessWidget {
  const SessaoNoteWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ConfigurarTreinoController>();
    final noteText = controller.sessaoNote;
    final isEmpty = noteText.trim().isEmpty;

    if (isEmpty) {
      return GestureDetector(
        onTap: () => _showEditNoteSheet(context, controller),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.doc_text, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Adicionar instruções gerais',
                style: AppTheme.bodyText.copyWith(
                  color: AppColors.primary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Nota de sessão', style: AppTheme.sectionHeader),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showEditNoteSheet(context, controller),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                  inset: true,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Icon(
                    CupertinoIcons.doc_text,
                    size: 16,
                    color: AppColors.labelTertiary,
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Text(
                    noteText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyText.copyWith(
                      color: AppColors.labelSecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.pencil,
                  size: 16,
                  color: AppColors.labelTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEditNoteSheet(
    BuildContext context,
    ConfigurarTreinoController controller,
  ) {
    HapticFeedback.lightImpact();
    final ctrl = TextEditingController(text: controller.sessaoNote);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background.withAlpha(235),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(100),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header do Modal
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.white.withAlpha(120),
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const Text(
                        'Notas da Sessão',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          controller.updateSessaoNote(ctrl.text.trim());
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Colors.white.withAlpha(20),
                ),
                // Campo de Texto
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: ctrl,
                        maxLines: 8,
                        maxLength: 500,
                        autofocus: true,
                        cursorColor: AppColors.primary,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Ex: "Focar na cadência do movimento e manter o abdômen contraído em todos os exercícios."',
                          hintStyle: TextStyle(
                            color: Colors.white.withAlpha(40),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: ctrl,
                        builder: (context, value, child) {
                          final remaining = 500 - value.text.length;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '$remaining caracteres disponíveis',
                                style: TextStyle(
                                  color: remaining < 50
                                      ? Colors.redAccent.withAlpha(200)
                                      : Colors.white.withAlpha(60),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
