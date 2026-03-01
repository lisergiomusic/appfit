import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';

class TreinosPage extends StatelessWidget {
  const TreinosPage({super.key});

  // --- FUNÇÃO PARA SALVAR O TREINO NO BANCO ---
  Future<void> _salvarTreino(
    BuildContext context,
    String titulo,
    String descricao,
  ) async {
    if (titulo.isEmpty) return;

    final String? personalId = FirebaseAuth.instance.currentUser?.uid;

    if (personalId == null) {
      debugPrint("Erro: Nenhum personal logado.");
      return;
    }

    try {
      // Criamos uma nova coleção chamada 'treinos'
      await FirebaseFirestore.instance.collection('treinos').add({
        'titulo': titulo,
        'descricao': descricao,
        'personalId': personalId, // <-- Segurança garantida: o treino é seu!
        'dataCriacao': FieldValue.serverTimestamp(),
      });
      if (context.mounted) Navigator.pop(context); // Fecha o modal
    } catch (e) {
      debugPrint("Erro ao salvar treino: $e");
    }
  }

  // --- MODAL PARA CRIAR O TREINO ---
  void _exibirModalNovoTreino(BuildContext context) {
    final tituloController = TextEditingController();
    final descricaoController = TextEditingController();

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
              'Nova Ficha de Treino',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: tituloController,
              decoration: const InputDecoration(
                labelText: 'Nome do Treino (ex: Ficha A - Peito)',
                prefixIcon: Icon(Icons.fitness_center),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição (ex: Foco em hipertrofia)',
                prefixIcon: Icon(Icons.description),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _salvarTreino(
                context,
                tituloController.text,
                descricaoController.text,
              ),
              child: const Text('Salvar Treino'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // --- FUNÇÃO PARA DELETAR TREINO ---
  Future<void> _deletarTreino(String id) async {
    await FirebaseFirestore.instance.collection('treinos').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final String? personalId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Biblioteca de Treinos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _exibirModalNovoTreino(context), // <-- Agora abre o Modal!
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Buscamos apenas os treinos criados por ESTE personal
        stream: FirebaseFirestore.instance
            .collection('treinos')
            .where('personalId', isEqualTo: personalId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Se não tiver nenhum treino, mostramos aquela tela bonita vazia
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 80,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nenhum treino na biblioteca.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Clique no botão + para criar sua primeira ficha.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Se tiver treinos, mostramos a lista!
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var treino = doc.data() as Map<String, dynamic>;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: AppTheme.surfaceDark,
                        title: const Text(
                          "Confirmar exclusão",
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          "Tem certeza que deseja excluir este treino?",
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text(
                              "Cancelar",
                              style: TextStyle(color: AppTheme.primary),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              "Excluir",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
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
                onDismissed: (direction) => _deletarTreino(doc.id),
                child: Card(
                  color: AppTheme.surfaceLight,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: AppTheme.primary,
                      ),
                    ),
                    title: Text(
                      treino['titulo'] ?? 'Sem título',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      treino['descricao'] ?? '',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.textSecondary,
                    ),
                    onTap: () {
                      // Em breve: Abrir os exercícios deste treino!
                    },
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
