import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/personal_service.dart';
import '../../../../core/services/rotina_service.dart';
import '../../../../core/widgets/app_swipe_to_delete.dart';
import '../../../../core/widgets/app_premium_fab.dart';
import 'personal_rotina_detalhe_page.dart';

class PersonalTreinosPage extends StatefulWidget {
  final String? alunoId;
  final String? alunoNome;
  final PersonalService? personalService;
  final RotinaService? rotinaService;
  final bool openCriarRotinaOnLoad;

  const PersonalTreinosPage({
    super.key,
    this.alunoId,
    this.alunoNome,
    this.personalService,
    this.rotinaService,
    this.openCriarRotinaOnLoad = false,
  });

  @override
  State<PersonalTreinosPage> createState() => _PersonalTreinosPageState();
}

class _PersonalTreinosPageState extends State<PersonalTreinosPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = "";
  final Set<String> _dismissedIds = {};

  late final PersonalService _personalService;
  late final RotinaService _rotinaService;
  late final Stream<dynamic> _rotinasStream;

  @override
  void initState() {
    super.initState();
    _personalService = widget.personalService ?? PersonalService();
    _rotinaService = widget.rotinaService ?? RotinaService();
    _rotinasStream = _personalService.getRotinasTemplates();

    if (widget.openCriarRotinaOnLoad && widget.alunoId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _abrirCriarRotina();
        }
      });
    }
  }

  void _abrirCriarRotina() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PersonalRotinaDetalhePage(rotinaService: _rotinaService),
      ),
    );
  }

  Future<void> _deletarTreino(String id) async {
    setState(() {
      _dismissedIds.add(id);
    });
    await _rotinaService.excluirRotina(id);
  }

  Future<void> _confirmarExcluir(String id) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        title: Text(
          'EXCLUIR TEMPLATE?',
          style: AppTheme.sectionHeader.copyWith(color: Colors.white, fontSize: 16),
        ),
        content: const Text(
          'Isso removerá a ficha da sua biblioteca permanentemente.',
          style: TextStyle(color: AppColors.labelSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'CANCELAR',
              style: AppTheme.sectionHeader.copyWith(color: AppColors.labelSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.pop(ctx, true);
            },
            child: Text(
              'EXCLUIR',
              style: AppTheme.sectionHeader.copyWith(color: AppColors.systemRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _deletarTreino(id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
        }
      }
    }
  }

  Future<void> _renomearTreino(String id, String nomeAtual) async {
    HapticFeedback.lightImpact();
    final controller = TextEditingController(text: nomeAtual);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        title: Text(
          'RENOMEAR TREINO',
          style: AppTheme.sectionHeader.copyWith(color: Colors.white, fontSize: 16),
        ),
        content: Container(
          decoration: AppTheme.premiumCardDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            autofocus: true,
            style: AppTheme.inputText,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: 'Nome do treino',
              hintStyle: AppTheme.inputPlaceHolder,
              border: InputBorder.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'CANCELAR',
              style: AppTheme.sectionHeader.copyWith(color: AppColors.labelSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx, true);
            },
            child: Text(
              'SALVAR',
              style: AppTheme.sectionHeader.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && controller.text.trim().isNotEmpty) {
      try {
        await _rotinaService.renomearRotina(id, controller.text.trim());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao renomear: $e')));
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mapa de seções da interface desta página:
    // 1) Estrutura superior: AppBar, título e ações de navegação.
    // 2) Conteúdo principal: blocos, listas, cards e estados da tela.
    // 3) Ações finais: botões primários, confirmadores e feedbacks.
    final bool isSelecting = widget.alunoId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: isSelecting
          ? null
          : AppPremiumFAB(
              label: 'NOVO MODELO',
              icon: CupertinoIcons.add,
              onPressed: _abrirCriarRotina,
              bottomPadding: 80,
            ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          _buildSliverAppBar(isSelecting),
          SliverToBoxAdapter(child: _buildSearchBar()),
          StreamBuilder<dynamic>(
            stream: _rotinasStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Erro ao carregar rotinas.\nVerifique sua conexão.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.labelSecondary),
                    ),
                  ),
                );
              }

              final docs = (snapshot.data as List<Map<String, dynamic>>?) ?? [];
              final filteredDocs = docs.where((data) {
                final id = data['id'].toString();
                if (_dismissedIds.contains(id)) return false;

                final nome = (data['nome'] ?? '').toString().toLowerCase();
                return nome.contains(_searchQuery.toLowerCase());
              }).toList();

              if (filteredDocs.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    var rotina = filteredDocs[index];
                    final id = rotina['id'].toString();
                    int qtdSessoes = rotina['sessoes'] != null
                        ? (rotina['sessoes'] as List).length
                        : 0;

                    return _buildTreinoCard(
                      id,
                      rotina,
                      qtdSessoes,
                      isSelecting,
                    );
                  }, childCount: filteredDocs.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isSelecting) {
    final String titleStr = isSelecting ? 'Biblioteca' : 'Biblioteca de treinos';

    return SliverAppBar(
      pinned: true,
      expandedHeight: 110,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: widget.alunoId != null
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            )
          : const SizedBox.shrink(),
      leadingWidth: widget.alunoId != null ? 56 : 0,
      actions: const [],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double topPadding = MediaQuery.of(context).padding.top;
          final double expandedHeight = 110.0 - kToolbarHeight - topPadding;
          final double currentHeight = constraints.maxHeight - kToolbarHeight - topPadding;
          final double percentage = (currentHeight / expandedHeight).clamp(0.0, 1.0);
          
          return FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: Container(
              decoration: BoxDecoration(gradient: AppTheme.premiumGradient),
              child: Stack(
                children: [
                  Positioned(
                    left: 20,
                    bottom: 16,
                    child: Opacity(
                      opacity: percentage.clamp(0.0, 1.0),
                      child: Text(
                        titleStr, 
                        style: AppTheme.bigTitle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            centerTitle: true,
            title: Opacity(
              opacity: (1.0 - percentage - 0.7).clamp(0.0, 1.0) * 3.3,
              child: Text(
                titleStr,
                style: AppTheme.pageTitle,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Container(
        height: 48,
        decoration: AppTheme.premiumCardDecoration,
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() => _searchQuery = val);
          },
          style: AppTheme.inputText,
          cursorColor: AppColors.primary,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Buscar modelos...',
            hintStyle: AppTheme.inputPlaceHolder,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.labelSecondary.withAlpha(120),
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.labelSecondary,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _searchController.clear();
                      setState(() => _searchQuery = "");
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildTreinoCard(
    String id,
    Map<String, dynamic> rotina,
    int qtdSessoes,
    bool isSelecting,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: AppSwipeToDelete(
          dismissibleKey: Key(id),
          direction: isSelecting
              ? DismissDirection.none
              : DismissDirection.endToStart,
          label: 'Excluir',
          confirmDismiss: (direction) async {
            HapticFeedback.mediumImpact();
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: AppColors.surfaceDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  ),
                  title: Text(
                    'EXCLUIR MODELO?',
                    style: AppTheme.sectionHeader.copyWith(color: Colors.white, fontSize: 16),
                  ),
                  content: const Text(
                    'Isso removerá este modelo da sua biblioteca permanentemente.',
                    style: TextStyle(color: AppColors.labelSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'CANCELAR',
                        style: AppTheme.sectionHeader.copyWith(color: AppColors.labelSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        Navigator.of(context).pop(true);
                      },
                      child: Text(
                        'EXCLUIR',
                        style: AppTheme.sectionHeader.copyWith(color: AppColors.systemRed),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) => _deletarTreino(id),
          child: Container(
            decoration: AppTheme.premiumCardDecoration,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              onTap: () {
                HapticFeedback.lightImpact();
                if (isSelecting) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PersonalRotinaDetalhePage(
                        rotinaData: rotina,
                        alunoId: widget.alunoId,
                        alunoNome: widget.alunoNome,
                        rotinaService: _rotinaService,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PersonalRotinaDetalhePage(
                        rotinaData: rotina,
                        rotinaId: id,
                        rotinaService: _rotinaService,
                      ),
                    ),
                  );
                }
              },
              child: Padding(
                padding: CardTokens.padding,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(40),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelecting ? AppColors.iosBlue : AppColors.primary,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        isSelecting ? Icons.add_task : Icons.fitness_center,
                        color: isSelecting
                            ? AppColors.iosBlue
                            : AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                (rotina['nome'] ?? 'Sem título').toString().toUpperCase(),
                                style: AppTheme.cardTitle,
                              ),
                              if (qtdSessoes > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(40),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$qtdSessoes SESSÕES',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ]
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rotina['objetivo'] ?? 'Sem objetivo definido',
                            style: AppTheme.cardSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: AppColors.labelSecondary,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      color: AppColors.surfaceDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMD,
                        ),
                      ),
                      onSelected: (value) {
                        HapticFeedback.lightImpact();
                        if (value == 'editar') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PersonalRotinaDetalhePage(
                                rotinaData: rotina,
                                rotinaId: isSelecting ? null : id,
                                alunoId: isSelecting ? widget.alunoId : null,
                                alunoNome: isSelecting
                                    ? widget.alunoNome
                                    : null,
                                rotinaService: _rotinaService,
                              ),
                            ),
                          );
                        } else if (value == 'renomear') {
                          _renomearTreino(id, rotina['nome'] ?? '');
                        } else if (value == 'excluir') {
                          _confirmarExcluir(id);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Text(
                            'Editar',
                            style: TextStyle(color: AppColors.labelPrimary),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'renomear',
                          child: Text(
                            'Renomear',
                            style: TextStyle(color: AppColors.labelPrimary),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'excluir',
                          child: Text(
                            'Excluir',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard_customize_rounded,
            size: 64,
            color: AppColors.labelSecondary.withAlpha(30),
          ),
          const SizedBox(height: 24),
          Text(
            'BIBLIOTECA VAZIA',
            style: AppTheme.sectionHeader.copyWith(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crie modelos para atribuir aos seus alunos.',
            style: TextStyle(color: AppColors.labelSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}