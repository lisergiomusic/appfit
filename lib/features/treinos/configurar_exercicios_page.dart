import 'package:appfit/core/widgets/appfit_sliver_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/orange_glass_action_button.dart';
import '../../core/widgets/sliver_safe_title.dart';
import 'exercicios_library_page.dart';
import 'exercicio_detalhe_page.dart';
import 'models/exercicio_model.dart';
import 'package:appfit/features/treinos/_note_section.dart';

class ConfigurarExerciciosPage extends StatefulWidget {
  final String nomeTreino;
  final List<ExercicioItem> exercicios;

  const ConfigurarExerciciosPage({
    super.key,
    required this.nomeTreino,
    required this.exercicios,
  });

  @override
  State<ConfigurarExerciciosPage> createState() =>
      _ConfigurarExerciciosPageState();
}

class _ConfigurarExerciciosPageState extends State<ConfigurarExerciciosPage> {
  late List<ExercicioItem> _exerciciosLocais;
  bool _hasChanges = false;
  late TextEditingController _nomeTreinoController;
  bool _isEditingTitle = false;
  late FocusNode _titleFocusNode;



  @override
  void initState() {
    super.initState();
    _exerciciosLocais = widget.exercicios.isNotEmpty
        ? widget.exercicios.map((ex) {
            return ExercicioItem(
              nome: ex.nome,
              grupoMuscular: ex.grupoMuscular,
              observacao: ex.observacao,
              tipoAlvo: ex.tipoAlvo,
              imagemUrl: ex.imagemUrl,
              series: ex.series
                  .map(
                    (s) => SerieItem(
                      tipo: s.tipo,
                      alvo: s.alvo,
                      carga: s.carga,
                      descanso: s.descanso,
                    ),
                  )
                  .toList(),
            );
          }).toList()
        : [];
    _nomeTreinoController = TextEditingController(text: widget.nomeTreino);
    _titleFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _nomeTreinoController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _toggleEditTitle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEditingTitle = !_isEditingTitle;
      if (_isEditingTitle) {
        _titleFocusNode.requestFocus();
      } else {
        _titleFocusNode.unfocus();
        if (_nomeTreinoController.text.trim() != widget.nomeTreino) {
          _hasChanges = true;
        }
      }
    });
  }

  int get _totalSeries =>
      _exerciciosLocais.fold(0, (sum, ex) => sum + ex.series.length);

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _exerciciosLocais.removeAt(oldIndex);
      _exerciciosLocais.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  Future<void> _openLibrary() async {
    final String? nome = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ExerciciosLibraryPage()),
    );

    if (nome != null && nome.isNotEmpty) {
      setState(() {
        _exerciciosLocais.add(ExercicioItem(nome: nome, series: []));
        _hasChanges = true;
      });
    }
  }

  void _concluirEdicao() {
    widget.exercicios.clear();
    widget.exercicios.addAll(_exerciciosLocais);
    Navigator.pop(context, _nomeTreinoController.text.trim());
  }

  Future<void> _onBackPressed() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }
    final sair = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Descartar alterações?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'As modificações nesta sessão não foram salvas.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.primary, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Descartar',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (sair == true) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final safeTreinoTitle = SliverSafeTitle.safeTitle(
      _nomeTreinoController.text.isEmpty
          ? widget.nomeTreino
          : _nomeTreinoController.text,
      fallback: 'Treino',
    );
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final shouldShowFab = !_isEditingTitle && !isKeyboardVisible;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          AppFitSliverAppBar(
            title: safeTreinoTitle,
            expandedHeight: 140,
            onBackPressed: _onBackPressed,
            leading: _isEditingTitle ? const SizedBox.shrink() : null,
            actions: [
              if (!_isEditingTitle)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: TextButton(
                    onPressed: _concluirEdicao,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(44, 44),
                      tapTargetSize: MaterialTapTargetSize.padded,
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
                ),
            ],
            background: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 16, right: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _isEditingTitle
                          ? TextField(
                              controller: _nomeTreinoController,
                              focusNode: _titleFocusNode,
                              maxLines: 1,
                              minLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 40,
                                letterSpacing: -0.5,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              cursorColor: AppTheme.primary,
                              textCapitalization: TextCapitalization.words,
                              onSubmitted: (_) => _toggleEditTitle(),
                            )
                          : GestureDetector(
                              onTap: _toggleEditTitle,
                              child: Text(
                                safeTreinoTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 40,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _toggleEditTitle,
                      child: Icon(
                        _isEditingTitle
                            ? Icons.check_circle_outline_rounded
                            : Icons.edit_note,
                        color: _isEditingTitle
                            ? AppTheme.primary
                            : Colors.white.withAlpha(80),
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverOpacity(
            opacity: _isEditingTitle ? 0.3 : 1.0,
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.paddingScreen,
                  AppTheme.space24,
                  AppTheme.paddingScreen,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const NoteSection(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_exerciciosLocais.length} ${_exerciciosLocais.length == 1 ? 'EXERCÍCIO' : 'EXERCÍCIOS'}',
                          style: AppTheme.textSectionHeaderDark,
                        ),
                        Text(
                          '${_totalSeries} ${_totalSeries == 1 ? 'SÉRIE' : 'SÉRIES'}',
                          style: AppTheme.textSectionHeaderDark.copyWith(
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_exerciciosLocais.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.fitness_center_outlined,
                          size: 40,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Nenhum exercício adicionado',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Comece a montar o treino adicionando\no primeiro exercício abaixo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          if (_exerciciosLocais.isNotEmpty)
            SliverOpacity(
              opacity: _isEditingTitle ? 0.3 : 1.0,
              sliver: SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingScreen,
                  vertical: AppTheme.space16,
                ),
                sliver: SliverReorderableList(
                  itemCount: _exerciciosLocais.length,
                  onReorder: _onReorder,
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      elevation: 0,
                      color: Colors.transparent,
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) => _buildExercicioCard(index),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Center(
              child: IgnorePointer(
                ignoring: !shouldShowFab,
                child: AnimatedScale(
                  scale: shouldShowFab ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24.0, bottom: 48.0),
                    child: OrangeGlassActionButton(
                      label: 'Adicionar Exercício',
                      onTap: _openLibrary,
                      bottomMargin: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercicioCard(int exIndex) {
    final ex = _exerciciosLocais[exIndex];
    return Dismissible(
      key: ValueKey('${ex.nome}_$exIndex'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.space12),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.redAccent.withAlpha(200),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppTheme.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                title: const Text(
                  'Remover exercício?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: const Text(
                  'Tem certeza que deseja excluir este exercício da rotina?',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppTheme.primary, fontSize: 16),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Remover',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        setState(() {
          _exerciciosLocais.removeAt(exIndex);
          _hasChanges = true;
        });
      },
      child: Container(
        key: ValueKey(ex.nome),
        margin: const EdgeInsets.only(bottom: AppTheme.space12),
        child: Material(
          color: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExercicioDetalhePage(
                    exercicio: ex,
                    onChanged: () => setState(() => _hasChanges = true),
                  ),
                ),
              );
              setState(() {});
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingCard,
                vertical: AppTheme.space14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Drag handle
                  ReorderableDragStartListener(
                    index: exIndex,
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppTheme.space8),
                      child: Icon(
                        Icons.drag_indicator,
                        color: Colors.white.withAlpha(80),
                        size: 24,
                      ),
                    ),
                  ),
                  // Main content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ex.nome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTheme.space6),
                        Text(
                          '${ex.series.length} ${ex.series.length == 1 ? 'Série' : 'Séries'}',
                          style: const TextStyle(
                            color: Color(0xFF94a3b8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Seta
                  const SizedBox(width: AppTheme.space12),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF64748b),
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
