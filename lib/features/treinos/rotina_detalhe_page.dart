import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/rotina_service.dart';
import '../../core/widgets/appfit_sliver_app_bar.dart';
import 'configurar_exercicios_page.dart';
import 'models/rotina_model.dart';
import 'rotina_detalhe_controller.dart';
import 'widgets/planilha_settings_modal.dart';
import 'widgets/sessao_treino_modal.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/app_bar_text_button.dart';
import '../../core/widgets/app_section_link_button.dart';
import '../../core/widgets/app_swipe_to_delete.dart';

class RotinaDetalhePage extends StatefulWidget {
  final Map<String, dynamic>? rotinaData;
  final String? rotinaId;
  final String? alunoId;
  final String? alunoNome;
  final RotinaService? rotinaService;

  const RotinaDetalhePage({
    super.key,
    this.rotinaData,
    this.rotinaId,
    this.alunoId,
    this.alunoNome,
    this.rotinaService,
  });

  @override
  State<RotinaDetalhePage> createState() => _RotinaDetalhePageState();
}

class _RotinaDetalhePageState extends State<RotinaDetalhePage> {
  late RotinaDetalheController _controller;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _canPopNow = false;
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    _controller = RotinaDetalheController(
      rotinaId: widget.rotinaId,
      alunoId: widget.alunoId,
      rotinaService: widget.rotinaService,
      initialData: widget.rotinaData,
    );

    if (widget.rotinaData == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _exibirModalInfo(context);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _showDescartarDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text(
              'Descartar alterações?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Os dados preenchidos não são válidos para salvar e serão perdidos.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'CONTINUAR EDITANDO',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'DESCARTAR',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _exibirModalInfo(BuildContext context) async {
    final bool isInitialSetup =
        widget.rotinaId == null && _controller.nomeCtrl.text.isEmpty;

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (pageContext) => PlanilhaSettingsModal(
          rotinaId: widget.rotinaId,
          nomeInicial: _controller.nomeCtrl.text,
          objetivoInicial: _controller.objCtrl.text,
          tipoVencimento: _controller.tipoVencimento,
          vencimentoSessoes: _controller.vencimentoSessoes,
          vencimentoData: _controller.vencimentoData,
          hasTreinos: _controller.treinos.isNotEmpty,
          onSave: (nome, obj, tipo, sessoes, data) {
            _controller.atualizarConfiguracoes(
              nome: nome,
              objetivo: obj,
              tipo: tipo,
              sessoes: sessoes,
              data: data,
            );
          },
          onDelete: _confirmarExclusao,
          showDescartarDialog: _showDescartarDialog,
        ),
      ),
    );

    if (isInitialSetup &&
        context.mounted &&
        _controller.nomeCtrl.text.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  void _exibirModalSessao({int? index}) async {
    final countBefore = index == null ? _controller.treinos.length : -1;

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (pageContext) => SessaoTreinoModal(
          sessao: index != null ? _controller.treinos[index] : null,
          onSave: (nome, dia, notas) {
            if (index != null) {
              _controller.atualizarSessao(index, nome, dia, notas);
            } else {
              _controller.adicionarSessao(nome, dia, notas);
            }
          },
        ),
      ),
    );

    // Navega automaticamente para a sessão recém-criada
    if (index == null && mounted && _controller.treinos.length > countBefore) {
      final newIndex = _controller.treinos.length - 1;
      final sessao = _controller.treinos[newIndex];
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfigurarExerciciosPage(
            nomeTreino: sessao.nome,
            exercicios: sessao.exercicios,
            sessaoNote: sessao.orientacoes ?? '',
          ),
        ),
      );
      if (mounted && result is Map<String, dynamic>) {
        _controller.atualizarSessao(
          newIndex,
          result['nome'],
          sessao.diaSemana,
          result['sessaoNote'],
        );
      }
    }
  }

  void _confirmarExclusao() {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Remover Planilha?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta ação não pode ser desfeita e todos os dados desta planilha serão perdidos.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              final sucesso = await _controller.excluirRotina();
              if (sucesso && mounted) {
                setState(() => _canPopNow = true);
                navigator.pop(); // Fecha dialog
                navigator.pop(); // Fecha modal
                navigator.pop(); // Volta para a tela anterior
              }
            },
            child: const Text(
              'REMOVER',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePop(bool didPop) async {
    if (didPop) return;
    if (_controller.isSaving) return;

    if (!_controller.verificarAlteracoes()) {
      setState(() => _canPopNow = true);
      Navigator.of(context).pop();
      return;
    }

    final salvo = await _controller.salvarRotina();
    if (salvo && mounted) {
      setState(() => _canPopNow = true);
      Navigator.of(context).pop();
    } else if (mounted) {
      final descartar = await _showDescartarDialog();
      if (descartar && mounted) {
        setState(() => _canPopNow = true);
        Navigator.of(context).pop();
      }
    }
  }

  int _indexOfSessao(SessaoTreinoModel sessao) {
    return _controller.treinos.indexWhere((item) => identical(item, sessao));
  }

  void _removerSessaoComUndo(SessaoTreinoModel sessao) {
    final removedIndex = _indexOfSessao(sessao);
    if (removedIndex < 0) return;

    final removed = _controller.removerSessaoComRetorno(removedIndex);
    if (removed == null) return;

    _scaffoldMessengerKey.currentState?.removeCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('${removed.nome} removido'),
        action: SnackBarAction(
          label: 'DESFAZER',
          textColor: AppColors.primary,
          onPressed: () => _controller.inserirSessao(removedIndex, removed),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final routineName = _controller.nomeCtrl.text.isEmpty
            ? 'Nova Rotina'
            : _controller.nomeCtrl.text;

        return PopScope(
          canPop: _canPopNow,
          onPopInvokedWithResult: (didPop, result) => _handlePop(didPop),
          child: ScaffoldMessenger(
            key: _scaffoldMessengerKey,
            child: Scaffold(
              backgroundColor: AppColors.background,
              body: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  AppFitSliverAppBar(
                    title: routineName,
                    expandedHeight: 140,
                    onBackPressed: () => Navigator.of(context).maybePop(),
                    actions: [
                      AppBarTextButton(
                        label: 'Salvar',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                    background: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: SpacingTokens.screenHorizontalPadding,
                          right: SpacingTokens.screenHorizontalPadding,
                          bottom: 0,
                        ),
                        child: _buildHeader(),
                      ),
                    ),
                  ),
                  if (_controller.isDeleting || _controller.isSaving)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.paddingScreen,
                          SpacingTokens.sectionGap,
                          AppTheme.paddingScreen,
                          0,
                        ),
                        child: _buildSectionHeader(),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: SpacingTokens.labelToField),
                    ),
                    if (_controller.treinos.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    else ...[
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.paddingScreen,
                        ),
                        sliver: SliverReorderableList(
                          itemCount: _controller.treinos.length,
                          onReorder: _controller.onReorderSessoes,
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
                                elevation: 2.0,
                                shadowColor: Colors.black.withAlpha(60),
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
                          itemBuilder: (context, index) => _buildSessaoCard(
                            _controller.treinos[index],
                            index,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.paddingScreen,
                            SpacingTokens.sectionGap,
                            AppTheme.paddingScreen,
                            SpacingTokens.screenBottomPadding,
                          ),
                          child: AppPrimaryButton(
                            label: 'Nova sessão',
                            icon: CupertinoIcons.add_circled,
                            onPressed: () => _exibirModalSessao(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _controller.nomeCtrl.text.isEmpty
                    ? 'Nova Rotina'
                    : _controller.nomeCtrl.text,
                style: AppTheme.bigTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: SpacingTokens.titleToSubtitle),
              Text(
                _controller.objCtrl.text.isEmpty
                    ? 'Defina o objetivo'
                    : _controller.objCtrl.text,
                style: CardTokens.cardSubtitle,
              ),
              const SizedBox(height: SpacingTokens.titleToSubtitle),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 11,
                    color: AppColors.labelSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(_buildVencimentoLabel(), style: AppTheme.caption),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _exibirModalInfo(context),
          style: IconButton.styleFrom(backgroundColor: AppColors.buttonSurface),
          icon: const Icon(
            CupertinoIcons.pencil,
            color: AppColors.labelPrimary,
          ),
        ),
      ],
    );
  }

  String _buildVencimentoLabel() {
    if (_controller.tipoVencimento == 'sessoes') {
      final sessoes = _controller.vencimentoSessoes;
      if (sessoes <= 0) {
        return 'Sem vencimento';
      }
      return '$sessoes ${sessoes == 1 ? 'sessão' : 'sessões'}';
    }

    return 'Vence em ${DateFormat('dd/MM/yyyy').format(_controller.vencimentoData)}';
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const SizedBox(width: 4),
        Text('Lista de treinos', style: AppTheme.sectionHeader),
        const Spacer(),
        AppSectionLinkButton(
          label: _isReordering ? 'Concluir' : 'Reorganizar',
          onPressed: _controller.treinos.length < 2
              ? null
              : () => setState(() => _isReordering = !_isReordering),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.paddingScreen,
        0,
        AppTheme.paddingScreen,
        SpacingTokens.screenBottomPadding,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.square_list,
              size: 48,
              color: AppColors.primary.withAlpha(150),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sua planilha está vazia',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione as sessões de treino (ex: Treino A, Treino B)\npara começar a configurar os exercícios.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.labelSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          AppPrimaryButton(
            label: 'Criar sessão',
            icon: CupertinoIcons.add_circled,
            onPressed: () => _exibirModalSessao(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessaoCard(SessaoTreinoModel sessao, int index) {
    final sessaoIndex = _indexOfSessao(sessao);

    return Padding(
      key: ValueKey('sessao-${identityHashCode(sessao)}'),
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: _isReordering
            ? _buildSessaoCardContent(sessao, index, sessaoIndex)
            : AppSwipeToDelete(
                dismissibleKey: ValueKey(
                  'dismiss-sessao-${identityHashCode(sessao)}',
                ),
                onDismissed: (_) => _removerSessaoComUndo(sessao),
                child: _buildSessaoCardContent(sessao, index, sessaoIndex),
              ),
      ),
    );
  }

  Widget _buildSessaoCardContent(
    SessaoTreinoModel sessao,
    int index,
    int sessaoIndex,
  ) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        onTap: _isReordering
            ? null
            : () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConfigurarExerciciosPage(
                      nomeTreino: sessao.nome,
                      exercicios: sessao.exercicios,
                      sessaoNote: sessao.orientacoes ?? '',
                    ),
                  ),
                );
                if (mounted && result is Map<String, dynamic>) {
                  final currentIndex = _indexOfSessao(sessao);
                  if (currentIndex < 0) return;
                  _controller.atualizarSessao(
                    currentIndex,
                    result['nome'],
                    sessao.diaSemana,
                    result['sessaoNote'],
                  );
                }
              },
        child: Padding(
          padding: CardTokens.padding,
          child: Row(
            children: [
              _buildSessaoIndex(index),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sessao.nome,
                      style: CardTokens.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: SpacingTokens.titleToSubtitle),
                    Text(
                      '${sessao.exercicios.length} ${sessao.exercicios.length == 1 ? 'exercício' : 'exercícios'}',
                      style: CardTokens.cardSubtitle,
                    ),
                  ],
                ),
              ),
              _isReordering
                  ? ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.drag_handle_rounded,
                          color: AppColors.labelSecondary,
                          size: 24,
                        ),
                      ),
                    )
                  : PopupMenuButton<String>(
                      icon: const Icon(
                        CupertinoIcons.ellipsis_vertical,
                        size: 20,
                        color: AppColors.labelTertiary,
                      ),
                      onSelected: (v) {
                        if (sessaoIndex < 0) return;
                        if (v == 'edit') {
                          _exibirModalSessao(index: sessaoIndex);
                        }
                        if (v == 'delete') _removerSessaoComUndo(sessao);
                      },
                      itemBuilder: (c) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Excluir'),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessaoIndex(int index) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(40),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      child: Center(
        child: Text(
          String.fromCharCode(65 + index),
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
