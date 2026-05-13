import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/personal_service.dart';
import '../../../../core/widgets/app_swipe_to_delete.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/cadastro_aluno_modal.dart';
import 'personal_aluno_perfil_page.dart';

class PersonalAlunosPage extends StatefulWidget {
  final bool openCadastroOnLoad;
  final ValueNotifier<int>? cadastroTrigger;

  const PersonalAlunosPage({
    super.key,
    this.openCadastroOnLoad = false,
    this.cadastroTrigger,
  });

  @override
  State<PersonalAlunosPage> createState() => PersonalAlunosPageState();
}

class PersonalAlunosPageState extends State<PersonalAlunosPage> {
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
    widget.cadastroTrigger?.addListener(_onCadastroTriggered);

    if (widget.openCadastroOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          exibirModalCadastro();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    widget.cadastroTrigger?.removeListener(_onCadastroTriggered);
    super.dispose();
  }

  void _onCadastroTriggered() {
    if (mounted) {
      exibirModalCadastro();
    }
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

  void exibirModalCadastro() {
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Atmosfera Superior (Efeito de profundidade)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: SpacingTokens.atmosphereHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: GlassTokens.opacityAtmosphere),
                    AppColors.primary.withValues(alpha: GlassTokens.opacityAtmosphereSubtle),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              top: true,
              bottom: false,
              child: RefreshIndicator(
                onRefresh: _fetchInitialData,
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceDark,
                edgeOffset: 80,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    _buildHeader(context),

                    // Início do Console de Vidro (Cabeçalho do Console)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: GlassTokens.consoleMarginH),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: GlassTokens.opacityConsole),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(GlassTokens.consoleRadius),
                            topRight: Radius.circular(GlassTokens.consoleRadius),
                          ),
                          border: Border(
                            top: BorderSide(color: Colors.white.withValues(alpha: GlassTokens.opacityBorder), width: 1),
                            left: BorderSide(color: Colors.white.withValues(alpha: GlassTokens.opacityBorder), width: 1),
                            right: BorderSide(color: Colors.white.withValues(alpha: GlassTokens.opacityBorder), width: 1),
                            bottom: BorderSide.none,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildSearchBar(),
                            _buildMinimalistTabs(),
                          ],
                        ),
                      ),
                    ),

                    // Corpo do Console de Vidro (Lista de alunos)
                    if (_isLoading)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildConsoleBody(
                          child: const Center(
                            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                          ),
                        ),
                      )
                    else if (_alunosDocs.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildConsoleBody(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 80),
                            child: _searchQuery.isNotEmpty || _statusFilter != "todos"
                                ? _buildNoResultsState()
                                : _buildEmptyState(),
                          ),
                        ),
                      )
                    else ...[
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final doc = _alunosDocs[index];
                          final aluno = doc as Map<String, dynamic>;
                          return _buildConsoleBody(
                            child: _buildDismissibleCard(aluno['id'], aluno, isFirst: index == 0),
                          );
                        }, childCount: _alunosDocs.length),
                      ),
                      // Espaçador Infinito no final da lista
                      SliverFillRemaining(
                        hasScrollBody: false,
                        fillOverscroll: true,
                        child: _buildConsoleBody(
                          child: Column(
                            children: [
                              if (_hasMore)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 140), // Buffer para o FAB
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Wrapper para manter o aspecto de console nas laterais dos itens de lista.
  Widget _buildConsoleBody({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: GlassTokens.consoleMarginH),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: GlassTokens.opacityConsole),
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: GlassTokens.opacityBorder), width: 1),
          right: BorderSide(color: Colors.white.withValues(alpha: GlassTokens.opacityBorder), width: 1),
          bottom: BorderSide.none,
          top: BorderSide.none,
        ),
      ),
      child: child,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 16,
          left: 20,
          right: 20,
          bottom: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GERENCIAMENTO DE',
              style: AppTheme.technicalLabel.copyWith(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'ALUNOS',
              style: AppTheme.headerTitle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() => _searchQuery = val);
            _fetchInitialData();
          },
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          cursorColor: AppColors.primary,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'BUSCAR ALUNO',
            hintStyle: AppTheme.technicalLabel.copyWith(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 10,
              letterSpacing: 0.5,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.primary.withValues(alpha: 0.5),
              size: 18,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.4),
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
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalistTabs() {
    final filters = [
      {'label': 'TODOS', 'value': 'todos', 'count': _totalCount},
      {'label': 'ATIVOS', 'value': 'ativo', 'count': _ativosCount},
      {'label': 'RISCO', 'value': 'risco', 'count': _riscoCount},
      {'label': 'INATIVOS', 'value': 'inativo', 'count': _inativosCount},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
        ),
      ),
      child: Row(
        children: filters.map((filter) {
          final bool isSelected = _statusFilter == filter['value'];

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isSelected) {
                  HapticFeedback.lightImpact();
                  setState(() => _statusFilter = filter['value'] as String);
                  _fetchInitialData();
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        filter['label'] as String,
                        style: AppTheme.technicalLabel.copyWith(
                          fontSize: 8,
                          color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${filter['count']}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 2,
                    width: isSelected ? 24 : 0,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDismissibleCard(String id, Map<String, dynamic> aluno, {required bool isFirst}) {
    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: isFirst ? 16 : 4,
        bottom: 4,
      ),
      child: AppSwipeToDelete(
        dismissibleKey: Key(id),
        confirmDismiss: (direction) async {
          await _deletarAluno(id);
          return false;
        },
        onDismissed: (direction) {},
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
                      '${aluno['nome'] ?? ''} ${aluno['sobrenome'] ?? ''}'.trim(),
                  photoUrl: aluno['photo_url'],
                ),
              ),
            );
          },
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

    // Define a tag de status técnica
    Widget statusTag;
    if (!isAtivo) {
      statusTag = _buildTechnicalTag('INATIVO', Colors.white.withValues(alpha: 0.3));
    } else if (emRisco) {
      statusTag = _buildTechnicalTag('EM RISCO', AppColors.systemRed);
    } else {
      statusTag = _buildTechnicalTag('ATIVO', AppColors.primary);
    }

    return AppTappable(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Avatar Quadrado Real (Estilo Spotify Playlist)
            AppAvatar(
              name: nome,
              photoUrl: photoUrl,
              radius: 24,
              showBorder: false,
              isSquare: true,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          nome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      statusTag,
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email.toLowerCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.more_vert_rounded,
              color: Colors.white.withValues(alpha: 0.2),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói uma tag técnica minimalista (Pill).
  Widget _buildTechnicalTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withValues(alpha: 0.8),
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
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
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'NENHUM ALUNO AINDA',
            style: AppTheme.technicalLabel.copyWith(color: Colors.white, fontSize: 10),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque em NOVO ALUNO para começar.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
              fontWeight: FontWeight.w500
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'NENHUM RESULTADO',
            textAlign: TextAlign.center,
            style: AppTheme.technicalLabel.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}