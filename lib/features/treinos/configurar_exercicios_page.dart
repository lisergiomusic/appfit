import 'dart:async';

import 'package:appfit/core/widgets/appfit_sliver_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/orange_glass_action_button.dart';
import '../../core/widgets/sliver_safe_title.dart';
import 'exercicios_library_page.dart';
import 'exercicio_detalhe_page.dart';
import 'models/exercicio_model.dart';
import 'widgets/sessao_note_widget.dart';

/// Wrapper local para garantir que cada item da lista tenha uma Key única e estável.
/// Isso resolve o problema de reordenação onde o índice era usado como chave.
class _ExercicioWrapper {
  final String id;
  final ExercicioItem item;

  _ExercicioWrapper(this.item) : id = UniqueKey().toString();
}

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
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  Timer? _snackBarTimer;
  late List<_ExercicioWrapper> _exerciciosLocais;
  bool _hasChanges = false;
  late TextEditingController _nomeTreinoController;
  bool _isEditingTitle = false;
  late FocusNode _titleFocusNode;

  @override
  void initState() {
    super.initState();
    _exerciciosLocais = widget.exercicios.isNotEmpty
        ? widget.exercicios.map((ex) {
            final item = ExercicioItem(
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
            return _ExercicioWrapper(item);
          }).toList()
        : [];
    _nomeTreinoController = TextEditingController(text: widget.nomeTreino);
    _titleFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _snackBarTimer?.cancel();
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

  int get _totalSeries => _exerciciosLocais.fold(
    0,
    (sum, wrapper) => sum + wrapper.item.series.length,
  );

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _exerciciosLocais.removeAt(oldIndex);
      _exerciciosLocais.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  Future<void> _openLibrary() async {
    final exercicioSelecionado = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => const ExerciciosLibraryPage()),
    );

    if (exercicioSelecionado != null) {
      setState(() {
        _exerciciosLocais.add(
          _ExercicioWrapper(
            ExercicioItem(
              nome: exercicioSelecionado['nome']!,
              grupoMuscular: exercicioSelecionado['musculo']!,
              series: [],
            ),
          ),
        );
        _hasChanges = true;
      });
    }
  }

  void _concluirEdicao() {
    widget.exercicios.clear();
    widget.exercicios.addAll(_exerciciosLocais.map((e) => e.item));
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

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            AppFitSliverAppBar(
              title: safeTreinoTitle,
              expandedHeight: _isEditingTitle ? 160 : 140,
              onBackPressed: _onBackPressed,
              leading: _isEditingTitle ? const SizedBox.shrink() : null,
              actions: [
                if (!_isEditingTitle)
                  TextButton(
                    onPressed: _concluirEdicao,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    ),
                    child: const Text('Salvar'),
                  ),
              ],
              background: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    bottom: 16,
                    right: 24,
                  ),
                  child: Row(
                    // Alinha ao topo quando edita para o ícone não "cair" com o contador
                    crossAxisAlignment: _isEditingTitle
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _isEditingTitle
                            ? TextField(
                                controller: _nomeTreinoController,
                                focusNode: _titleFocusNode,
                                maxLines: 1,
                                maxLength:
                                    35, // <-- Limite de Caracteres Adicionado
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      32, // Fonte um pouco menor para caber na caixa
                                  letterSpacing: -0.5,
                                ),
                                buildCounter:
                                    (
                                      context, {
                                      required currentLength,
                                      required isFocused,
                                      maxLength,
                                    }) {
                                      final isLimit =
                                          currentLength == maxLength;
                                      return Text(
                                        '$currentLength / $maxLength',
                                        style: TextStyle(
                                          color: isLimit
                                              ? Colors.redAccent
                                              : AppTheme.textSecondary,
                                          fontSize: 12,
                                          fontWeight: isLimit
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                      );
                                    },
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.black.withAlpha(
                                    60,
                                  ), // Fundo escuro
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: AppTheme.primary.withAlpha(
                                        120,
                                      ), // Borda neon sutil
                                      width: 1.5,
                                    ),
                                  ),
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
                                    fontSize: 48,
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
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: _isEditingTitle ? 8.0 : 0.0,
                          ), // Ajuste visual do ícone
                          child: Icon(
                            _isEditingTitle
                                ? Icons.check_circle_rounded
                                : Icons.edit_note,
                            color: _isEditingTitle
                                ? AppTheme.primary
                                : Colors.white.withAlpha(80),
                            size: 44,
                          ),
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
                    AppTheme.space8,
                    AppTheme.paddingScreen,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ========================================================
                      // INÍCIO DOS BLOCOS DE MÉTRICAS
                      // ========================================================
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withAlpha(13),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(
                                      60,
                                    ), // shadow-xl
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Exercícios',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_exerciciosLocais.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30, // text-3xl
                                      fontWeight: FontWeight.bold,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withAlpha(
                                    13,
                                  ), // border-white/5
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(
                                      60,
                                    ), // shadow-xl
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total de Séries',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$_totalSeries',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30, // text-3xl
                                      fontWeight: FontWeight.bold,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ========================================================
                      // FIM DOS BLOCOS DE MÉTRICAS
                      // ========================================================
                      const SessaoNoteWidget(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'LISTA DE EXERCÍCIOS',
                            style: AppTheme.textSectionHeaderDark,
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
                      final curvedAnimation = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      );

                      return ScaleTransition(
                        scale: Tween<double>(
                          begin: 1.0,
                          end: 1.02,
                        ).animate(curvedAnimation),
                        child: Material(
                          elevation: 6.0,
                          color: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLarge,
                            ),
                          ),
                          child: child,
                        ),
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
      ),
    );
  }

  Widget _buildExercicioCard(int exIndex) {
    final wrapper = _exerciciosLocais[exIndex];
    final ex = wrapper.item;

    return Dismissible(
      key: Key(wrapper.id), // Agora usamos um ID estável gerado na criação
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      // Removemos confirmDismiss para agilizar o fluxo (UX padrão Gmail)
      onDismissed: (direction) {
        // Guarda referência para Undo
        final removedItem = wrapper;
        final removedIndex = exIndex;

        setState(() {
          _exerciciosLocais.removeAt(exIndex);
          _hasChanges = true;
        });

        // Cancela o timer anterior e remove a SnackBar atual
        _snackBarTimer?.cancel();
        _scaffoldMessengerKey.currentState?.removeCurrentSnackBar();

        // Cria a SnackBar com uma duração muito longa, pois vamos controlá-la manualmente
        final snackBar = SnackBar(
          content: Text('${ex.nome} removido'),
          action: SnackBarAction(
            label: 'DESFAZER',
            textColor: AppTheme.primary,
            onPressed: () {
              // Ao clicar em desfazer, cancela o timer, esconde a snackbar e reinsere o item
              _snackBarTimer?.cancel();
              _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
              if (!mounted) return;
              setState(() {
                _exerciciosLocais.insert(removedIndex, removedItem);
              });
            },
          ),
          duration: const Duration(days: 365), // Duração efetivamente infinita
          behavior: SnackBarBehavior.floating,
        );

        // Mostra a SnackBar e guarda seu controlador
        final controller = _scaffoldMessengerKey.currentState?.showSnackBar(
          snackBar,
        );

        // Inicia um timer para fechar a SnackBar após 4 segundos
        if (controller != null) {
          _snackBarTimer = Timer(const Duration(seconds: 4), () {
            controller.close();
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.space12),
        child: Material(
          elevation: 1.0,
          color: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            side: BorderSide(color: Colors.white.withAlpha(14), width: 1),
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
                      padding: const EdgeInsets.all(12.0),
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
                            fontSize: 18,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTheme.space6),
                        Text(
                          '${ex.grupoMuscular.isNotEmpty ? '${ex.grupoMuscular} • ' : ''}${ex.series.length} ${ex.series.length == 1 ? 'Série' : 'Séries'}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
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
