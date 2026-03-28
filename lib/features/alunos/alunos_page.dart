import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/aluno_service.dart';
import 'perfil_aluno_page.dart';
import 'widgets/aluno_avatar.dart';

class AlunosPage extends StatefulWidget {
  const AlunosPage({super.key});

  @override
  State<AlunosPage> createState() => _AlunosPageState();
}

class _AlunosPageState extends State<AlunosPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AlunoService _alunoService = AlunoService();

  String _searchQuery = "";
  String _statusFilter = "todos"; // "todos", "ativo", "inativo", "risco"

  // Estados de Paginação
  List<DocumentSnapshot> _alunosDocs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  static const int _limit = 20;

  // Contagens Globais para os Chips
  int _totalCount = 0;
  int _ativosCount = 0;
  int _inativosCount = 0;
  int _riscoCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _scrollController.addListener(_onScroll);
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

    await Future.wait([
      _updateSummaryCounts(),
      _fetchNextPage(isInitial: true),
    ]);

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _updateSummaryCounts() async {
    try {
      final contagens = await _alunoService.fetchContagens();
      if (mounted) {
        setState(() {
          _totalCount = contagens.total;
          _ativosCount = contagens.ativos;
          _inativosCount = contagens.inativos;
          _riscoCount = contagens.risco;
        });
      }
    } catch (e) {
      debugPrint("Erro ao buscar contagens: $e");
    }
  }

  Future<void> _fetchNextPage({bool isInitial = false}) async {
    if (!isInitial && (_isLoadingMore || !_hasMore)) return;

    if (!isInitial) setState(() => _isLoadingMore = true);

    try {
      final result = await _alunoService.fetchAlunosPaginado(
        statusFilter: _statusFilter,
        searchQuery: _searchQuery,
        lastDoc: _lastDocument,
        limit: _limit,
      );

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
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _deletarAluno(String id) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: const Text(
          'Remover Aluno',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Deseja realmente remover este aluno? Todos os dados vinculados serão perdidos.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(
                color: AppTheme.textSecondary,
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
  ) async {
    if (nome.isEmpty || sobrenome.isEmpty || email.isEmpty) return;

    try {
      await _alunoService.salvarAluno(nome, sobrenome, email);
      if (context.mounted) {
        Navigator.pop(context);
        _fetchInitialData();
      }
    } catch (e) {
      debugPrint("Erro ao salvar: $e");
    }
  }

  void _exibirModalCadastro() {
    final nomeController = TextEditingController();
    final sobrenomeController = TextEditingController();
    final emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          left: 24,
          right: 24,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Novo Aluno',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Preencha os dados do aluno abaixo',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 32),
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: sobrenomeController,
              decoration: const InputDecoration(
                labelText: 'Sobrenome',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail de Acesso',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _salvarAluno(
                  context,
                  nomeController.text,
                  sobrenomeController.text,
                  emailController.text,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'CADASTRAR ALUNO',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _fetchInitialData,
        color: AppTheme.primary,
        backgroundColor: AppTheme.surfaceDark,
        child: ListView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.zero,
          children: [
            _buildSearchBar(),
            _buildFilterChips(),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 64),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else if (_alunosDocs.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 64),
                child: _searchQuery.isNotEmpty || _statusFilter != "todos"
                    ? _buildNoResultsState()
                    : _buildEmptyState(),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _alunosDocs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _alunosDocs.length) {
                      return _hasMore
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primary,
                                ),
                              ),
                            )
                          : const SizedBox.shrink();
                    }
                    final doc = _alunosDocs[index];
                    final aluno = doc.data() as Map<String, dynamic>;
                    return _buildDismissibleCard(doc.id, aluno);
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exibirModalCadastro,
        icon: const Icon(Icons.add, color: Colors.black, size: 20),
        label: const Text(
          'Adicionar',
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.background.withAlpha(200),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Row(children: [const SizedBox(width: 10), Text('Gerenciamento de Alunos')]),
      actions: [
        IconButton(
          icon: Stack(
            children: [
              const Icon(
                Icons.notifications_rounded,
                color: AppTheme.textPrimary,
                size: 26,
              ),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.background,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          height: 1.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withAlpha(0),
                Colors.white.withAlpha(20),
                Colors.white.withAlpha(0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: Colors.white.withAlpha(10)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() => _searchQuery = val);
            _fetchInitialData();
          },
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Pesquisar por nome...',
            hintStyle: TextStyle(color: AppTheme.textSecondary.withAlpha(80)),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppTheme.textSecondary,
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppTheme.primary, width: 1),
            ),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Row(
        children: [
          Expanded(
            child: _buildChip(
              label: 'Todos',
              count: _totalCount,
              value: 'todos',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildChip(
              label: 'Ativos',
              count: _ativosCount,
              value: 'ativo',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildChip(
              label: 'Risco',
              count: _riscoCount,
              value: 'risco',
              activeColor: Colors.orangeAccent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildChip(
              label: 'Inativos',
              count: _inativosCount,
              value: 'inativo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required int count,
    required String value,
    Color? activeColor,
  }) {
    final bool isSelected = _statusFilter == value;
    final Color primaryColor = activeColor ?? AppTheme.primary;

    return GestureDetector(
      onTap: () {
        if (_statusFilter != value) {
          setState(() => _statusFilter = value);
          _fetchInitialData();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.white.withAlpha(15),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withAlpha(60),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.black.withAlpha(40)
                    : Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.black : AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleCard(String id, Map<String, dynamic> aluno) {
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        await _deletarAluno(id);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_sweep_rounded,
          color: Colors.redAccent,
          size: 28,
        ),
      ),
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
              builder: (context) => PerfilAlunoPage(
                alunoId: id,
                alunoNome: '${aluno['nome'] ?? ''} ${aluno['sobrenome'] ?? ''}'
                    .trim(),
                photoUrl: aluno['photoUrl'],
              ),
            ),
          );
        },
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
      final DateTime lastWorkout = (ultimoTreino as Timestamp).toDate();
      if (DateTime.now().difference(lastWorkout).inDays >= 7) {
        emRisco = true;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    AlunoAvatar(
                      alunoNome: nome,
                      photoUrl: photoUrl,
                      radius: 26,
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
                  color: AppTheme.textSecondary.withAlpha(100),
                  size: 14,
                ),
              ],
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
            Icons.group_add_rounded,
            size: 64,
            color: AppTheme.textSecondary.withAlpha(30),
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
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
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
              color: AppTheme.textSecondary.withAlpha(40),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum resultado para os filtros aplicados',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}