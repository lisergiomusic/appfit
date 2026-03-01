import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/app_theme.dart';

class AlunosPage extends StatelessWidget {
  const AlunosPage({super.key});

  // --- FUNÇÃO PARA SALVAR NO BANCO ---
  Future<void> _salvarAluno(
    BuildContext context,
    String nome,
    String email,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').add({
        'nome': nome,
        'email': email,
        'tipoUsuario': 'aluno',
        'dataCriacao': FieldValue.serverTimestamp(),
      });

      if (context.mounted) Navigator.pop(context); // Fecha o modal
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- O MODAL QUE DESLIZA (BOTTOM SHEET) ---
  void _exibirModalCadastro(BuildContext context) {
    final nomeController = TextEditingController();
    final emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que o modal suba com o teclado
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(
            context,
          ).viewInsets.bottom, // Ajuste para o teclado
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Novo Aluno',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Aluno',
                prefixIcon: Icon(Icons.person),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email),
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _salvarAluno(
                context,
                nomeController.text,
                emailController.text,
              ),
              child: const Text('Cadastrar Aluno'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _exibirModalCadastro(context), // Agora o botão funciona!
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .where('tipoUsuario', isEqualTo: 'aluno')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum aluno cadastrado.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var aluno = snapshot.data!.docs[index];
              return Card(
                color: AppTheme.surfaceLight,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: Text(
                      aluno['nome'][0],
                      style: const TextStyle(color: AppTheme.primary),
                    ),
                  ),
                  title: Text(
                    aluno['nome'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    aluno['email'],
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
