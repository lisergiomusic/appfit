import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/aluno_service.dart';
import '../../core/services/rotina_service.dart';
import '../../core/widgets/app_swipe_to_delete.dart';
import 'rotina_detalhe_page.dart';
import '../../core/widgets/app_bar_icon_button.dart';

class TreinosPage extends StatefulWidget {
  final String? alunoId;
  final String? alunoNome;
  final AlunoService? alunoService;
  final RotinaService? rotinaService;

  const TreinosPage({
    super.key,
    this.alunoId,
    this.alunoNome,
    this.alunoService,
    this.rotinaService,
  });

  @override
  State<TreinosPage> createState() => _TreinosPageState();
}

class _TreinosPageState extends State<TreinosPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = "";

  late final AlunoService _alunoService;
  late final RotinaService _rotinaService;

  @override
  void initState() {
    super.initState();
    _alunoService = widget.alunoService ?? AlunoService();
    _rotinaService = widget.rotinaService ?? RotinaService();
  }

  Future<void> _deletarTreino(String id) async {
    await _rotinaService.excluirRotina(id);
  }

  Future<void> _confirmarExcluir(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        title: const Text(
          'Excluir template?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Isso removerá a ficha da sua biblioteca permanentemente.',
          style: TextStyle(color: AppColors.labelSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.labelSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Excluir',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
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
    final controller = TextEditingController(text: nomeAtual);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renomear treino'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nome do treino'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Salvar'),
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
    final bool isSelecting = widget.alunoId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          _buildSliverAppBar(isSelecting),
          SliverToBoxAdapter(child: _buildSearchBar()),
          StreamBuilder<QuerySnapshot>(
            stream: _alunoService.getRotinasTemplates(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final nome = (data['nome'] ?? '').toString().toLowerCase();
                return nome.contains(_searchQuery.toLowerCase());
              }).toList();

              if (filteredDocs.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                );
              }

              return SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        SpacingTokens.screenHorizontalPadding,
                        0,
                        SpacingTokens.screenHorizontalPadding,
                        SpacingTokens.labelToField,
                      ),
                      child: Text(
                        'Templates (${filteredDocs.length})',
                        style: AppTheme.sectionHeader,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        var doc = filteredDocs[index];
                        var rotina = doc.data() as Map<String, dynamic>;
                        int qtdSessoes = rotina['sessoes'] != null
                            ? (rotina['sessoes'] as List).length
                            : 0;

                        return _buildTreinoCard(
                          doc.id,
                          rotina,
                          qtdSessoes,
                          isSelecting,
                        );
                      }, childCount: filteredDocs.length),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isSelecting) {
    final String titleStr = isSelecting ? 'Templates' : 'Biblioteca de Rotinas';

    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: AppColors.background,
      surfaceTintColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: widget.alunoId != null
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            )
          : const SizedBox.shrink(),
      leadingWidth: widget.alunoId != null ? 56 : 0,
      centerTitle: true,
      actions: [
        if (!isSelecting)
          AppBarIconButton(
            icon: CupertinoIcons.add,
            size: 26,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RotinaDetalhePage(rotinaService: _rotinaService),
                ),
              );
            },
          ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCollapsed =
              constraints.biggest.height <=
              (kToolbarHeight + MediaQuery.of(context).padding.top + 10);

          return FlexibleSpaceBar(
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isCollapsed ? 1.0 : 0.0,
              child: Text(titleStr, style: AppTheme.pageTitle),
            ),
            centerTitle: true,
            titlePadding: const EdgeInsets.only(bottom: 14),
            background: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isCollapsed ? 0.0 : 1.0,
              child: Container(
                color: AppColors.background,
                padding: const EdgeInsets.fromLTRB(
                  SpacingTokens.screenHorizontalPadding,
                  SpacingTokens.screenTopPadding,
                  SpacingTokens.screenHorizontalPadding,
                  20,
                ),
                alignment: Alignment.bottomLeft,
                child: Text(titleStr, style: AppTheme.bigTitle),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.screenHorizontalPadding,
        0,
        SpacingTokens.screenHorizontalPadding,
        SpacingTokens.sectionGap,
      ),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: const TextStyle(
            color: AppColors.labelPrimary,
            fontSize: 16,
            letterSpacing: -0.41,
            fontWeight: FontWeight.w400,
          ),
          cursorColor: AppColors.primary,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Buscar templates...',
            hintStyle: TextStyle(
              color: AppColors.labelTertiary,
              fontSize: 17,
              letterSpacing: -0.41,
              fontWeight: FontWeight.w400,
            ),
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
                      _searchController.clear();
                      setState(() => _searchQuery = "");
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
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
      margin: const EdgeInsets.only(bottom: SpacingTokens.listItemGap),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: AppSwipeToDelete(
          dismissibleKey: Key(id),
          direction: isSelecting
              ? DismissDirection.none
              : DismissDirection.endToStart,
          label: 'Excluir',
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: AppColors.surfaceDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  ),
                  title: const Text(
                    'Excluir template?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    'Isso removerá a ficha da sua biblioteca permanentemente.',
                    style: TextStyle(color: AppColors.labelSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: AppColors.labelSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Excluir',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) => _deletarTreino(id),
          child: Container(
            decoration: AppTheme.cardDecoration,
            child: Material(
              color: Colors.transparent,
              elevation: 0,
              child: InkWell(
                borderRadius: CardTokens.cardRadius,
                onTap: () {
                  if (isSelecting) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RotinaDetalhePage(
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
                        builder: (context) => RotinaDetalhePage(
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(40),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSM,
                            ),
                          ),
                          child: Icon(
                            isSelecting ? Icons.add_task : Icons.fitness_center,
                            color: isSelecting
                                ? AppColors.iosBlue
                                : AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rotina['nome'] ?? 'Sem título',
                              style: AppTheme.cardTitle,
                            ),
                            const SizedBox(height: SpacingTokens.xs),
                            Text(
                              rotina['objetivo'] ?? '',
                              style: AppTheme.cardSubtitle,
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
                          if (value == 'editar') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RotinaDetalhePage(
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard_customize_outlined,
            size: 64,
            color: AppColors.labelSecondary.withAlpha(80),
          ),
          const SizedBox(height: 20),
          const Text(
            'Biblioteca vazia',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.labelPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie templates para atribuir\naos seus alunos.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyText.copyWith(color: AppColors.labelSecondary),
          ),
        ],
      ),
    );
  }
}
