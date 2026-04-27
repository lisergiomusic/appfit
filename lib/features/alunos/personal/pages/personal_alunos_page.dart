import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/aluno_service.dart';
import '../../../../core/widgets/app_swipe_to_delete.dart';
import '../../../../core/widgets/app_bar_icon_button.dart';
import '../../shared/widgets/aluno_avatar.dart';
import '../../shared/widgets/cadastro_aluno_modal.dart';
import 'personal_aluno_perfil_page.dart';

class PersonalAlunosPage extends StatefulWidget {
  final bool openCadastroOnLoad;

  const PersonalAlunosPage({super.key, this.openCadastroOnLoad = false});

  @override
  State<PersonalAlunosPage> createState() => _PersonalAlunosPageState();
}

class _PersonalAlunosPageState extends State<PersonalAlunosPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AlunoService _alunoService = AlunoService();

  String _searchQuery = "";
  String _statusFilter = "todos";

  List<dynamic> _alunosDocs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  dynamic _lastDocument;
  static const int _limit = 20;

  int _totalCount = 0;
  int _ativosCount = 0;
  int _inativosCount = 0;
  int _riscoCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _scrollController.addListener(_onScroll);

    if (widget.openCadastroOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _exibirModalCadastro();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _fetchNextPage();
      }
    }
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _alunosDocs = [];
      _lastDocument = null;
      _hasMore = true;
    });

    try {
      await Future.wait([
        _updateSummaryCounts(),
        _fetchNextPage(isInitial: true),
      ]).timeout(const Duration(seconds: 12));
    } catch (e) {
      debugPrint("Timeout/erro no carregamento inicial: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível carregar os alunos agora. Tente novamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSummaryCounts() async {
    try {
      // Tenta buscar as contagens com um timeout generoso, mas sem travar o resto
      final contagens = await _alunoService.fetchContagens().timeout(
        const Duration(seconds: 10),
      );
      if (mounted) {
        setState(() {
          _totalCount = contagens.total;
          _ativosCount = contagens.ativos;
          _inativosCount = contagens.inativos;
          _riscoCount = contagens.risco;
        });
      }
    } catch (e) {
      // Se der erro nas contagens (timeout ou falta de índice), apenas logamos.
      // A lista de alunos abaixo continuará tentando carregar.
      debugPrint("Aviso: Falha ao carregar contagens (resumo), mas continuando... Erro: $e");
    }
  }

  Future<void> _fetchNextPage({bool isInitial = false}) async {
    if (!isInitial && (_isLoadingMore || !_hasMore)) return;

    if (!isInitial) setState(() => _isLoadingMore = true);

    try {
      final result = await _alunoService
          .fetchAlunosPaginado(
            statusFilter: _statusFilter,
            searchQuery: _searchQuery,
            lastDoc: _lastDocument,
            limit: _limit,
          )
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _hasMore = result.hasMore;
          if (result.docs.isNotEmpty) {
            _lastDocument = result.lastDoc;
            _alunosDocs.addAll(result.docs);
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao buscar alunos: $e");
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _deletarAluno(String id) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        title: const Text(
          'Remover Aluno',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Deseja realmente remover este aluno? Todos os dados vinculados serão perdidos.',
          style: TextStyle(color: AppColors.labelSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(
                color: AppColors.labelSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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

    if (confirmar == true) {
      await _alunoService.deletarAluno(id);
      _fetchInitialData();
    }
  }

  Future<void> _salvarAluno(
    BuildContext context,
    String nome,
    String sobrenome,
    String email,
    String whatsapp,
    String? genero,
    DateTime? dataNascimento,
  ) async {
    if (nome.isEmpty) return;

    try {
      await _alunoService.salvarAluno(
        nome,
        sobrenome,
        email,
        whatsapp: whatsapp,
        genero: genero,
        dataNascimento: dataNascimento,
      );
      if (context.mounted) {
        Navigator.pop(context);
        _fetchInitialData();
      }
    } catch (e) {
      debugPrint("Erro ao salvar: $e");
    }
  }

  void _exibirModalCadastro() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CadastroAlunoModal(onSalvar: _salvarAluno),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mapa de seções da interface desta página:
    // 1) Estrutura superior: AppBar, título e ações de navegação.
    // 2) Conteúdo principal: blocos, listas, cards e estados da tela.
    // 3) Ações finais: botões primários, confirmadores e feedbacks.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchInitialData,
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceDark,
        edgeOffset: 120,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildFilterChips()),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_alunosDocs.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: _searchQuery.isNotEmpty || _statusFilter != "todos"
                      ? _buildNoResultsState()
                      : _buildEmptyState(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == _alunosDocs.length) {
                      return _hasMore
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : const SizedBox.shrink();
                    }
                    final doc = _alunosDocs[index];
                    final aluno = doc as Map<String, dynamic>;
                    return _buildDismissibleCard(aluno['id'], aluno);
                  }, childCount: _alunosDocs.length + 1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: AppColors.background,
      surfaceTintColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: const SizedBox.shrink(),
      leadingWidth: 0,
      centerTitle: true,
      actions: [
        AppBarIconButton(
          icon: CupertinoIcons.add,
          padding: const EdgeInsets.only(right: 16, top: 4),
          onPressed: _exibirModalCadastro,
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
              child: const Text('Meus Alunos', style: AppTheme.pageTitle),
            ),
            centerTitle: true,
            titlePadding: const EdgeInsets.only(bottom: 14),
            background: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isCollapsed ? 0.0 : 1.0,
              child: Container(
                color: AppColors.background,
                padding: const EdgeInsets.only(
                  left: SpacingTokens.screenHorizontalPadding,
                  right: SpacingTokens.screenHorizontalPadding,
                  bottom: 20,
                ),
                alignment: Alignment.bottomLeft,
                child: Text('Meus Alunos', style: AppTheme.bigTitle),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() => _searchQuery = val);
            _fetchInitialData();
          },
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
            hintText: 'Buscar por nome...',
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
                      _fetchInitialData();
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

  Widget _buildFilterChips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: CupertinoSlidingSegmentedControl<String>(
        backgroundColor: AppColors.surfaceDark,
        thumbColor: const Color(0xFF3A3A3C),
        groupValue: _statusFilter,
        children: {
          'todos': _buildSegment('Todos', _totalCount, 'todos'),
          'ativo': _buildSegment('Ativos', _ativosCount, 'ativo'),
          'risco': _buildSegment('Risco', _riscoCount, 'risco'),
          'inativo': _buildSegment('Inativos', _inativosCount, 'inativo'),
        },
        onValueChanged: (value) {
          if (value != null) {
            setState(() => _statusFilter = value);
            _fetchInitialData();
          }
        },
      ),
    );
  }

  Widget _buildSegment(String label, int count, String value) {
    final bool isSelected = _statusFilter == value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              letterSpacing: -0.08,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.labelSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? AppColors.primary : AppColors.labelTertiary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleCard(String id, Map<String, dynamic> aluno) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: AppSwipeToDelete(
          dismissibleKey: Key(id),
          confirmDismiss: (direction) async {
            await _deletarAluno(id);
            return false;
          },
          onDismissed: (direction) {
          },
          child: _buildAlunoCard(
            nome: '${aluno['nome'] ?? ''} ${aluno['sobrenome'] ?? ''}'.trim(),
            email: aluno['email'] ?? 'Sem e-mail',
            status: aluno['status'] ?? 'ativo',
            photoUrl: aluno['photoUrl'],
            ultimoTreino: aluno['ultimoTreino'],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PersonalAlunoPerfilPage(
                    alunoId: id,
                    alunoNome:
                        '${aluno['nome'] ?? ''} ${aluno['sobrenome'] ?? ''}'
                            .trim(),
                    photoUrl: aluno['photoUrl'],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAlunoCard({
    required String nome,
    required String email,
    required String status,
    String? photoUrl,
    dynamic ultimoTreino,
    required VoidCallback onTap,
  }) {
    final bool isAtivo = status == 'ativo';

    bool emRisco = false;
    if (ultimoTreino != null && isAtivo) {
      final DateTime? lastWorkout = DateTime.tryParse(ultimoTreino.toString());
      if (lastWorkout != null && DateTime.now().difference(lastWorkout).inDays >= 7) {
        emRisco = true;
      }
    }

    // Define a cor da borda baseada no status real
    Color statusColor;
    if (!isAtivo) {
      statusColor = AppColors.labelSecondary.withAlpha(100); // Inativo
    } else if (emRisco) {
      statusColor = Colors.orangeAccent; // Risco
    } else {
      statusColor = AppColors.success; // Ativo
    }

    return Container(
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Padding(
          padding: CardTokens.padding,
          child: Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  AlunoAvatar(
                    alunoNome: nome,
                    photoUrl: photoUrl,
                    radius: 20,
                    borderColor: statusColor,
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(nome, style: AppTheme.cardTitle),
                        if (emRisco) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withAlpha(40),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'RISCO',
                              style: TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email.toLowerCase(),
                      style: AppTheme.cardSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.labelSecondary.withAlpha(100),
                size: 14,
              ),
            ],
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
            Icons.group_add_rounded,
            size: 64,
            color: AppColors.labelSecondary.withAlpha(30),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nenhum aluno ainda',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toque em ADICIONAR para começar.',
            style: TextStyle(color: AppColors.labelSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.labelSecondary.withAlpha(40),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum resultado para os filtros aplicados',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.labelSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}