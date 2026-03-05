import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final Map<String, String> _lastValues = {};
  final Map<String, bool> _hasUserEdited = {};
  final Set<String> _suppressNextOnChanged = {};
  final Set<String> _hapticTriggeredDismissKeys = {};

  @override
  void initState() {
    super.initState();
    ex = widget.exercicio;
  }

  @override
  void dispose() {
    _disposeControllers();
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

  Color _getSerieNumberColor(TipoSerie tipoSerie) {
    switch (tipoSerie) {
      case TipoSerie.trabalho:
        return AppTheme.primary;
      case TipoSerie.aquecimento:
        return AppTheme.iosAmber;
      case TipoSerie.feeder:
        return Colors.blueAccent;
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
    return const TextStyle(
      color: Color.fromARGB(150, 255, 255, 255),
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.25,
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

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space4,
      ),
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
          background: Container(color: Colors.black),
          secondaryBackground: Container(
            color: Colors.redAccent,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppTheme.space20),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          child: Container(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                    vertical: AppTheme.space8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 44,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('SÉRIE', style: _microLabelStyle()),
                            const SizedBox(height: AppTheme.space6),
                            Text(
                              '$visualNumber',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _getSerieNumberColor(serie.tipo),
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text('REPS', style: _microLabelStyle()),
                                  const SizedBox(height: AppTheme.space6),
                                  TextFormField(
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
                                      fontSize: 17,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    cursorColor: AppTheme.primary,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      fillColor: Colors.transparent,
                                      filled: false,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppTheme.space12),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text('CARGA', style: _microLabelStyle()),
                                  const SizedBox(height: AppTheme.space6),
                                  SizedBox(
                                    width: 74,
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
                                        fontSize: 17,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      cursorColor: AppTheme.primary,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        fillColor: Colors.transparent,
                                        filled: false,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppTheme.space12),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('DESCANSO', style: _microLabelStyle()),
                                  const SizedBox(height: AppTheme.space6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Icon(
                                        Icons.timer,
                                        color: Colors.white.withAlpha(170),
                                        size: 14,
                                      ),
                                      SizedBox(
                                        width: 44,
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
                                            fontSize: 17,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          cursorColor: AppTheme.primary,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                            border: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            fillColor: Colors.transparent,
                                            filled: false,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (showDivider)
                  Container(
                    margin: const EdgeInsets.only(left: 44, right: 24),
                    height: 0.5,
                    color: Colors.white.withAlpha(25),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<MapEntry<int, SerieItem>> entries,
  }) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: AppTheme.space10),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withAlpha(150),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          ...entries.asMap().entries.map((mapped) {
            final isLast = mapped.key == entries.length - 1;
            return _buildSerieRow(mapped.value, mapped.key + 1, !isLast);
          }),
        ],
      ),
    );
  }

  bool _isKeyboardVisible() {
    return MediaQuery.of(context).viewInsets.bottom > 0;
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
    final instructionsText = ex.observacao.trim().isEmpty
        ? 'Foco na profundidade e controle. Mantenha o tronco ereto e os joelhos alinhados com os pés. Empurre com os calcanhares.'
        : ex.observacao;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.black.withValues(alpha: 0.9),
            surfaceTintColor: Colors.transparent,
            pinned: true,
            expandedHeight: 130,
            leadingWidth: 108,
            leading: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.chevron_left,
                color: AppTheme.primary,
                size: 18,
              ),
              label: const Text(
                'Voltar',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.only(left: 2, right: 8),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text(
                  'Concluir',
                  style: TextStyle(
                    color: AppTheme.primary,
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
                AppTheme.space12,
                AppTheme.space16,
                AppTheme.space48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    muscleGroupsText,
                    style: TextStyle(
                      color: Colors.white.withAlpha(150),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
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
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withAlpha(20),
                            width: 0.5,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(
                              ex.imagemUrl ??
                                  'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&h=280&fit=crop',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(80),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withAlpha(30),
                                    width: 0.5,
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
                  const SizedBox(height: AppTheme.space28),
                  Text(
                    'INSTRUÇÕES',
                    style: TextStyle(
                      color: Colors.white.withAlpha(150),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space10),
                  Text(
                    instructionsText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
                  _buildSeriesSection(
                    icon: Icons.local_fire_department,
                    iconColor: const Color(0xFFFFB300),
                    title: 'AQUECIMENTO',
                    entries: warmupEntries,
                  ),
                  if (feederEntries.isNotEmpty) ...[
                    _buildSeriesSection(
                      icon: Icons.flash_on,
                      iconColor: Colors.blueAccent,
                      title: 'FEEDER',
                      entries: feederEntries,
                    ),
                  ],
                  if (workEntries.isNotEmpty) ...[
                    _buildSeriesSection(
                      icon: Icons.label,
                      iconColor: Colors.white,
                      title: 'SÉRIES DE TRABALHO',
                      entries: workEntries,
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
