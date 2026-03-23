import 'package:appfit/core/widgets/appfit_sliver_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/orange_glass_action_button.dart';
import '../../core/widgets/sliver_safe_title.dart';
import 'models/exercicio_model.dart';
import 'exercicio_detalhe_controller.dart';

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

class _ExercicioDetalhePageState extends State<ExercicioDetalhePage>
    with TickerProviderStateMixin {
  late final ExercicioItem ex;
  late final ExercicioDetalheController controller;
  final Map<TipoSerie, GlobalKey<AnimatedListState>> _animatedListKeys = {
    TipoSerie.aquecimento: GlobalKey<AnimatedListState>(),
    TipoSerie.feeder: GlobalKey<AnimatedListState>(),
    TipoSerie.trabalho: GlobalKey<AnimatedListState>(),
  };
  final ScrollController _scrollController = ScrollController();
  final Map<int, AnimationController> _swipeHintControllers = {};
  final Map<int, AnimationController> _rippleControllers = {};
  Timer? _undoSnackTimer;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _lastValues = {};
  final Map<String, bool> _hasUserEdited = {};
  final Set<String> _suppressNextOnChanged = {};
  final Map<int, AnimationController> _flashControllers = {};

  @override
  void initState() {
    super.initState();
    ex = widget.exercicio;
    controller = ExercicioDetalheController(ex);
  }

  @override
  void dispose() {
    _disposeControllers();
    _disposeCardAnimationControllers();
    _disposeFlashControllers();
    _undoSnackTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _disposeFlashControllers() {
    for (final ctrl in _flashControllers.values) {
      ctrl.dispose();
    }
    _flashControllers.clear();
  }

  void _disposeCardAnimationControllers() {
    for (final ctrl in _swipeHintControllers.values) {
      ctrl.dispose();
    }
    _swipeHintControllers.clear();
    for (final ctrl in _rippleControllers.values) {
      ctrl.dispose();
    }
    _rippleControllers.clear();
  }

  void _disposeControllers() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
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

  void _setControllerText(String fieldKey, TextEditingController controller, String value) {
    _suppressNextOnChanged.add(fieldKey);
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _playFlashAnimation(int serieHash) {
    _flashControllers[serieHash]?.dispose();
    final flashController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flashControllers[serieHash] = flashController;
    flashController.forward().then((_) {
      if (mounted) {
        flashController.dispose();
        _flashControllers.remove(serieHash);
      }
    });
  }

  void _handleFieldChanged({
    required String fieldKey,
    required TextEditingController controller,
    required String value,
    required String emptyFallback,
    required void Function(String) onSave,
    required int serieHash,
  }) {
    if (_suppressNextOnChanged.contains(fieldKey)) {
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
    _playFlashAnimation(serieHash);
  }

  String _extractDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _formatCargaInputValue(String value) {
    if (value.trim() == '-') return '-';
    final digits = _extractDigits(value);
    return digits.isEmpty ? '' : '${digits}kg';
  }

  String _formatDescansoInputValue(String value) {
    final digits = _extractDigits(value);
    return digits.isEmpty ? '' : '${digits}s';
  }

  Future<void> _adicionarSerie() async {
    final TipoSerie? tipoEscolhido = await showModalBottomSheet<TipoSerie>(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
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
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
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
                        onTap: () => Navigator.pop(context, TipoSerie.aquecimento),
                        showDivider: true,
                        subtitle: 'Prepara articulações e ativa músculos.',
                      ),
                      _buildModalOption(
                        title: 'Feeder Set',
                        icon: Icons.flash_on,
                        color: Colors.blueAccent,
                        onTap: () => Navigator.pop(context, TipoSerie.feeder),
                        showDivider: true,
                        subtitle: 'Aproximação progressiva sem fadiga.',
                      ),
                      _buildModalOption(
                        title: 'Série de Trabalho',
                        icon: Icons.tag,
                        color: Colors.white,
                        onTap: () => Navigator.pop(context, TipoSerie.trabalho),
                        showDivider: false,
                        subtitle: 'Série efetiva próxima à falha muscular.',
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
      String alvoToClone = '10', cargaToClone = '-', descansoToClone = '60s';
      if (ex.series.isNotEmpty) {
        final ultimaSerie = ex.series.lastWhere((s) => s.tipo == tipoEscolhido, orElse: () => ex.series.last);
        alvoToClone = ultimaSerie.alvo;
        cargaToClone = ultimaSerie.carga;
        descansoToClone = ultimaSerie.descanso;
      }

      final newSerie = SerieItem(tipo: tipoEscolhido, alvo: alvoToClone, carga: cargaToClone, descanso: descansoToClone);
      final sectionList = controller.entriesForTipo(tipoEscolhido);
      final insertSectionIndex = sectionList.length;
      final insertRealIndex = controller.computeInsertRealIndex(tipoEscolhido);

      setState(() { controller.insertAt(insertRealIndex, newSerie); });

      Future.microtask(() {
        _animatedListKeys[tipoEscolhido]?.currentState?.insertItem(insertSectionIndex, duration: const Duration(milliseconds: 300));
      });

      widget.onChanged();
    }
  }

  Widget _buildModalOption({required String title, required IconData icon, required Color color, required VoidCallback onTap, required bool showDivider, required String subtitle}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppTheme.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: AppTheme.textSecondary.withAlpha(160), fontSize: 11), maxLines: 1),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, thickness: 0.5, color: Colors.white.withAlpha(20)),
      ],
    );
  }

  TextStyle _microLabelStyle() => const TextStyle(color: AppTheme.silverGrey, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8);
  TextStyle _sectionEyebrowStyle() => const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0);

  InputDecoration _editableFieldDecoration() {
    return const InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space10),
      focusedBorder: InputBorder.none,
      enabledBorder: InputBorder.none,
    );
  }

  // --- WIDGET DE LINHA DA SÉRIE ---
  Widget _buildSerieRow(SerieItem serie, int realIndex, int visualNumber, bool isFirst, bool isLast) {
    final stableId = serie.hashCode;
    final repsController = _getController('reps_$stableId', serie.alvo);
    final cargaController = _getController('carga_$stableId', _formatCargaInputValue(serie.carga));
    final descansoController = _getController('descanso_$stableId', _formatDescansoInputValue(serie.descanso));

    final radius = Radius.circular(AppTheme.radiusMedium);
    final borderRadius = BorderRadius.only(
      topLeft: isFirst ? radius : Radius.zero,
      topRight: isFirst ? radius : Radius.zero,
      bottomLeft: isLast ? radius : Radius.zero,
      bottomRight: isLast ? radius : Radius.zero,
    );

    return Column(
      children: [
        ClipRRect(
          borderRadius: borderRadius,
          child: Dismissible(
            key: ValueKey('${serie.hashCode}'),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              final idx = ex.series.indexOf(serie);
              if (idx == -1) return;
              final sectionIndex = controller.sectionIndexOf(serie);
              setState(() { controller.removeAt(idx); _clearEditingState(); });
              _animatedListKeys[serie.tipo]?.currentState?.removeItem(
                sectionIndex,
                    (context, animation) => SizeTransition(sizeFactor: animation, child: Container()),
              );
              widget.onChanged();
            },
            background: Container(
                color: Colors.redAccent,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete_outline, color: Colors.white)
            ),
            child: AnimatedBuilder(
              animation: _flashControllers[serie.hashCode] ?? const AlwaysStoppedAnimation(0.0),
              builder: (context, child) {
                final flashCtrl = _flashControllers[serie.hashCode];
                final flashColor = flashCtrl != null
                    ? ColorTween(begin: AppTheme.accentMetrics.withAlpha(50), end: Colors.transparent).animate(flashCtrl).value
                    : Colors.transparent;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space4),
                  color: flashColor,
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Padding(padding: const EdgeInsets.only(left: 18), child: Text('$visualNumber', style: const TextStyle(color: AppTheme.silverGrey, fontSize: 14, fontWeight: FontWeight.w700)))),
                      const SizedBox(width: AppTheme.space8),
                      Expanded(flex: 3, child: _buildEditableField(repsController, (val) => _handleFieldChanged(fieldKey: 'reps_$realIndex', controller: repsController, value: val, emptyFallback: '0', onSave: (s) => serie.alvo = s, serieHash: serie.hashCode))),
                      const SizedBox(width: AppTheme.space8),
                      Expanded(flex: 3, child: _buildEditableField(cargaController, (val) => _handleFieldChanged(fieldKey: 'carga_$realIndex', controller: cargaController, value: val, emptyFallback: '-', onSave: (s) => serie.carga = s, serieHash: serie.hashCode), inputFormatters: [const _CargaKgInputFormatter()])),
                      const SizedBox(width: AppTheme.space8),
                      Expanded(flex: 3, child: _buildEditableField(descansoController, (val) => _handleFieldChanged(fieldKey: 'descanso_$realIndex', controller: descansoController, value: val, emptyFallback: '0', onSave: (s) => serie.descanso = s, serieHash: serie.hashCode), inputFormatters: [const _DescansoSecondsInputFormatter()])),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, thickness: 0.5, color: Colors.white.withAlpha(15), indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildEditableField(TextEditingController ctrl, ValueChanged<String> onChanged, {List<TextInputFormatter>? inputFormatters}) {
    return TextFormField(
      controller: ctrl,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: _editableFieldDecoration(),
    );
  }

  // --- WIDGET DA SEÇÃO DE SÉRIES (O CARD AGRUPADO) ---
  Widget _buildSeriesSection({required String title, required List<MapEntry<int, SerieItem>> entries, Color? titleColor, bool showDot = false}) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Text(title, style: TextStyle(color: titleColor ?? Colors.white, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5,)),
            ]),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: Colors.white.withAlpha(20), width: 0.5),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: Row(children: [
                    Expanded(flex: 3, child: Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(left: 8), child: Text('SÉRIE', style: _microLabelStyle())))),
                    Expanded(flex: 3, child: Center(child: Text('REPS', style: _microLabelStyle()))),
                    Expanded(flex: 3, child: Center(child: Text('PESO', style: _microLabelStyle()))),
                    Expanded(flex: 3, child: Center(child: Text('DESCANSO', style: _microLabelStyle()))),
                  ]),
                ),
                AnimatedList(
                  key: _animatedListKeys[entries.first.value.tipo],
                  initialItemCount: entries.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index, animation) {
                    final mapped = entries[index];
                    return SizeTransition(
                      sizeFactor: animation,
                      child: _buildSerieRow(mapped.value, mapped.key, index + 1, index == 0, index == entries.length - 1),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exerciseTitle = SliverSafeTitle.safeTitle(ex.nome, fallback: 'Exercício');
    final warmup = ex.series.asMap().entries.where((e) => e.value.tipo == TipoSerie.aquecimento).toList();
    final feeder = ex.series.asMap().entries.where((e) => e.value.tipo == TipoSerie.feeder).toList();
    final work = ex.series.asMap().entries.where((e) => e.value.tipo == TipoSerie.trabalho).toList();

    final muscleGroupsText = ex.grupoMuscular.isEmpty ? 'GERAL' : ex.grupoMuscular.join(' • ').toUpperCase();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              AppFitSliverAppBar(
                  title: exerciseTitle,
                  background: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(exerciseTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))
                      )
                  )
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(muscleGroupsText, style: _sectionEyebrowStyle()),
                      const SizedBox(height: AppTheme.space16),

                      // Thumbnail do Vídeo
                      _ExerciseVideoCard(
                        imageUrl: ex.imagemUrl,
                        exerciseTitle: exerciseTitle,
                        onTap: () {},
                      ),
                      const SizedBox(height: AppTheme.space32),

                      if (ex.series.isEmpty)
                        Column(children: [
                          const SizedBox(height: 48),
                          const Icon(Icons.fitness_center_rounded, size: 50, color: AppTheme.primary),
                          const SizedBox(height: 24),
                          const Text('Prescreva o exercício', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 32),
                          OrangeGlassActionButton(label: 'Adicionar Série', onTap: _adicionarSerie, bottomMargin: 0),
                        ])
                      else ...[
                        _buildSeriesSection(title: 'Aquecimento', entries: warmup, titleColor: Color(0xFF00B4D8), showDot: true),
                        _buildSeriesSection(title: 'Séries de aproximação', entries: feeder, titleColor: Color(0xFFFFB703), showDot: true),
                        _buildSeriesSection(title: 'Séries de trabalho', entries: work, titleColor: Color(0xFFFF3366), showDot: true),
                        const SizedBox(height: 12),
                        Center(child: OrangeGlassActionButton(label: 'Adicionar Série', onTap: _adicionarSerie, bottomMargin: 0)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET DO CARD DE VÍDEO (Thumbnail) ---
class _ExerciseVideoCard extends StatelessWidget {
  final String? imageUrl;
  final String exerciseTitle;
  final VoidCallback onTap;

  const _ExerciseVideoCard({required this.imageUrl, required this.exerciseTitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(30), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  imageUrl ?? 'https://lh3.googleusercontent.com/aida-public/AB6AXuAXzEmkEB7BMnRUWQ6iIDF5Oc_gVzBjCjxHaac9LYJyL8KxdAi-mTOKK2v2nO9Vt3-DXPcDcoSM3RkTh-iDX0q8oShyD0TllFVTVsQBP3fKU0HPHHtOlkO5uRRx_yIiMes1tmlEr6VkkMyvhy-LTIzYuWYuJaLsSzeba5FPnNX9_RQjcusWmbIyWrBVLVSmLZjDaMcPJMKiSSY6S-RSZFaAzRzHQdDbWnPbv1aUP1akkwSiPE9Rriwmdn8VrF3w0ZIWei1Cxfd7B2Ut',
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, _) => Container(color: AppTheme.surfaceDark, child: const Icon(Icons.videocam_off, color: Colors.white38)),
                ),
              ),
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(64),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withAlpha(38), width: 0.9),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 26),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CargaKgInputFormatter extends TextInputFormatter {
  const _CargaKgInputFormatter();
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final d = next.text.replaceAll(RegExp(r'[^0-9]'), '');
    return d.isEmpty ? const TextEditingValue(text: '') : TextEditingValue(text: '${d}kg', selection: TextSelection.collapsed(offset: d.length));
  }
}

class _DescansoSecondsInputFormatter extends TextInputFormatter {
  const _DescansoSecondsInputFormatter();
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final d = next.text.replaceAll(RegExp(r'[^0-9]'), '');
    return d.isEmpty ? const TextEditingValue(text: '') : TextEditingValue(text: '${d}s', selection: TextSelection.collapsed(offset: d.length));
  }
}