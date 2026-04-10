import 'package:flutter/material.dart';
import '../../models/exercicio_model.dart';
import '../../../../../core/theme/app_theme.dart';
import 'exercicio_constants.dart';
import 'exercicio_editable_field.dart';
import 'hinting_serie_animator.dart';

class SerieRow extends StatefulWidget {
  final SerieItem serie;
  final int visualNumber;
  final bool isFirst;
  final bool isLast;
  final bool isNew;
  final bool isEditingSection;
  final TextEditingController repsController;
  final TextEditingController cargaController;
  final TextEditingController descansoController;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final void Function(String field, String value) onFieldChanged;
  final VoidCallback onHintEnd;
  final Color accentColor;

  const SerieRow({
    super.key,
    required this.serie,
    required this.visualNumber,
    required this.isFirst,
    required this.isLast,
    required this.isNew,
    required this.isEditingSection,
    required this.repsController,
    required this.cargaController,
    required this.descansoController,
    required this.onDelete,
    required this.onDuplicate,
    required this.onFieldChanged,
    required this.onHintEnd,
    required this.accentColor,
  });

  @override
  State<SerieRow> createState() => _SerieRowState();
}

class _SerieRowState extends State<SerieRow> with TickerProviderStateMixin {
  AnimationController? _flashController;

  void playFlash() {
    if (!mounted) return;

    _flashController?.dispose();
    _flashController = AnimationController(
      duration: ExercicioDetalheConstants.flashAnimationDuration,
      vsync: this,
    );
    _flashController?.forward().then((_) {
      if (mounted) {
        setState(() {
          _flashController?.dispose();
          _flashController = null;
        });
      }
    });
    setState(() {});
  }

  @override
  void dispose() {
    _flashController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(AppTheme.radiusXL);
    final borderRadius = BorderRadius.only(
      topLeft: widget.isFirst ? radius : Radius.zero,
      topRight: widget.isFirst ? radius : Radius.zero,
      bottomLeft: widget.isLast ? radius : Radius.zero,
      bottomRight: widget.isLast ? radius : Radius.zero,
    );

    Widget content(Color? hintColor) {
      return _buildRowContent(hintColor);
    }

    Widget card;
    if (widget.isNew) {
      card = HintingSerieAnimator(
        onEnd: widget.onHintEnd,
        builder: (context, color) => content(color),
      );
    } else {
      card = content(null);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Dismissible(
        key: ValueKey(widget.serie.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => widget.onDelete(),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, AppColors.systemRed.withAlpha(220)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 18),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_rounded, color: Colors.white, size: 20),
              SizedBox(height: 3),
              Text(
                'Remover',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        child: card,
      ),
    );
  }

  Widget _buildRowContent(Color? hintColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _flashController ?? const AlwaysStoppedAnimation(0.0),
          builder: (context, child) {
            final editFlashColor = _flashController != null
                ? ColorTween(
                    begin: widget.accentColor.withAlpha(40),
                    end: Colors.transparent,
                  ).animate(_flashController!).value
                : Colors.transparent;

            return Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: 6,
              ),
              color: hintColor ?? editFlashColor,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: ExercicioDetalheConstants.rowAnimationDuration,
                    curve: Curves.easeInOutCubic,
                    width: widget.isEditingSection ? 28 : 0,
                    child: AnimatedOpacity(
                      duration: ExercicioDetalheConstants.fadeAnimationDuration,
                      opacity: widget.isEditingSection ? 1.0 : 0.0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: widget.onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: ExercicioDetalheConstants.rowAnimationDuration,
                    curve: Curves.easeInOutCubic,
                    width: widget.isEditingSection ? 8 : 0,
                  ),
                  Expanded(
                    flex: 2,
                    child: AnimatedPadding(
                      duration: ExercicioDetalheConstants.rowAnimationDuration,
                      curve: Curves.easeInOutCubic,
                      padding: EdgeInsets.only(
                        left: widget.isEditingSection ? 2 : 6,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: widget.accentColor.withAlpha(22),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSM,
                            ),
                          ),
                          child: Text(
                            '${widget.visualNumber}',
                            style: TextStyle(
                              color: widget.accentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: ExercicioEditableField(
                      controller: widget.repsController,
                      onChanged: (val) {
                        widget.onFieldChanged('reps', val);
                        playFlash();
                      },
                      hintText: 'Ex: 8-12',
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    flex: 3,
                    child: ExercicioEditableField(
                      controller: widget.cargaController,
                      onChanged: (val) {
                        widget.onFieldChanged('carga', val);
                        playFlash();
                      },
                      maxLength: 5,
                      suffixText: 'kg',
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    flex: 3,
                    child: ExercicioEditableField(
                      controller: widget.descansoController,
                      onChanged: (val) {
                        widget.onFieldChanged('descanso', val);
                        playFlash();
                      },
                      maxLength: 8,
                      suffixText: 's',
                      hintText: 'Ex: 60s',
                      keyboardType: TextInputType.number,
                    ),
                  ),

                  AnimatedContainer(
                    duration: ExercicioDetalheConstants.rowAnimationDuration,
                    curve: Curves.easeInOutCubic,
                    width: widget.isEditingSection ? 8 : 0,
                  ),
                  AnimatedContainer(
                    duration: ExercicioDetalheConstants.rowAnimationDuration,
                    curve: Curves.easeInOutCubic,
                    width: widget.isEditingSection ? 26 : 0,
                    child: AnimatedOpacity(
                      duration: ExercicioDetalheConstants.fadeAnimationDuration,
                      opacity: widget.isEditingSection ? 1.0 : 0.0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.copy_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        onPressed: widget.onDuplicate,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (!widget.isLast)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.white.withAlpha(10),
            ),
          ),
      ],
    );
  }
}
