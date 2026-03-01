import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- NOVO: Importação para pegar o ID do Personal
import 'theme/app_theme.dart';

class AlunosPage extends StatelessWidget {
  const AlunosPage({super.key});

  // --- FUNÇÃO PARA DELETAR DO BANCO ---
  Future<void> _deletarAluno(String id) async {
    await FirebaseFirestore.instance.collection('usuarios').doc(id).delete();
  }

  Future<void> _salvarAluno(
    BuildContext context,
    String nome,
    String email,
  ) async {
    if (nome.isEmpty || email.isEmpty) return;

    // <-- NOVO: Pegamos o ID único do Personal logado
    final String? personalId = FirebaseAuth.instance.currentUser?.uid;

    if (personalId == null) {
      debugPrint("Erro: Nenhum personal logado.");
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('usuarios').add({
        'nome': nome,
        'email': email,
        'tipoUsuario': 'aluno',
        'personalId':
            personalId, // <-- NOVO: Carimbamos o aluno com o ID do seu Personal!
        'dataCriacao': FieldValue.serverTimestamp(),
      });
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Erro ao salvar: $e");
    }
  }

  void _exibirModalCadastro(BuildContext context) {
    final nomeController = TextEditingController();
    final emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
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
    // <-- NOVO: Pegamos o ID do Personal para usar no filtro da consulta
    final String? personalId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _exibirModalCadastro(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .where('tipoUsuario', isEqualTo: 'aluno')
            .where(
              'personalId',
              isEqualTo: personalId,
            ) // <-- NOVO: O Firestore agora só traz os SEUS alunos!
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum aluno.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var aluno = doc.data() as Map<String, dynamic>;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) => _deletarAluno(doc.id),
                child: Card(
                  color: AppTheme.surfaceLight,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
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
