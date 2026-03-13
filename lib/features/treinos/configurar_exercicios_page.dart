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

// =================================================================================
// INÍCIO: MODELO DE DADOS LOCAL
// =================================================================================
/// Wrapper para o [ExercicioItem] que garante uma [id] única e estável.
/// Essencial para o funcionamento correto do [SliverReorderableList], que exige
/// chaves (`Keys`) que não mudem quando a ordem dos itens é alterada.
class _ExercicioWrapper {
  final String id;
  final ExercicioItem item;

  _ExercicioWrapper(this.item) : id = UniqueKey().toString();
}

// =================================================================================
// FIM: MODELO DE DADOS LOCAL
// =================================================================================

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
  // =================================================================================
  // INÍCIO: GERENCIAMENTO DE ESTADO
  // =================================================================================

  /// Chave para controlar o [ScaffoldMessenger] e exibir [SnackBar]s.
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Timer para controlar a duração da [SnackBar] de "item removido".
  Timer? _snackBarTimer;

  /// Cópia local dos exercícios para permitir edição sem afetar o estado original.
  late List<_ExercicioWrapper> _exerciciosLocais;

  /// Flag para rastrear se houve alguma alteração que precise ser salva.
  bool _hasChanges = false;

  /// Controlador para o campo de texto do nome do treino.
  late TextEditingController _nomeTreinoController;

  /// Controla o estado de edição do título do treino.
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

  // =================================================================================
  // FIM: GERENCIAMENTO DE ESTADO
  // =================================================================================

  // =================================================================================
  // INÍCIO: LÓGICA DE UI E NAVEGAÇÃO
  // =================================================================================

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

  /// Calcula o número total de séries em todos os exercícios.
  int get _totalSeries => _exerciciosLocais.fold(
    0,
    (sum, wrapper) => sum + wrapper.item.series.length,
  );

  /// Armazena os IDs dos exercícios recém-adicionados para acionar a animação de "hint".
  final Set<String> _newExercicios = {};

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _exerciciosLocais.removeAt(oldIndex);
      _exerciciosLocais.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  /// Abre a biblioteca de exercícios e adiciona o item selecionado à lista local.
  Future<void> _openLibrary() async {
    final exercicioSelecionado = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => const ExerciciosLibraryPage()),
    );

    if (exercicioSelecionado != null) {
      setState(() {
        final newWrapper = _ExercicioWrapper(
          ExercicioItem(
            nome: exercicioSelecionado['nome']!,
            grupoMuscular: exercicioSelecionado['musculo']!,
            series: [],
          ),
        );
        _exerciciosLocais.add(newWrapper);
        _newExercicios.add(newWrapper.id);
        _hasChanges = true;
      });
    }
  }

  /// Finaliza a edição, atualiza a lista de exercícios original e retorna para a tela anterior.
  void _concluirEdicao() {
    widget.exercicios.clear();
    widget.exercicios.addAll(_exerciciosLocais.map((e) => e.item));
    Navigator.pop(context, _nomeTreinoController.text.trim());
  }

  /// Intercepta o botão de voltar para confirmar o descarte de alterações não salvas.
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

  // =================================================================================
  // FIM: LÓGICA DE UI E NAVEGAÇÃO
  // =================================================================================

  // =================================================================================
  // INÍCIO: CONSTRUÇÃO DA INTERFACE (BUILD)
  // =================================================================================

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
            // ========================================================
            // INÍCIO: APP BAR EXPANSÍVEL
            // ========================================================
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
                                maxLength: 35,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
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
                                  filled: true, // Fundo escuro
                                  fillColor: Colors.black.withAlpha(60),
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
                                      color: AppTheme.primary.withAlpha(120),
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
                                    fontSize: 45,
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
                          ),
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

            // ========================================================
            // FIM: APP BAR EXPANSÍVEL
            // ========================================================
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
                      // ==================================================
                      // INÍCIO: BLOCOS DE MÉTRICAS
                      // ==================================================
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
                                    color: Colors.black.withAlpha(60),
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
                                      fontSize: 30,
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
                                  color: Colors.white.withAlpha(13),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(60),
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
                                      fontSize: 30,
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

                      // ==================================================
                      // FIM: BLOCOS DE MÉTRICAS
                      // ==================================================

                      // ==================================================
                      // INÍCIO: SEÇÃO DE NOTAS E CABEÇALHO DA LISTA
                      // ==================================================
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
                  ), // Fim Column
                ), // Fim Padding
              ), // Fim SliverToBoxAdapter
            ), // Fim SliverOpacity
            // ==================================================
            // FIM: SEÇÃO DE NOTAS E CABEÇALHO DA LISTA
            // ==================================================

            // ========================================================
            // INÍCIO: ESTADO VAZIO (EMPTY STATE)
            // ========================================================
            if (_exerciciosLocais.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
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
                      Text(
                        'Toque no botão abaixo para começar a\n'
                        'montar o seu treino.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const Spacer(flex: 2),
                      IgnorePointer(
                        ignoring: !shouldShowFab,
                        child: AnimatedScale(
                          scale: shouldShowFab ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          child: OrangeGlassActionButton(
                            label: 'Adicionar Exercício',
                            onTap: _openLibrary,
                            bottomMargin: 0,
                          ),
                        ),
                      ),
                      const Spacer(flex: 3),
                    ],
                  ),
                ),
              ),

            // ========================================================
            // FIM: ESTADO VAZIO (EMPTY STATE)
            // ========================================================
            if (_exerciciosLocais.isNotEmpty)
              // ========================================================
              // INÍCIO: LISTA REORDENÁVEL DE EXERCÍCIOS
              // ========================================================
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
                    // Decorador para o item enquanto está sendo arrastado.
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
                    itemBuilder: (context, index) {
                      final wrapper = _exerciciosLocais[index];
                      final isNew = _newExercicios.contains(wrapper.id);

                      // Se o exercício é novo, aplica a animação de "hint".
                      // Caso contrário, constrói o card normalmente.
                      Widget card;
                      if (isNew) {
                        card = _HintingExercicioAnimator(
                          onEnd: () {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _newExercicios.remove(wrapper.id);
                                });
                              }
                            });
                          },
                          builder: (context, color) {
                            return _buildCardContent(index, flashColor: color);
                          },
                        );
                      } else {
                        card = _buildCardContent(index);
                      }

                      // ============================================
                      // INÍCIO: GESTO DE SWIPE-TO-DELETE (DISMISSIBLE)
                      // ============================================
                      return Dismissible(
                        key: Key(wrapper.id),
                        direction: DismissDirection.endToStart,
                        background: Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.space12,
                          ),
                          child: Container(
                            padding: const EdgeInsets.only(right: 24),
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLarge,
                              ),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        onDismissed: (direction) {
                          final removedItem = _exerciciosLocais[index];
                          final removedIndex = index;

                          setState(() {
                            _exerciciosLocais.removeAt(index);
                            _hasChanges = true;
                          });

                          // Lógica da SnackBar com ação "Desfazer".
                          // Garante que apenas uma SnackBar de "desfazer" esteja visível.
                          _snackBarTimer?.cancel();
                          _scaffoldMessengerKey.currentState
                              ?.removeCurrentSnackBar();

                          final snackBar = SnackBar(
                            content: Text('${removedItem.item.nome} removido'),
                            action: SnackBarAction(
                              label: 'DESFAZER',
                              textColor: AppTheme.primary,
                              onPressed: () {
                                _snackBarTimer?.cancel();
                                _scaffoldMessengerKey.currentState
                                    ?.hideCurrentSnackBar();
                                if (!mounted) return;
                                setState(() {
                                  _exerciciosLocais.insert(
                                    removedIndex,
                                    removedItem,
                                  );
                                });
                              },
                            ),
                            duration: const Duration(days: 365),
                            behavior: SnackBarBehavior.floating,
                          );

                          final controller = _scaffoldMessengerKey.currentState
                              ?.showSnackBar(snackBar);

                          if (controller != null) {
                            _snackBarTimer = Timer(
                              const Duration(seconds: 4),
                              () {
                                controller.close();
                              },
                            );
                          }
                        },
                        child: card,
                      );
                    },
                  ), // Fim SliverReorderableList
                ), // Fim SliverPadding
              ), // Fim SliverOpacity
            // ========================================================
            // FIM: LISTA REORDENÁVEL DE EXERCÍCIOS
            // ========================================================
            if (_exerciciosLocais.isNotEmpty)
              // ========================================================
              // INÍCIO: BOTÃO DE AÇÃO FLUTUANTE (FAB)
              // ========================================================
              SliverToBoxAdapter(
                child: Center(
                  child: IgnorePointer(
                    ignoring: !shouldShowFab,
                    child: AnimatedScale(
                      scale: shouldShowFab ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24.0, bottom: 96.0),
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
            // ========================================================
            // FIM: BOTÃO DE AÇÃO FLUTUANTE (FAB)
            // ========================================================
          ],
        ),
      ),
    );
  }

  // =================================================================================
  // FIM: CONSTRUÇÃO DA INTERFACE (BUILD)
  // =================================================================================

  // =================================================================================
  // INÍCIO: WIDGETS AUXILIARES (BUILD HELPERS)
  // =================================================================================

  /// Constrói o conteúdo visual de um card de exercício na lista.
  Widget _buildCardContent(int exIndex, {Color? flashColor}) {
    final wrapper = _exerciciosLocais[exIndex];
    final ex = wrapper.item;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Material(
        elevation: 1.0,
        color: flashColor ?? AppTheme.surfaceDark,
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
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.1,
                          ),
                          children: [
                            if (ex.grupoMuscular.isNotEmpty)
                              TextSpan(
                                text: '${ex.grupoMuscular} • ',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            TextSpan(
                              text:
                                  '${ex.series.length} ${ex.series.length == 1 ? 'Série' : 'Séries'}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
    );
  }
}

// =================================================================================
// FIM: WIDGETS AUXILIARES (BUILD HELPERS)
// =================================================================================

// =================================================================================
// INÍCIO: WIDGET DE ANIMAÇÃO
// =================================================================================
/// Widget que orquestra uma sequência de animações para novos exercícios:
/// 1. Flash de cor para destacar o novo item.
/// 2. Pausa.
/// 3. Animação de "swipe hint" para ensinar o gesto de exclusão.
class _HintingExercicioAnimator extends StatefulWidget {
  final Widget Function(BuildContext context, Color? color) builder;
  final VoidCallback onEnd;

  const _HintingExercicioAnimator({required this.builder, required this.onEnd});

  @override
  _HintingExercicioAnimatorState createState() =>
      _HintingExercicioAnimatorState();
}

class _HintingExercicioAnimatorState extends State<_HintingExercicioAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _swipeHintAnimation;
  late Animation<double> _swipeHintBgAnimation;

  /// Define a animação de movimento do card para a esquerda e de volta.
  static final _swipeHintTween = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: -72.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 35,
    ),
    TweenSequenceItem(tween: ConstantTween<double>(-72.0), weight: 15),
    TweenSequenceItem(
      tween: Tween(
        begin: -72.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 50,
    ),
  ]);

  /// Define a animação de largura do fundo vermelho que é revelado.
  static final _swipeHintBgTween = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 72.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 35,
    ),
    TweenSequenceItem(tween: ConstantTween<double>(72.0), weight: 15),
    TweenSequenceItem(
      tween: Tween(
        begin: 72.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 50,
    ),
  ]);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    );

    final highlightColor = AppTheme.primary.withValues(alpha: 0.12);
    // Sequência 1: Animação de flash (0ms a 1200ms)
    _colorAnimation =
        TweenSequence<Color?>([
          TweenSequenceItem(
            tween: ColorTween(begin: AppTheme.surfaceDark, end: highlightColor),
            weight: 50.0,
          ),
          TweenSequenceItem(
            tween: ColorTween(begin: highlightColor, end: AppTheme.surfaceDark),
            weight: 50.0,
          ),
          TweenSequenceItem(
            tween: ColorTween(begin: highlightColor, end: AppTheme.surfaceDark),
            weight: 50.0,
          ),
          TweenSequenceItem(
            tween: ColorTween(begin: highlightColor, end: AppTheme.surfaceDark),
            weight: 50.0,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 1200 / 2600, curve: Curves.easeOut),
          ),
        );

    // Sequência 2: Animação de swipe (após uma pausa, de 1600ms a 2600ms)
    final swipeInterval = CurvedAnimation(
      parent: _controller,
      curve: const Interval(800 / 1600, 1.0, curve: Curves.linear),
    );
    _swipeHintAnimation = _swipeHintTween.animate(swipeInterval);
    _swipeHintBgAnimation = _swipeHintBgTween.animate(swipeInterval);

    _controller.forward().whenComplete(() {
      if (mounted) {
        widget.onEnd();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final dx = _swipeHintAnimation.value;
        final bgWidth = _swipeHintBgAnimation.value;

        return Stack(
          children: [
            // O fundo vermelho é "posicionado" para não influenciar o tamanho do Stack.
            // Ele simplesmente preenche o espaço definido pelo card principal.
            if (bgWidth > 0)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.space12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      child: Container(
                        width: bgWidth,
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: Opacity(
                          opacity: (bgWidth / 72.0).clamp(0.0, 1.0),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // O card principal (não posicionado) define o tamanho do Stack.
            Transform.translate(
              offset: Offset(dx, 0),
              child: widget.builder(context, _colorAnimation.value),
            ),
          ],
        );
      },
    );
  }
}

// =================================================================================
// FIM: WIDGET DE ANIMAÇÃO
// =================================================================================
