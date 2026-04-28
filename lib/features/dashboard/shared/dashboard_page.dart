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

  late final List<Widget> _paginas;

  @override
  void initState() {
    super.initState();
    final uid = _authService.currentUser?.id ?? '';
    final isAluno = widget.userType == 'aluno';

    _paginas = isAluno
        ? [
            AlunoHomePage(uid: uid),
            const Center(
              child: Text(
                'Meu Treino — em breve',
                style: TextStyle(color: AppColors.labelSecondary),
              ),
            ),
            AlunoHistoricoPage(uid: uid),
            AlunoContaPage(uid: uid),
          ]
        : [
            PersonalHomePage(
              onNovoAlunoTap: _abrirCadastroAlunoPeloAtalhoHome,
              onCriarRotinaTap: _abrirCriacaoRotinaPeloAtalhoHome,
            ),
            const PersonalAlunosPage(openCadastroOnLoad: false),
            const PersonalTreinosPage(openCriarRotinaOnLoad: false),
            PersonalContaPage(uid: uid),
          ];
  }

  void _abrirCadastroAlunoPeloAtalhoHome() {
    setState(() => _indiceAtual = 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final page = _paginas[1];
      if (page is PersonalAlunosPage) {
        setState(() {
          _paginas[1] = const PersonalAlunosPage(openCadastroOnLoad: true);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _paginas[1] = const PersonalAlunosPage(openCadastroOnLoad: false);
          });
        });
      }
    });
  }

  void _abrirCriacaoRotinaPeloAtalhoHome() {
    setState(() => _indiceAtual = 2);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _paginas[2] = const PersonalTreinosPage(openCriarRotinaOnLoad: true);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _paginas[2] = const PersonalTreinosPage(openCriarRotinaOnLoad: false);
        });
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    final isAluno = widget.userType == 'aluno';

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
      body: IndexedStack(index: _indiceAtual, children: _paginas),
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