import '../treinos/treinos_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import 'home_page.dart'; // Importamos a nossa aba Home
import '../alunos/alunos_page.dart'; // Importamos a tela de Alunos
import '../../main.dart';

class DashboardPage extends StatefulWidget {
  final String userType;
  const DashboardPage({super.key, required this.userType});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _indiceAtual = 0; // Controla qual aba está ativa

  // Lista das telas que serão exibidas
  final List<Widget> _paginas = [
    const HomePage(),
    const AlunosPage(), // Agora exibe a tela real de alunos
    const TreinosPage(),
    const Center(
      child: Text('Configurações', style: TextStyle(color: Colors.white)),
    ),
  ];

  Future<void> _sair(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ChecagemPagina()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user?.uid)
              .get(),
          builder: (context, snapshot) {
            String nome = "Treinador";
            if (snapshot.hasData && snapshot.data!.exists) {
              nome = snapshot.data!.get('nome').toString().split(' ')[0];
            }
            return Text(
              'Olá, $nome',
              style: const TextStyle(fontWeight: FontWeight.bold),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.primary),
            onPressed: () => _sair(context),
          ),
        ],
        automaticallyImplyLeading: false,
      ),

      // O corpo agora muda dependendo do ícone clicado na barra!
      body: _paginas[_indiceAtual],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: (index) {
          setState(() {
            _indiceAtual = index;
          });
        },
        type: BottomNavigationBarType.fixed, // Mantém os nomes sempre visíveis
        backgroundColor: AppTheme.surfaceDark,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Alunos'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Treinos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
