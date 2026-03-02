import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../treinos/detalhe_treino_page.dart';
import 'gerenciar_aluno_page.dart';

class PerfilAlunoPage extends StatelessWidget {
  final String alunoId;
  final String alunoNome;

  const PerfilAlunoPage({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  // --- LÓGICA DE BANCO DE DADOS ---

  Future<void> _atribuirTreinoAoAluno(
    BuildContext context,
    String treinoId,
    String titulo,
    String descricao,
  ) async {
    try {
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Treino "$titulo" vinculado!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erro ao vincular: $e");
    }
  }

  void _exibirBibliotecaDeTreinos(BuildContext context) {
    final String? personalId = FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Sua Biblioteca',
                style: TextStyle(
                  fontSize: 22,
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
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      );
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Nenhum treino na biblioteca.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        var treino = doc.data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              treino['titulo'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              treino['descricao'] ?? '',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.add_circle,
                              color: AppTheme.primary,
                            ),
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
      ),
    );
  }

  // --- AÇÕES RÁPIDAS (Mock) ---

  void _chamarWhatsApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Em breve: Abrir conversa no WhatsApp!'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _alternarBloqueioAluno(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Em breve: Bloquear/Liberar acesso do aluno!'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // --- INTERFACE ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Gestão do Aluno',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons
                  .settings_outlined, // Mudei de edit para settings (engrenagem)
              color: AppTheme.textSecondary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GerenciarAlunoPage(
                    alunoId: alunoId,
                    alunoNome: alunoNome,
                  ),
                ),
              );
            },
            tooltip: 'Gerenciar Aluno',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER HORIZONTAL - FINO, ALINHADO E PREMIUM
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 36, // Tamanho padrão perfeito (72x72)
                    backgroundColor: AppTheme.surfaceLight,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment
                          .center, // Garante o alinhamento com a foto
                      children: [
                        Text(
                          alunoNome,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6), // Espaçamento suave
                        // LINHA DE STATUS: Idade + Ponto Verde + Ativo
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              '28 anos', // TODO: Fazer a idade vir do banco de dados
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                '•',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.success, // Bolinha de status
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Ativo',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Botão de WhatsApp em Destaque
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                onPressed: () => _chamarWhatsApp(context),
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                label: const Text(
                  'Chamar no WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success.withOpacity(0.15),
                  foregroundColor: AppTheme.success,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Ritmo da Semana
            _buildRitmoDaSemana(),

            const SizedBox(height: 32),

            // Hero Card da Ficha Atual
            _buildFichaAtivaHeroCard(context),

            const SizedBox(height: 24),

            // Menu Principal Restante
            _buildMenuOption(
              icon: Icons.calendar_month_outlined,
              title: 'Histórico de Feedbacks',
              onTap: () {},
            ),
            _buildMenuOption(
              icon: Icons.assignment_outlined,
              title: 'Avaliação Física',
              onTap: () {},
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildRitmoDaSemana() {
    final dias = [
      {'dia': 'Seg', 'status': 'feito'},
      {'dia': 'Ter', 'status': 'feito'},
      {'dia': 'Qua', 'status': 'feito'},
      {'dia': 'Qui', 'status': 'falta'},
      {'dia': 'Sex', 'status': 'feito'},
      {'dia': 'Sáb', 'status': 'futuro'},
      {'dia': 'Dom', 'status': 'futuro'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ritmo da Semana',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dias.map((d) {
              bool isFeito = d['status'] == 'feito';
              bool isFalta = d['status'] == 'falta';

              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isFeito
                          ? AppTheme.primary
                          : (isFalta
                                ? AppTheme.surfaceLight
                                : Colors.transparent),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isFeito
                            ? AppTheme.primary
                            : (isFalta
                                  ? Colors.redAccent.withOpacity(0.3)
                                  : AppTheme.textSecondary.withOpacity(0.1)),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isFeito
                            ? Icons.done
                            : (isFalta ? Icons.close : Icons.circle),
                        size: isFeito || isFalta ? 18 : 6,
                        color: isFeito
                            ? Colors.white
                            : (isFalta
                                  ? Colors.redAccent.withOpacity(0.8)
                                  : AppTheme.textSecondary.withOpacity(0.2)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    d['dia']!,
                    style: TextStyle(
                      color: isFeito ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isFeito ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // A JOGADA DE MESTRE DE UI/UX (O Hero Card Inteligente)
  Widget _buildFichaAtivaHeroCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(alunoId)
            .collection('treinos_atribuidos')
            .orderBy('dataAtribuicao', descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return InkWell(
              onTap: () => _exibirBibliotecaDeTreinos(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nenhuma Ficha Ativa',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Toque para vincular um treino',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          var treinoDoc = snapshot.data!.docs.first;
          var treino = treinoDoc.data() as Map<String, dynamic>;

          double progressoAtual = 0.85;
          bool alertaVencimento = progressoAtual >= 0.8;
          Color corProgresso = alertaVencimento
              ? Colors.orangeAccent
              : AppTheme.success;

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalheTreinoPage(
                    treinoId: treino['treinoIdOriginal'],
                    treinoTitulo: treino['titulo'],
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.surfaceDark,
                    AppTheme.surfaceLight.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt, size: 16, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'FICHA ATUAL',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _exibirBibliotecaDeTreinos(context),
                        child: const Text(
                          'Trocar',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    treino['titulo'] ?? 'Treino Personalizado',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Toque para ver os exercícios',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        alertaVencimento ? 'Vence em 3 dias' : 'Progresso',
                        style: TextStyle(
                          color: alertaVencimento
                              ? corProgresso
                              : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(progressoAtual * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressoAtual,
                      backgroundColor: Colors.black.withOpacity(0.3),
                      color: corProgresso,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = AppTheme.textSecondary,
    Color textColor = Colors.white,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.textSecondary,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}
