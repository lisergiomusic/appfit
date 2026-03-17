import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import 'perfil_aluno_page.dart';

class AlunosPage extends StatefulWidget {
  const AlunosPage({super.key});

  @override
  State<AlunosPage> createState() => _AlunosPageState();
}

class _AlunosPageState extends State<AlunosPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _statusFilter = "todos"; // "todos", "ativo", "inativo"

  Future<void> _deletarAluno(String id) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        title: const Text('Remover Aluno', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Deseja realmente remover este aluno? Todos os dados vinculados serão perdidos.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('REMOVER', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await FirebaseFirestore.instance.collection('usuarios').doc(id).delete();
    }
  }

  Future<void> _salvarAluno(BuildContext context, String nome, String email) async {
    if (nome.isEmpty || email.isEmpty) return;

    final String? personalId = FirebaseAuth.instance.currentUser?.uid;
    if (personalId == null) return;

    try {
      await FirebaseFirestore.instance.collection('usuarios').add({
        'nome': nome,
        'email': email,
        'tipoUsuario': 'aluno',
        'status': 'ativo', // Padrão ao cadastrar
        'personalId': personalId,
        'dataCriacao': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Erro ao salvar: $e");
    }
  }

  void _exibirModalCadastro() {
    final nomeController = TextEditingController();
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
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                    ),
                    Text(
                      'Preencha os dados do aluno abaixo',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
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
                labelText: 'Nome do Aluno',
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
                onPressed: () => _salvarAluno(context, nomeController.text, emailController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('CADASTRAR ALUNO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? personalId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exibirModalCadastro,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.black, size: 20),
        label: const Text('ADICIONAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .where('tipoUsuario', isEqualTo: 'aluno')
                  .where('personalId', isEqualTo: personalId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nome = data['nome']?.toString().toLowerCase() ?? "";
                  final status = data['status']?.toString().toLowerCase() ?? "ativo";

                  final matchesSearch = nome.contains(_searchQuery.toLowerCase());
                  final matchesFilter = _statusFilter == "todos" || status == _statusFilter;

                  return matchesSearch && matchesFilter;
                }).toList();

                if (docs.isEmpty && (_searchQuery.isNotEmpty || _statusFilter != "todos")) {
                  return _buildNoResultsState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final aluno = doc.data() as Map<String, dynamic>;
                    return _buildDismissibleCard(doc.id, aluno);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.background.withAlpha(200),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fitness_center, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: AppTheme.space12),
          const Text(
            'AppFit',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.8),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined, color: AppTheme.textPrimary, size: 26),
          onPressed: () {},
        ),
        const SizedBox(width: AppTheme.space12),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          height: 1.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withAlpha(0), Colors.white.withAlpha(20), Colors.white.withAlpha(0)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meus Alunos',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 40,
              letterSpacing: -1.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.iosBlue]),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'GERENCIAMENTO DE CLIENTES',
                style: AppTheme.textSectionHeaderDark.copyWith(fontSize: 10, letterSpacing: 1.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(10)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Pesquisar por nome...',
            hintStyle: TextStyle(color: AppTheme.textSecondary.withAlpha(80)),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary),
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
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildChip(label: 'Todos', value: 'todos'),
          const SizedBox(width: 8),
          _buildChip(label: 'Ativos', value: 'ativo'),
          const SizedBox(width: 8),
          _buildChip(label: 'Inativos', value: 'inativo'),
        ],
      ),
    );
  }

  Widget _buildChip({required String label, required String value}) {
    final bool isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.white.withAlpha(15),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.primary.withAlpha(60), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            fontSize: 13,
          ),
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
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 28),
      ),
      child: _buildAlunoCard(
        nome: aluno['nome'] ?? 'Sem nome',
        email: aluno['email'] ?? 'Sem e-mail',
        status: aluno['status'] ?? 'ativo',
        photoUrl: aluno['photoUrl'],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PerfilAlunoPage(alunoId: id, alunoNome: aluno['nome']),
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
    required VoidCallback onTap,
  }) {
    final bool isAtivo = status == 'ativo';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withAlpha(150),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isAtivo ? [AppTheme.primary, AppTheme.iosBlue] : [Colors.grey, Colors.blueGrey],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: AppTheme.surfaceLight,
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null || photoUrl.isEmpty
                            ? Text(nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: isAtivo ? AppTheme.primary : Colors.grey,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ))
                            : null,
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isAtivo ? AppTheme.primary : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.surfaceDark, width: 2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email.toLowerCase(),
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withAlpha(180), fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textSecondary.withAlpha(100), size: 14),
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
          Icon(Icons.group_add_rounded, size: 64, color: AppTheme.textSecondary.withAlpha(30)),
          const SizedBox(height: 24),
          const Text('Nenhum aluno ainda', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Toque em ADICIONAR para começar.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
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
            Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textSecondary.withAlpha(40)),
            const SizedBox(height: 16),
            Text('Nenhum resultado para os filtros aplicados',
                textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}