import 'package:flutter/material.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../aluno/aluno_home_page.dart';
import '../personal/personal_home_page.dart';
import '../../alunos/aluno/pages/aluno_conta_page.dart';
import '../../alunos/personal/pages/personal_alunos_page.dart';
import '../../treinos/personal/pages/personal_treinos_page.dart';
import '../../treinos/aluno/pages/aluno_historico_page.dart';
import '../../alunos/personal/pages/personal_conta_page.dart';

class DashboardPage extends StatefulWidget {
  final String userType;
  const DashboardPage({super.key, required this.userType});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _indiceAtual = 0;
  final SupabaseAuthService _authService = SupabaseAuthService();

  List<Widget> _getPaginas() {
    final uid = _authService.currentUser?.id ?? '';
    final isAluno = widget.userType == 'aluno';

    if (isAluno) {
      return [
        AlunoHomePage(uid: uid),
        AlunoHistoricoPage(uid: uid),
        AlunoContaPage(uid: uid),
      ];
    }

    return [
      PersonalHomePage(
        onNovoAlunoTap: _abrirCadastroAlunoPeloAtalhoHome,
        onCriarRotinaTap: _abrirCriacaoRotinaPeloAtalhoHome,
      ),
      PersonalAlunosPage(
        openCadastroOnLoad: _abrirCadastroPendente,
      ),
      PersonalTreinosPage(
        openCriarRotinaOnLoad: _abrirCriacaoPendente,
      ),
      PersonalContaPage(uid: uid),
    ];
  }

  bool _abrirCadastroPendente = false;
  bool _abrirCriacaoPendente = false;

  void _abrirCadastroAlunoPeloAtalhoHome() {
    setState(() {
      _indiceAtual = 1;
      _abrirCadastroPendente = true;
    });
    // Resetar flag após o frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _abrirCadastroPendente = false;
    });
  }

  void _abrirCriacaoRotinaPeloAtalhoHome() {
    setState(() {
      _indiceAtual = 2;
      _abrirCriacaoPendente = true;
    });
    // Resetar flag após o frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _abrirCriacaoPendente = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAluno = widget.userType == 'aluno';
    final paginas = _getPaginas();

    final List<BottomNavigationBarItem> items = isAluno
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Histórico',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Conta'),
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
      body: IndexedStack(index: _indiceAtual, children: paginas),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: (index) => setState(() => _indiceAtual = index),
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