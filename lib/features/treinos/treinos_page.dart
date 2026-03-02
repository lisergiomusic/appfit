import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import 'criar_rotina_page.dart'; // <-- AGORA USAMOS A NOSSA TELA SÊNIOR!
import 'rotina_detalhe_page.dart';

class TreinosPage extends StatelessWidget {
  const TreinosPage({super.key});

  // --- FUNÇÃO PARA DELETAR ROTINA DA BIBLIOTECA ---
  Future<void> _deletarTreino(String id) async {
    await FirebaseFirestore.instance.collection('rotinas').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final String? personalId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Biblioteca de Treinos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      // --- O FAB AGORA ABRE A NOSSA TELA PREMIUM DE CRIAR ROTINA ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              // Sem passar alunoId, ela entende que é um "Template" da Biblioteca!
              builder: (context) => const CriarRotinaPage(),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Novo Template',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Buscamos as ROTINAS (nova coleção) que são TEMPLATES (alunoId nulo) do Personal logado
        stream: FirebaseFirestore.instance
            .collection('rotinas')
            .where('personalId', isEqualTo: personalId)
            .where(
              'alunoId',
              isNull: true,
            ) // <-- Garante que traz apenas os genéricos da biblioteca
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          // Se não tiver nenhum treino, mostramos a tela de "Empty State"
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dashboard_customize_outlined,
                    size: 80,
                    color: AppTheme.textSecondary.withAlpha(100),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sua biblioteca está vazia.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Crie templates para enviar rapidamente\naos seus alunos no futuro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }

          // Se tiver treinos, mostramos a lista premium!
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              80,
            ), // Padding extra no fundo para não bater no FAB
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var rotina = doc.data() as Map<String, dynamic>;

              // Calcula quantas sessões este template tem (se a chave existir)
              int qtdSessoes = rotina['sessoes'] != null
                  ? (rotina['sessoes'] as List).length
                  : 0;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: AppTheme.surfaceDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          "Confirmar exclusão",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: const Text(
                          "Tem certeza que deseja excluir este template da sua biblioteca?",
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text(
                              "Cancelar",
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              "Excluir",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withAlpha(10)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withAlpha(50),
                        ),
                      ),
                      child: const Icon(
                        Icons.collections_bookmark,
                        color: AppTheme.primary,
                      ),
                    ),
                    title: Text(
                      rotina['nome'] ?? 'Sem título',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Template • $qtdSessoes sessões',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.textSecondary,
                    ),
                    onTap: () {
                      // <-- AQUI FOI CORRIGIDO: Passando o JSON completo como na arquitetura nova
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RotinaDetalhePage(
                            rotinaData:
                                rotina, // A magia do Single Source of Truth
                          ),
                        ),
                      );
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
