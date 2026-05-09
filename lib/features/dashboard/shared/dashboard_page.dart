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
  int _indiceAnterior = 0;
  final SupabaseAuthService _authService = SupabaseAuthService();
  late List<Widget> _paginas;

  @override
  void initState() {
    super.initState();
    _paginas = _getPaginas();
  }

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
      _indiceAnterior = _indiceAtual;
      _indiceAtual = 1;
      _abrirCadastroPendente = true;
      // Atualiza a página com o novo estado de abertura pendente
      _paginas = _getPaginas();
    });
    // Resetar flag após o frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _abrirCadastroPendente = false;
      if (mounted) {
        setState(() {
          _paginas = _getPaginas();
        });
      }
    });
  }

  void _abrirCriacaoRotinaPeloAtalhoHome() {
    setState(() {
      _indiceAnterior = _indiceAtual;
      _indiceAtual = 2;
      _abrirCriacaoPendente = true;
      // Atualiza a página com o novo estado de abertura pendente
      _paginas = _getPaginas();
    });
    // Resetar flag após o frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _abrirCriacaoPendente = false;
      if (mounted) {
        setState(() {
          _paginas = _getPaginas();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAluno = widget.userType == 'aluno';

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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutQuart,
        switchOutCurve: Curves.easeInQuart,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final isIncoming = child.key == ValueKey<int>(_indiceAtual);
          final slidingRight = _indiceAtual > _indiceAnterior;
          
          Offset beginOffset;
          if (isIncoming) {
            beginOffset = slidingRight ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
          } else {
            beginOffset = slidingRight ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
          }

          return SlideTransition(
            position: animation.drive(Tween<Offset>(begin: beginOffset, end: Offset.zero)),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey<int>(_indiceAtual),
          child: _paginas[_indiceAtual],
        ),
      ),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _indiceAtual,
        items: items,
        onTap: (index) {
          if (index != _indiceAtual) {
            setState(() {
              _indiceAnterior = _indiceAtual;
              _indiceAtual = index;
            });
          }
        },
      ),
    );
  }
}