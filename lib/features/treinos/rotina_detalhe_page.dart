import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/rotina_service.dart';
import '../../core/widgets/appfit_sliver_app_bar.dart';
import 'sessao_detalhe_personal_page.dart';
import 'models/rotina_model.dart';
import 'rotina_detalhe_controller.dart';
import 'widgets/planilha_settings_modal.dart';
import 'widgets/rotina_detalhe_header.dart';
import 'widgets/rotina_empty_state.dart';
import 'widgets/rotina_section_header.dart';
import 'widgets/rotina_sessao_card.dart';
import 'widgets/sessao_treino_modal.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/app_bar_text_button.dart';

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

  Future<Map<String, dynamic>?> _abrirConfigurarExercicios(
    SessaoTreinoModel sessao,
  ) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessaoDetalhePersonalPage(
          nomeTreino: sessao.nome,
          exercicios: sessao.exercicios,
          sessaoNote: sessao.orientacoes ?? '',
        ),
      ),
    );
  }

  /// Abre a sessão, aplica o resultado e persiste no Firebase em background.
  Future<void> _editarSessao(SessaoTreinoModel sessao) async {
    final result = await _abrirConfigurarExercicios(sessao);
    if (!mounted) return;

    if (result is Map<String, dynamic>) {
      final currentIndex = _controller.indexOfSessao(sessao);
      if (currentIndex < 0) return;
      _controller.atualizarSessao(
        currentIndex,
        result['nome'],
        sessao.diaSemana,
        result['sessaoNote'],
      );
    }

    // Persiste silenciosamente se a rotina já existe e há algo para salvar.
    if (_controller.rotinaId != null && _controller.verificarAlteracoes()) {
      _controller.salvarRotina();
    }
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
      await _editarSessao(_controller.treinos[newIndex]);
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

  void _removerSessaoComUndo(SessaoTreinoModel sessao) {
    final removed = _controller.removerSessaoPorReferencia(sessao);
    if (removed == null) return;

    _scaffoldMessengerKey.currentState?.removeCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('${removed.sessao.nome} removido'),
        action: SnackBarAction(
          label: 'DESFAZER',
          textColor: AppColors.primary,
          onPressed: () =>
              _controller.inserirSessao(removed.index, removed.sessao),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _renomearSessao(SessaoTreinoModel sessao) async {
    final currentIndex = _controller.indexOfSessao(sessao);
    if (currentIndex < 0) return;

    var nomeDigitado = sessao.nome;
    var mostrarErroNome = false;

    final novoNome = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final nomeValido = nomeDigitado.trim().isNotEmpty;

          return AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text(
              'Renomear sessão',
              style: TextStyle(color: Colors.white),
            ),
            content: TextFormField(
              initialValue: sessao.nome,
              autofocus: true,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nome da sessão',
                labelStyle: const TextStyle(color: Colors.white70),
                errorText: mostrarErroNome && !nomeValido
                    ? 'Informe um nome para a sessão'
                    : null,
              ),
              onChanged: (value) {
                nomeDigitado = value;
                if (mostrarErroNome) {
                  setDialogState(() => mostrarErroNome = false);
                }
              },
              onFieldSubmitted: (value) {
                if (value.trim().isEmpty) {
                  setDialogState(() => mostrarErroNome = true);
                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  'CANCELAR',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (!nomeValido) {
                    setDialogState(() => mostrarErroNome = true);
                    return;
                  }

                  Navigator.of(dialogContext).pop(nomeDigitado);
                },
                child: const Text(
                  'SALVAR',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (!mounted || novoNome == null) return;

    final nomeAjustado = novoNome.trim();
    if (nomeAjustado.isEmpty || nomeAjustado == sessao.nome) return;

    _controller.atualizarSessao(
      currentIndex,
      nomeAjustado,
      sessao.diaSemana,
      sessao.orientacoes ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
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
                    title: _controller.nomeRotinaExibicao,
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
                        child: RotinaDetalheHeader(
                          title: _controller.nomeRotinaExibicao,
                          subtitle: _controller.objetivoExibicao,
                          vencimentoLabel: _controller.vencimentoLabel,
                          onEdit: () => _exibirModalInfo(context),
                        ),
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
                        child: RotinaSectionHeader(
                          isReordering: _isReordering,
                          canReorder: _controller.canReorderSessoes,
                          onToggleReordering: () {
                            setState(() => _isReordering = !_isReordering);
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: SpacingTokens.labelToField),
                    ),
                    if (_controller.treinos.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: RotinaEmptyState(
                          onCreateSession: () => _exibirModalSessao(),
                        ),
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
                          itemBuilder: (context, index) {
                            final sessao = _controller.treinos[index];

                            return Padding(
                              key: ValueKey(
                                'sessao-${identityHashCode(sessao)}',
                              ),
                              padding: const EdgeInsets.only(
                                bottom: SpacingTokens.listItemGap,
                              ),
                              child: RotinaSessaoCard(
                              sessao: sessao,
                              index: index,
                              isReordering: _isReordering,
                              onOpen: () => _editarSessao(sessao),
                              onEdit: () {
                                _renomearSessao(sessao);
                              },
                              onDelete: () => _removerSessaoComUndo(sessao),
                            ),
                            );
                          },
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
}
