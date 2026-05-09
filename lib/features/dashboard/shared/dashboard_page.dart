import 'package:flutter/material.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_bottom_nav.dart';
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

    final List<GlassBottomNavItem> items = isAluno
        ? const [
            GlassBottomNavItem(
              icon: Icons.grid_view_outlined,
              activeIcon: Icons.grid_view_rounded,
              label: 'Início',
            ),
            GlassBottomNavItem(
              icon: Icons.bar_chart_outlined,
              activeIcon: Icons.bar_chart_rounded,
              label: 'Histórico',
            ),
            GlassBottomNavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Conta',
            ),
          ]
        : const [
            GlassBottomNavItem(
              icon: Icons.grid_view_outlined,
              activeIcon: Icons.grid_view_rounded,
              label: 'Início',
            ),
            GlassBottomNavItem(
              icon: Icons.group_outlined,
              activeIcon: Icons.group_rounded,
              label: 'Alunos',
            ),
            GlassBottomNavItem(
              icon: Icons.fitness_center_outlined,
              activeIcon: Icons.fitness_center_rounded,
              label: 'Rotinas',
            ),
            GlassBottomNavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings_rounded,
              label: 'Ajustes',
            ),
          ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(index: _indiceAtual, children: paginas),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _indiceAtual,
        items: items,
        onTap: (index) => setState(() => _indiceAtual = index),
      ),
    );
  }
}