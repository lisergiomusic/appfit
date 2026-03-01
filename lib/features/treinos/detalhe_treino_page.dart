import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';

class DetalheTreinoPage extends StatelessWidget {
  final String treinoId;
  final String treinoTitulo;

  const DetalheTreinoPage({
    super.key,
    required this.treinoId,
    required this.treinoTitulo,
  });

  // --- SALVAR EXERCÍCIO NA SUBCOLEÇÃO ---
  Future<void> _salvarExercicio(
    BuildContext context,
    String nome,
    String series,
    String repeticoes,
  ) async {
    if (nome.isEmpty) return;

    try {
      // Repare no caminho: treinos -> ID do treino -> exercicios
      await FirebaseFirestore.instance
          .collection('treinos')
          .doc(treinoId)
          .collection('exercicios')
          .add({
            'nome': nome,
            'series': series,
            'repeticoes': repeticoes,
            'dataCriacao': FieldValue.serverTimestamp(),
          });
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Erro ao salvar exercício: $e");
    }
  }

  // --- DELETAR EXERCÍCIO ---
  Future<void> _deletarExercicio(String exercicioId) async {
    await FirebaseFirestore.instance
        .collection('treinos')
        .doc(treinoId)
        .collection('exercicios')
        .doc(exercicioId)
        .delete();
  }

  // --- MODAL DE EXERCÍCIO ---
  void _exibirModalNovoExercicio(BuildContext context) {
    final nomeController = TextEditingController();
    final seriesController = TextEditingController();
    final repeticoesController = TextEditingController();

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
              'Novo Exercício',
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
                labelText: 'Nome (ex: Supino Reto)',
                prefixIcon: Icon(Icons.fitness_center),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: seriesController,
                    decoration: const InputDecoration(
                      labelText: 'Séries (ex: 4)',
                      prefixIcon: Icon(Icons.repeat),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: repeticoesController,
                    decoration: const InputDecoration(
                      labelText: 'Reps (ex: 10 a 12)',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _salvarExercicio(
                context,
                nomeController.text,
                seriesController.text,
                repeticoesController.text,
              ),
              child: const Text('Adicionar Exercício'),
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
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          treinoTitulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _exibirModalNovoExercicio(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Buscamos a subcoleção de exercícios DESTE treino específico
        stream: FirebaseFirestore.instance
            .collection('treinos')
            .doc(treinoId)
            .collection('exercicios')
            .orderBy('dataCriacao') // Ordena pela ordem que você adicionou
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum exercício adicionado.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var exercicio = doc.data() as Map<String, dynamic>;

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
                onDismissed: (direction) => _deletarExercicio(doc.id),
                child: Card(
                  color: AppTheme.surfaceLight,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      exercicio['nome'] ?? 'Sem nome',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      '${exercicio['series']} séries  •  ${exercicio['repeticoes']} repetições',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
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
