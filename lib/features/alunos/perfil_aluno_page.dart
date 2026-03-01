import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';

class PerfilAlunoPage extends StatelessWidget {
  final String alunoId;
  final String alunoNome;

  const PerfilAlunoPage({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  // --- FUNÇÃO PARA VINCULAR O TREINO AO ALUNO ---
  Future<void> _atribuirTreinoAoAluno(
    BuildContext context,
    String treinoId,
    String titulo,
    String descricao,
  ) async {
    try {
      // Salva o treino na subcoleção 'treinos_atribuidos' dentro do documento do Aluno
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(alunoId)
          .collection('treinos_atribuidos')
          .add({
            'treinoIdOriginal': treinoId,
            'titulo': titulo,
            'descricao': descricao,
            'dataAtribuicao': FieldValue.serverTimestamp(),
          });

      if (context.mounted) {
        Navigator.pop(context); // Fecha o modal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Treino "$titulo" atribuído com sucesso!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erro ao atribuir treino: $e");
    }
  }

  // --- MODAL COM A BIBLIOTECA DE TREINOS ---
  void _exibirBibliotecaDeTreinos(BuildContext context) {
    final String? personalId = FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Escolher Ficha da Biblioteca',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('treinos')
                    .where('personalId', isEqualTo: personalId)
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
                        'Não tens treinos na tua biblioteca.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var treino = doc.data() as Map<String, dynamic>;

                      return Card(
                        color: AppTheme.surfaceLight,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(
                            Icons.fitness_center,
                            color: AppTheme.primary,
                          ),
                          title: Text(
                            treino['titulo'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            treino['descricao'] ?? '',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.add_circle,
                            color: AppTheme.primary,
                          ),
                          // Quando o personal clica, faz o "Match" no Firebase
                          onTap: () => _atribuirTreinoAoAluno(
                            context,
                            doc.id,
                            treino['titulo'],
                            treino['descricao'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- FUNÇÃO PARA REMOVER TREINO ATRIBUÍDO ---
  Future<void> _removerTreinoAtribuido(String idAtribuicao) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(alunoId)
        .collection('treinos_atribuidos')
        .doc(idAtribuicao)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          alunoNome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _exibirBibliotecaDeTreinos(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.fitness_center, color: Colors.white),
        label: const Text(
          'Atribuir Treino',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // A página agora "ouve" os treinos que pertencem especificamente a ESTE aluno
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(alunoId)
            .collection('treinos_atribuidos')
            .orderBy('dataAtribuicao', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_ind,
                    size: 80,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nenhum treino atribuído.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Clica no botão para vincular uma ficha a este aluno.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Fichas do Aluno',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var atribuicao = doc.data() as Map<String, dynamic>;

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
                      onDismissed: (direction) =>
                          _removerTreinoAtribuido(doc.id),
                      child: Card(
                        color: AppTheme.surfaceLight,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: AppTheme.success,
                            ),
                          ),
                          title: Text(
                            atribuicao['titulo'] ?? 'Sem título',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            atribuicao['descricao'] ?? '',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppTheme.textSecondary,
                          ),
                          onTap: () {
                            // No futuro: clicar aqui abrirá a ficha com os exercícios para ver/editar
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
