import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/orange_glass_action_button.dart';
import '../../core/widgets/sliver_safe_title.dart';
import 'models/exercicio_model.dart';

class ExercicioDetalhePage extends StatefulWidget {
  final ExercicioItem exercicio;
  final VoidCallback onChanged;

  const ExercicioDetalhePage({
    super.key,
    required this.exercicio,
    required this.onChanged,
  });

  @override
  State<ExercicioDetalhePage> createState() => _ExercicioDetalhePageState();
}

class _ExercicioDetalhePageState extends State<ExercicioDetalhePage> {
  late ExercicioItem ex;
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _instructionsController = TextEditingController();
  final Map<String, String> _lastValues = {};
  final Map<String, bool> _hasUserEdited = {};
  final Set<String> _suppressNextOnChanged = {};
  final Set<String> _hapticTriggeredDismissKeys = {};

  @override
  void initState() {
    super.initState();
    ex = widget.exercicio;
    _instructionsController.text = ex.observacao;
  }

  @override
  void dispose() {
    _disposeControllers();
    _instructionsController.dispose();
    super.dispose();
  }

  void _disposeControllers() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  void _clearEditingState() {
    _disposeControllers();
    _lastValues.clear();
    _hasUserEdited.clear();
    _suppressNextOnChanged.clear();
  }

  TextEditingController _getController(String fieldKey, String initialValue) {
    if (!_controllers.containsKey(fieldKey)) {
      _controllers[fieldKey] = TextEditingController(text: initialValue);
    }
    return _controllers[fieldKey]!;
  }

  void _setControllerText(
    String fieldKey,
    TextEditingController controller,
    String value,
  ) {
    _suppressNextOnChanged.add(fieldKey);
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _startEditingField(String fieldKey, TextEditingController controller) {
    _lastValues[fieldKey] = controller.text;
    _hasUserEdited[fieldKey] = false;
    _setControllerText(fieldKey, controller, '');
  }

  void _restorePreviousIfNoChange({
    required String fieldKey,
    required TextEditingController controller,
    required void Function(String) onRestore,
    void Function(String)? onCommitEdited,
  }) {
    final hasEdited = _hasUserEdited[fieldKey] ?? false;
    if (!hasEdited) {
      final previousValue = _lastValues[fieldKey] ?? controller.text;
      _setControllerText(fieldKey, controller, previousValue);
      onRestore(previousValue);
      widget.onChanged();
    } else if (onCommitEdited != null) {
      final committed = controller.text.isEmpty ? '' : controller.text;
      onCommitEdited(committed);
      widget.onChanged();
    }
    _lastValues.remove(fieldKey);
    _hasUserEdited.remove(fieldKey);
  }

  void _handleFieldChanged({
    required String fieldKey,
    required TextEditingController controller,
    required String value,
    required String emptyFallback,
    required void Function(String) onSave,
  }) {
    if (_suppressNextOnChanged.contains(fieldKey)) {
      // Ignora apenas a limpeza programática; se já houver entrada do usuário,
      // processa normalmente para não perder a primeira digitação.
      if (value.isEmpty) {
        _suppressNextOnChanged.remove(fieldKey);
        return;
      }
      _suppressNextOnChanged.remove(fieldKey);
    }

    _hasUserEdited[fieldKey] = true;
    final nextValue = value.isEmpty ? emptyFallback : value;
    if (nextValue != value) {
      _setControllerText(fieldKey, controller, nextValue);
    }
    onSave(nextValue);
    widget.onChanged();
  }

  String _extractDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _formatCargaInputValue(String value) {
    if (value.trim() == '-') {
      return '-';
    }

    final digits = _extractDigits(value);
    if (digits.isEmpty) {
      return '';
    }
    return '${digits}kg';
  }

  String _formatDescansoInputValue(String value) {
    final digits = _extractDigits(value);
    if (digits.isEmpty) {
      return '';
    }
    return '${digits}s';
  }

  void _removerSerie(int realIndex) {
    setState(() {
      ex.series.removeAt(realIndex);
      _clearEditingState();
      widget.onChanged();
    });
  }

  void _removerSeriePorReferencia(SerieItem serie) {
    final index = ex.series.indexOf(serie);
    if (index == -1) {
      return;
    }
    _removerSerie(index);
  }

  Future<void> _adicionarSerie() async {
    final TipoSerie? tipoEscolhido = await showModalBottomSheet<TipoSerie>(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const Text(
                  'Adicionar Nova Série',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildModalOption(
                        title: 'Série de Aquecimento',
                        icon: Icons.whatshot,
                        color: Colors.amber,
                        onTap: () =>
                            Navigator.pop(context, TipoSerie.aquecimento),
                        showDivider: true,
                        subtitle: 'Preparação leve e articular.',
                      ),
                      _buildModalOption(
                        title: 'Feeder Set',
                        icon: Icons.flash_on,
                        color: Colors.blueAccent,
                        onTap: () => Navigator.pop(context, TipoSerie.feeder),
                        showDivider: true,
                        subtitle: 'Aproximação sem gerar fadiga.',
                      ),
                      _buildModalOption(
                        title: 'Série de Trabalho',
                        icon: Icons.tag,
                        color: Colors.white,
                        onTap: () => Navigator.pop(context, TipoSerie.trabalho),
                        showDivider: false,
                        subtitle: 'Série principal até a falha.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );

    if (tipoEscolhido != null) {
      setState(() {
        String alvoToClone = '10';
        String cargaToClone = '-';
        String descansoToClone = '60s';

        if (ex.series.isNotEmpty) {
          final ultimaSerie = ex.series.lastWhere(
            (s) => s.tipo == tipoEscolhido,
            orElse: () => ex.series.last,
          );
          alvoToClone = ultimaSerie.alvo;
          cargaToClone = ultimaSerie.carga;
          descansoToClone = ultimaSerie.descanso;
        }

        ex.series.add(
          SerieItem(
            tipo: tipoEscolhido,
            alvo: alvoToClone,
            carga: cargaToClone,
            descanso: descansoToClone,
          ),
        );
        widget.onChanged();
      });
    }
  }

  Widget _buildModalOption({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool showDivider,
    required String subtitle,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space16,
              vertical: AppTheme.space16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppTheme.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.textSecondary.withAlpha(160),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.black45,
            indent: 0,
          ),
      ],
    );
  }

  TextStyle _microLabelStyle() {
    return TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 9,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    );
  }

  TextStyle _sectionEyebrowStyle() {
    return TextStyle(
      color: AppTheme.textSecondary,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
    );
  }

  InputDecoration _editableFieldDecoration({
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
      horizontal: AppTheme.space12,
      vertical: 8,
    ),
  }) {
    return InputDecoration(
      isDense: true,
      contentPadding: contentPadding,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.1),
      ),
    );
  }

  Widget _buildSerieRow(
    MapEntry<int, SerieItem> entry,
    int visualNumber,
    bool showDivider,
  ) {
    final realIndex = entry.key;
    final serie = entry.value;
    final repsFieldKey = 'reps_$realIndex';
    final cargaFieldKey = 'carga_$realIndex';
    final descansoFieldKey = 'descanso_$realIndex';

    final repsController = _getController(repsFieldKey, serie.alvo);
    final cargaController = _getController(
      cargaFieldKey,
      _formatCargaInputValue(serie.carga),
    );
    final descansoController = _getController(
      descansoFieldKey,
      _formatDescansoInputValue(serie.descanso),
    );
    final dismissKey = '${serie.hashCode}_$realIndex';
    final borderRadius = BorderRadius.circular(14);

    // Inicio dos rows de séries
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space4),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Dismissible(
          key: ValueKey(dismissKey),
          direction: DismissDirection.endToStart,
          movementDuration: const Duration(milliseconds: 300),
          resizeDuration: const Duration(milliseconds: 300),
          dismissThresholds: const {DismissDirection.endToStart: 0.45},
          onUpdate: (details) {
            final reachedThreshold = details.progress >= 0.45;
            if (reachedThreshold &&
                !_hapticTriggeredDismissKeys.contains(dismissKey)) {
              _hapticTriggeredDismissKeys.add(dismissKey);
              HapticFeedback.mediumImpact();
            } else if (!reachedThreshold) {
              _hapticTriggeredDismissKeys.remove(dismissKey);
            }
          },
          onDismissed: (_) {
            _hapticTriggeredDismissKeys.remove(dismissKey);
            _removerSeriePorReferencia(serie);
          },
          background: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.space4,
              horizontal: AppTheme.space16,
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Container(color: Colors.black),
            ),
          ),
          secondaryBackground: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.space4,
              horizontal: AppTheme.space16,
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Container(
                color: Colors.redAccent,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppTheme.space20),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.space4,
                  horizontal: 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space12,
                          vertical: AppTheme.space10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 18),
                                  child: Text(
                                    '$visualNumber',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: _microLabelStyle().color,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextFormField(
                                      controller: repsController,
                                      onTap: () {
                                        _startEditingField(
                                          repsFieldKey,
                                          repsController,
                                        );
                                      },
                                      onChanged: (val) {
                                        _handleFieldChanged(
                                          fieldKey: repsFieldKey,
                                          controller: repsController,
                                          value: val,
                                          emptyFallback: '0',
                                          onSave: (saved) => serie.alvo = saved,
                                        );
                                      },
                                      onFieldSubmitted: (_) {
                                        _restorePreviousIfNoChange(
                                          fieldKey: repsFieldKey,
                                          controller: repsController,
                                          onRestore: (restored) =>
                                              serie.alvo = restored,
                                        );
                                      },
                                      onTapOutside: (_) {
                                        _restorePreviousIfNoChange(
                                          fieldKey: repsFieldKey,
                                          controller: repsController,
                                          onRestore: (restored) =>
                                              serie.alvo = restored,
                                        );
                                      },
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      cursorColor: AppTheme.primary,
                                      decoration: _editableFieldDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: AppTheme.space8,
                                              vertical: 6,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextFormField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: const [
                                        _CargaKgInputFormatter(),
                                      ],
                                      controller: cargaController,
                                      onTap: () {
                                        _startEditingField(
                                          cargaFieldKey,
                                          cargaController,
                                        );
                                      },
                                      onChanged: (val) {
                                        _handleFieldChanged(
                                          fieldKey: cargaFieldKey,
                                          controller: cargaController,
                                          value: val,
                                          emptyFallback: '-',
                                          onSave: (saved) =>
                                              serie.carga = saved,
                                        );
                                      },
                                      onFieldSubmitted: (_) {
                                        _restorePreviousIfNoChange(
                                          fieldKey: cargaFieldKey,
                                          controller: cargaController,
                                          onRestore: (restored) =>
                                              serie.carga = restored,
                                          onCommitEdited: (committed) {
                                            serie.carga = committed.isEmpty
                                                ? '-'
                                                : committed;
                                          },
                                        );
                                      },
                                      onTapOutside: (_) {
                                        _restorePreviousIfNoChange(
                                          fieldKey: cargaFieldKey,
                                          controller: cargaController,
                                          onRestore: (restored) =>
                                              serie.carga = restored,
                                          onCommitEdited: (committed) {
                                            serie.carga = committed.isEmpty
                                                ? '-'
                                                : committed;
                                          },
                                        );
                                      },
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      cursorColor: AppTheme.primary,
                                      decoration: _editableFieldDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: AppTheme.space8,
                                              vertical: 6,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextFormField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: const [
                                        _DescansoSecondsInputFormatter(),
                                      ],
                                      controller: descansoController,
                                      onTap: () {
                                        _startEditingField(
                                          descansoFieldKey,
                                          descansoController,
                                        );
                                      },
                                      onChanged: (val) {
                                        _handleFieldChanged(
                                          fieldKey: descansoFieldKey,
                                          controller: descansoController,
                                          value: val,
                                          emptyFallback: '0',
                                          onSave: (saved) =>
                                              serie.descanso = saved,
                                        );
                                      },
                                      onFieldSubmitted: (_) {
                                        _restorePreviousIfNoChange(
                                          fieldKey: descansoFieldKey,
                                          controller: descansoController,
                                          onRestore: (restored) =>
                                              serie.descanso = restored,
                                        );
                                      },
                                      onTapOutside: (_) {
                                        _restorePreviousIfNoChange(
                                          fieldKey: descansoFieldKey,
                                          controller: descansoController,
                                          onRestore: (restored) =>
                                              serie.descanso = restored,
                                        );
                                      },
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      cursorColor: AppTheme.primary,
                                      decoration: _editableFieldDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: AppTheme.space8,
                                              vertical: 6,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildSeriesSection({
    IconData? icon,
    Color? iconColor,
    required String title,
    required List<MapEntry<int, SerieItem>> entries,
    Color? titleColor,
    bool showDot = false,
  }) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppTheme.space4,
              right: AppTheme.space12,
              bottom: AppTheme.space10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                showDot
                    ? Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: titleColor ?? Colors.white,
                          shape: BoxShape.circle,
                        ),
                      )
                    : (icon != null
                          ? Icon(icon, color: iconColor, size: 18)
                          : SizedBox(width: 18)),
                const SizedBox(width: AppTheme.space10),
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor ?? Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space0,
              AppTheme.space12,
              AppTheme.space0,
              AppTheme.space12,
            ),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.space4,
                    horizontal: AppTheme.space12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: AppTheme.space8,
                                  ),
                                  child: Text(
                                    'SÉRIE',
                                    style: _microLabelStyle(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Expanded(
                              flex: 3,
                              child: Center(
                                child: Text('REPS', style: _microLabelStyle()),
                              ),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Expanded(
                              flex: 3,
                              child: Center(
                                child: Text('PESO', style: _microLabelStyle()),
                              ),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Expanded(
                              flex: 3,
                              child: Center(
                                child: Text(
                                  'DESCANSO',
                                  style: _microLabelStyle(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ...entries.asMap().entries.map((mapped) {
                  final isLast = mapped.key == entries.length - 1;
                  return _buildSerieRow(mapped.value, mapped.key + 1, !isLast);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isKeyboardVisible() {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  Future<void> _editarInstrucoes() async {
    _instructionsController
      ..text = ex.observacao
      ..selection = TextSelection.collapsed(offset: ex.observacao.length);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        final insets = MediaQuery.of(modalContext).viewInsets;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space12,
              AppTheme.space16,
              insets.bottom + AppTheme.space16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                const Text(
                  'Instruções do exercício',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.space6),
                Text(
                  'Opcional: adicione orientações para execução.',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withAlpha(180),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppTheme.space14),
                TextField(
                  controller: _instructionsController,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Ex.: mantenha o tronco estável e controle a fase excêntrica.',
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondary.withAlpha(135),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: Colors.white.withAlpha(8),
                    contentPadding: const EdgeInsets.all(AppTheme.space12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      borderSide: const BorderSide(
                        color: AppTheme.accentMetrics,
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space14),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(modalContext),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            ex.observacao = _instructionsController.text.trim();
                          });
                          widget.onChanged();
                          Navigator.pop(modalContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentMetrics,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Salvar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final exerciseTitle = SliverSafeTitle.safeTitle(
      ex.nome,
      fallback: 'Exercício',
    );
    final warmupEntries = ex.series
        .asMap()
        .entries
        .where((e) => e.value.tipo == TipoSerie.aquecimento)
        .toList();
    final feederEntries = ex.series
        .asMap()
        .entries
        .where((e) => e.value.tipo == TipoSerie.feeder)
        .toList();
    final workEntries = ex.series
        .asMap()
        .entries
        .where((e) => e.value.tipo == TipoSerie.trabalho)
        .toList();
    final muscleGroupsText = ex.grupoMuscular.trim().isEmpty
        ? 'EXERCÍCIO'
        : ex.grupoMuscular
              .toUpperCase()
              .replaceAll(RegExp(r'\s*,\s*'), ' • ')
              .replaceAll(RegExp(r'\s+/\s+'), ' • ');
    final instructionsText = ex.observacao.trim();

    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.black,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              expandedHeight: 138,
              leadingWidth: 60,
              leading: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Material(
                    color: AppTheme.buttonSurface,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          CupertinoIcons.back,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accentMetrics,
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text(
                    'Concluir',
                    style: TextStyle(
                      color: AppTheme.accentMetrics,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double collapsedHeight =
                      MediaQuery.of(context).padding.top + kToolbarHeight;
                  final bool isCollapsed =
                      constraints.biggest.height <= collapsedHeight + 20;

                  return FlexibleSpaceBar(
                    centerTitle: true,
                    titlePadding: const EdgeInsets.only(bottom: 16),
                    title: SliverSafeTitle(
                      title: exerciseTitle,
                      isVisible: isCollapsed,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    background: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: AppTheme.space16,
                          right: AppTheme.space16,
                          bottom: 10,
                        ),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isCollapsed ? 0.0 : 1.0,
                          child: Text(
                            exerciseTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space16,
                  AppTheme.space4,
                  AppTheme.space16,
                  AppTheme.space48,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(muscleGroupsText, style: _sectionEyebrowStyle()),
                    const SizedBox(height: AppTheme.space16),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Abrindo vídeo explicativo de $exerciseTitle...',
                            ),
                            backgroundColor: AppTheme.primary,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(
                                    ex.imagemUrl ??
                                        'https://lh3.googleusercontent.com/aida-public/AB6AXuAXzEmkEB7BMnRUWQ6iIDF5Oc_gVzBjCjxHaac9LYJyL8KxdAi-mTOKK2v2nO9Vt3-DXPcDcoSM3RkTh-iDX0q8oShyD0TllFVTVsQBP3fKU0HPHHtOlkO5uRRx_yIiMes1tmlEr6VkkMyvhy-LTIzYuWYuJaLsSzeba5FPnNX9_RQjcusWmbIyWrBVLVSmLZjDaMcPJMKiSSY6S-RSZFaAzRzHQdDbWnPbv1aUP1akkwSiPE9Rriwmdn8VrF3w0ZIWei1Cxfd7B2Ut',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(88),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withAlpha(35),
                                          width: 0.9,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 30,
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
                    const SizedBox(height: AppTheme.space20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        AppTheme.space16,
                        0,
                        AppTheme.space16,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (instructionsText.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'INSTRUÇÕES',
                                  style: _sectionEyebrowStyle(),
                                ),
                                TextButton(
                                  onPressed: _editarInstrucoes,
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.accentMetrics,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.space0,
                                      vertical: AppTheme.space6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Editar',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(width: AppTheme.space4),
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 14,
                                        color: AppTheme.accentMetrics,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          if (instructionsText.isNotEmpty)
                            const SizedBox(height: AppTheme.space10),
                          if (instructionsText.isEmpty)
                            Semantics(
                              button: true,
                              label: 'Adicionar instruções',
                              child: InkWell(
                                onTap: _editarInstrucoes,
                                borderRadius: BorderRadius.circular(999),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 44,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.space14,
                                      vertical: AppTheme.space10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceDark,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Colors.white.withAlpha(58),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Adicionar instruções',
                                          style: TextStyle(
                                            color: AppTheme.accentMetrics,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                        const SizedBox(width: AppTheme.space8),
                                        Icon(
                                          CupertinoIcons.add,
                                          color: AppTheme.accentMetrics,
                                          size: 15,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Text(
                              instructionsText,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.space24),
                    _buildSeriesSection(
                      icon: null,
                      iconColor: null,
                      title: 'AQUECIMENTO',
                      entries: warmupEntries,
                      titleColor: const Color(0xFF60A5FA),
                      showDot: true,
                    ),
                    if (feederEntries.isNotEmpty) ...[
                      _buildSeriesSection(
                        icon: null,
                        iconColor: null,
                        title: 'FEEDER',
                        entries: feederEntries,
                        titleColor: const Color(0xFFFF6B00),
                        showDot: true,
                      ),
                    ],
                    if (workEntries.isNotEmpty) ...[
                      _buildSeriesSection(
                        icon: null,
                        iconColor: null,
                        title: 'SÉRIES DE TRABALHO',
                        entries: workEntries,
                        titleColor: const Color(0xFF0df259),
                        showDot: true,
                      ),
                    ],
                    const SizedBox(height: AppTheme.space40),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: AnimatedScale(
          scale: _isKeyboardVisible() ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: OrangeGlassActionButton(
            label: 'Adicionar Série',
            onTap: _adicionarSerie,
            bottomMargin: 24,
          ),
        ),
      ),
    );
  }
}

class _CargaKgInputFormatter extends TextInputFormatter {
  const _CargaKgInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = '${digits}kg';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: digits.length),
      composing: TextRange.empty,
    );
  }
}

class _DescansoSecondsInputFormatter extends TextInputFormatter {
  const _DescansoSecondsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = '${digits}s';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: digits.length),
      composing: TextRange.empty,
    );
  }
}
