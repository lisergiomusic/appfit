import '../treinos/treinos_page.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import 'home_page.dart';
import 'aluno_home_page.dart';
import '../alunos/alunos_page.dart';
import '../alunos/aluno_perfil_page.dart';
import '../../main.dart';

class DashboardPage extends StatefulWidget {
  final String userType;
  const DashboardPage({super.key, required this.userType});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _indiceAtual = 0;
  final AuthService _authService = AuthService();
  bool _openCadastroAlunoOnNextBuild = false;
  bool _openCriarRotinaOnNextBuild = false;

  void _abrirCadastroAlunoPeloAtalhoHome() {
    setState(() {
      _indiceAtual = 1;
      _openCadastroAlunoOnNextBuild = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_openCadastroAlunoOnNextBuild) return;
      setState(() {
        _openCadastroAlunoOnNextBuild = false;
      });
    });
  }

  void _abrirCriacaoRotinaPeloAtalhoHome() {
    setState(() {
      _indiceAtual = 2;
      _openCriarRotinaOnNextBuild = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_openCriarRotinaOnNextBuild) return;
      setState(() {
        _openCriarRotinaOnNextBuild = false;
      });
    });
  }

  Future<void> _sair(BuildContext context) async {
    await _authService.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ChecagemPagina()),
        (route) => false,
      );
    }
  }

  Widget _buildAjustes(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.settings, size: 64, color: AppColors.labelSecondary),
          const SizedBox(height: AppTheme.space16),
          const Text(
            'Ajustes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.space32),
          ElevatedButton.icon(
            onPressed: () => _sair(context),
            icon: const Icon(Icons.logout),
            label: const Text('Sair do AppFit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withAlpha(25),
              foregroundColor: Colors.redAccent,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAluno = widget.userType == 'aluno';
    final uid = _authService.currentUser?.uid ?? '';

    final List<Widget> paginas = isAluno
        ? [
            AlunoHomePage(uid: uid),
            const Center(
              child: Text(
                'Meu Treino — em breve',
                style: TextStyle(color: AppColors.labelSecondary),
              ),
            ),
            AlunoPerfliPage(uid: uid),
          ]
        : [
            HomePage(
              onNovoAlunoTap: _abrirCadastroAlunoPeloAtalhoHome,
              onCriarRotinaTap: _abrirCriacaoRotinaPeloAtalhoHome,
            ),
            AlunosPage(openCadastroOnLoad: _openCadastroAlunoOnNextBuild),
            TreinosPage(openCriarRotinaOnLoad: _openCriarRotinaOnNextBuild),
            _buildAjustes(context),
          ];

    final List<BottomNavigationBarItem> items = isAluno
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center),
              label: 'Meu Treino',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Início',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Alunos'),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center),
              label: 'Rotinas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: paginas[_indiceAtual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: (index) {
          setState(() {
            _indiceAtual = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.labelSecondary,
        elevation: 16,
        items: items,
      ),
    );
  }
}
