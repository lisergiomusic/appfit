import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/personal_service.dart';
import '../../../../core/widgets/app_swipe_to_delete.dart';
import '../../shared/widgets/app_avatar.dart';
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
  final PersonalService _personalService = PersonalService();

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
      final contagens = await _personalService.fetchContagens().timeout(
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
      debugPrint("Aviso: Falha ao carregar contagens: $e");
    }
  }

  Future<void> _fetchNextPage({bool isInitial = false}) async {
    if (!isInitial && (_isLoadingMore || !_hasMore)) return;

    if (!isInitial) setState(() => _isLoadingMore = true);

    try {
      final result = await _personalService
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
    HapticFeedback.mediumImpact();
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        title: Text(
          'REMOVER ALUNO',
          style: AppTheme.sectionHeader.copyWith(color: Colors.white, fontSize: 16),
        ),
        content: const Text(
          'Deseja realmente remover este aluno? Todos os dados vinculados serão perdidos.',
          style: TextStyle(color: AppColors.labelSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCELAR',
              style: AppTheme.sectionHeader.copyWith(color: AppColors.labelSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.pop(context, true);
            },
            child: Text(
              'REMOVER',
              style: AppTheme.sectionHeader.copyWith(color: AppColors.systemRed),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _personalService.deletarAluno(id);
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
      await _personalService.salvarAluno(
        nome,
        sobrenome,
        email,
        whatsapp: whatsapp,
        genero: genero,
        dataNascimento: dataNascimento,
      );
      if (context.mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        _fetchInitialData();
      }
    } catch (e) {
      debugPrint("Erro ao salvar: $e");
    }
  }

  void _exibirModalCadastro() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CadastroAlunoModal(onSalvar: _salvarAluno),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: const SizedBox.shrink(),
      leadingWidth: 0,
      actions: [
        IconButton(
          icon: const Icon(CupertinoIcons.add, color: AppColors.primary, size: 24),
          onPressed: _exibirModalCadastro,
          padding: const EdgeInsets.only(right: 16),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: Container(
          decoration: BoxDecoration(gradient: AppTheme.premiumGradient),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        centerTitle: false,
        title: Text('Meus Alunos', style: AppTheme.pageTitle),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Container(
        height: 44,
        decoration: AppTheme.premiumCardDecoration,
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() => _searchQuery = val);
            _fetchInitialData();
          },
          style: AppTheme.inputText,
          cursorColor: AppColors.primary,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Buscar por nome...',
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
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
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
            HapticFeedback.lightImpact();
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
            photoUrl: aluno['photo_url'],
            ultimoTreino: aluno['ultimo_treino'],
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PersonalAlunoPerfilPage(
                    alunoId: id,
                    alunoNome:
                        '${aluno['nome'] ?? ''} ${aluno['sobrenome'] ?? ''}'
                            .trim(),
                    photoUrl: aluno['photo_url'],
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
      decoration: AppTheme.premiumCardDecoration,
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
                  AppAvatar(
                    name: nome,
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
          Text(
            'NENHUM ALUNO AINDA',
            style: AppTheme.sectionHeader.copyWith(color: Colors.white, fontSize: 16),
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
              'NENHUM RESULTADO PARA OS FILTROS APLICADOS',
              textAlign: TextAlign.center,
              style: AppTheme.sectionHeader.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
