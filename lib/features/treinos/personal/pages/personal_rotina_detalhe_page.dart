import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/rotina_service.dart';
import '../../../../core/widgets/appfit_sliver_app_bar.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_bar_text_button.dart';
import '../controllers/rotina_detalhe_controller.dart';
import '../../shared/models/rotina_model.dart';
import '../../shared/widgets/planilha_settings_modal.dart';
import '../../shared/widgets/rotina_detalhe_header.dart';
import '../../shared/widgets/rotina_empty_state.dart';
import '../../shared/widgets/rotina_section_header.dart';
import '../../shared/widgets/rotina_sessao_card.dart';
import '../../shared/widgets/sessao_treino_modal.dart';
import 'personal_sessao_detalhe_page.dart';

class PersonalRotinaDetalhePage extends StatefulWidget {
  final Map<String, dynamic>? rotinaData;
  final String? rotinaId;
  final String? alunoId;
  final String? alunoNome;
  final RotinaService? rotinaService;

  const PersonalRotinaDetalhePage({
    super.key,
    this.rotinaData,
    this.rotinaId,
    this.alunoId,
    this.alunoNome,
    this.rotinaService,
  });

  @override
  State<PersonalRotinaDetalhePage> createState() =>
      _PersonalRotinaDetalhePageState();
}

class _PersonalRotinaDetalhePageState extends State<PersonalRotinaDetalhePage> {
  late RotinaDetalheController _controller;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _canPopNow = false;
  bool _isReordering = false;
  bool _isSavingOverlay = false;

  @override
  void initState() {
    super.initState();
    _controller = RotinaDetalheController(
      rotinaId: widget.rotinaId,
      alunoId: widget.alunoId,
      rotinaService: widget.rotinaService,
      initialData: widget.rotinaData,
    );

    if (widget.rotinaData == null && widget.rotinaId == null) {
      // Nova rotina sem dados: abre modal de configuração inicial.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _exibirModalInfo(context);
      });
    }
    // rotinaData já vem da stream em tempo real — não precisa buscar nada.
  }

  @override
  void didUpdateWidget(PersonalRotinaDetalhePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rotinaData != oldWidget.rotinaData && widget.rotinaData != null) {
      _controller.recarregarDados(widget.rotinaData!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _showDescartarDialog({bool erroDeRede = false}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text(
              'Descartar alterações?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              erroDeRede
                  ? 'Não foi possível salvar. Deseja descartar as alterações e sair?'
                  : 'Os dados preenchidos não são válidos para salvar e serão perdidos.',
              style: const TextStyle(color: Colors.white70),
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

  Future<void> _editarSessao(SessaoTreinoModel sessao) async {
    // Captura o índice AGORA, antes de qualquer navegação ou recarregamento assíncrono.
    // Não usamos identical() depois porque recarregarDados() substitui os objetos.
    final indexNoMomento = _controller.indexOfSessao(sessao);
    if (indexNoMomento < 0) return;

    final diaSemana = sessao.diaSemana;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalSessaoDetalhePage(
          nomeTreino: sessao.nome,
          exercicios: sessao.exercicios,
          sessaoNote: sessao.orientacoes ?? '',
          onSaveToFirebase: _controller.rotinaId != null
              ? (exercicios, nome, note) async {
                  final idx = indexNoMomento;
                  if (idx >= _controller.treinos.length) return false;
                  _controller.atualizarSessaoCompleta(idx, nome, diaSemana, note, exercicios);
                  return await _controller.salvarRotinaAgora();
                }
              : null,
        ),
      ),
    );

    if (!mounted) return;

    if (result is Map<String, dynamic>) {
      if (_controller.rotinaId == null) {
        // Rotina nova: onSaveToFirebase é null, aplica resultado pelo índice capturado.
        final idx = indexNoMomento;
        if (idx < _controller.treinos.length) {
          _controller.atualizarSessaoCompleta(
            idx,
            result['nome'],
            diaSemana,
            result['sessaoNote'] ?? '',
            sessao.exercicios,
          );
        }
      }
      // Rotina existente: onSaveToFirebase já chamou atualizarSessaoCompleta + salvarRotinaBackground.
    }

    // Rotinas novas ainda sem ID precisam do await para criar o documento.
    if (_controller.rotinaId == null &&
        !_controller.isSaving &&
        _controller.verificarAlteracoes()) {
      await _controller.salvarRotina();
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
                navigator.pop();
                navigator.pop();
                navigator.pop();
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
    if (_controller.isSaving || _isSavingOverlay) return;

    // Se não houve alteração desde o último save manual, sai direto.
    if (_controller.saveFlushed || !_controller.verificarAlteracoes()) {
      setState(() => _canPopNow = true);
      Navigator.of(context).pop();
      return;
    }

    // Se há alterações, dispara o fluxo unificado de salvamento
    await _executarSalvamentoManual();
  }

  Future<void> _executarSalvamentoManual() async {
    if (_controller.isSaving || _isSavingOverlay) return;

    // Se não houve alteração desde o último save, apenas fecha a tela.
    if (!_controller.verificarAlteracoes()) {
      setState(() => _canPopNow = true);
      if (mounted) Navigator.pop(context);
      return;
    }

    final nomeParaSalvar = _controller.nomeCtrl.text.trim();
    final objetivoParaSalvar = _controller.objCtrl.text.trim();
    final sessoesParaSalvar = _controller.treinos;

    // Se os dados preenchidos não são válidos para salvar (ex: campos vazios)
    final podesSalvar = nomeParaSalvar.isNotEmpty &&
        objetivoParaSalvar.isNotEmpty &&
        sessoesParaSalvar.isNotEmpty;

    if (!podesSalvar) {
      final descartar = await _showDescartarDialog(erroDeRede: false);
      if (!mounted) return;
      if (descartar) {
        setState(() => _canPopNow = true);
        Navigator.of(context).pop();
      }
      return;
    }

    setState(() => _isSavingOverlay = true);

    // Feedback visual de salvamento (Staff-level UX)
    final animationDelay = Future.delayed(const Duration(milliseconds: 800));

    try {
      bool salvo = false;
      if (_controller.rotinaId != null) {
        salvo = await _controller.salvarRotinaAgora();
      } else {
        salvo = await _controller.salvarRotina();
      }

      if (!mounted) return;

      if (!salvo) {
        setState(() => _isSavingOverlay = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao salvar. Verifique sua conexão.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      await animationDelay;

      if (!mounted) return;
      setState(() {
        _isSavingOverlay = false;
        _canPopNow = true;
      });
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingOverlay = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
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
    return PopScope(
      canPop: _canPopNow,
      onPopInvokedWithResult: (didPop, result) => _handlePop(didPop),
      child: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return Stack(
              children: [
                Scaffold(
                  backgroundColor: AppColors.background,
                  body: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      AppFitSliverAppBar(
                        title: _controller.nomeRotinaExibicao,
                        expandedHeight: 148,
                        onBackPressed: () => Navigator.of(context).maybePop(),
                        actions: [
                          AppBarTextButton(
                            label: 'Salvar',
                            onPressed: _executarSalvamentoManual,
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
                      if (_controller.isDeleting)
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
                if (_isSavingOverlay) _buildSavingOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSavingOverlay() {
    return Container(
      color: Colors.black.withAlpha(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(100),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Salvando...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
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