import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../treinos/rotina_detalhe_page.dart';

class GerenciarPlanilhasPage extends StatelessWidget {
  final String alunoId;
  final String alunoNome;
  final String? photoUrl;
  final String peso;
  final String idade;

  const GerenciarPlanilhasPage({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    required this.photoUrl,
    required this.peso,
    required this.idade
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Gerenciar Planilhas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withAlpha(0),
                  Colors.white.withAlpha(25),
                  Colors.white.withAlpha(0),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rotinas')
            .where('alunoId', isEqualTo: alunoId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final allDocs = snapshot.data?.docs ?? [];

          final planilhas = allDocs.toList()
            ..sort((a, b) {
              final da = (a.data() as Map<String, dynamic>)['dataCriacao'] as Timestamp?;
              final db = (b.data() as Map<String, dynamic>)['dataCriacao'] as Timestamp?;
              if (da == null) return 1;
              if (db == null) return -1;
              return db.compareTo(da);
            });

          final ativa = planilhas.where((doc) => (doc.data() as Map<String, dynamic>)['ativa'] == true).toList();
          final historico = planilhas.where((doc) => (doc.data() as Map<String, dynamic>)['ativa'] != true).toList();

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'avatar_$alunoId',
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // ADICIONE A LINHA ABAIXO:
                        image: photoUrl != null && photoUrl!.isNotEmpty
                            ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover)
                            : null,
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: photoUrl == null || photoUrl!.isEmpty
                          ? Center( // Adicionei um Center para o texto ficar alinhado
                        child: Text(
                          alunoNome.isNotEmpty ? alunoNome[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 24, // Diminuí um pouco para caber melhor no círculo
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          ),
                        ),
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alunoNome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Gerenciando planilhas',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              if (planilhas.isEmpty) ...[
                _buildEmptyState(),
              ] else ...[
                if (ativa.isNotEmpty) ...[
                  Text('PLANILHA ATIVA', style: AppTheme.textSectionHeaderDark),
                  const SizedBox(height: 16),
                  ...ativa.map((d) => _buildPlanilhaAtivaCard(context, d)),
                  const SizedBox(height: 32),
                ],
                if (historico.isNotEmpty) ...[
                  Text('PLANILHAS CONCLUIDAS', style: AppTheme.textSectionHeaderDark),
                  const SizedBox(height: 16),
                  ...historico.map((d) => _buildPlanilhaHistoricoCard(context, d)),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlanilhaAtivaCard(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Lógica de progresso idêntica à PerfilAlunoPage
    String tipoVencimento = data['tipoVencimento'] ?? 'data';
    double progressoAtual = 0.0;
    String legendaVencimento = '';

    if (tipoVencimento == 'sessoes') {
      int totalSessoes = data['vencimentoSessoes'] ?? 1;
      int concluidas = data['sessoesConcluidas'] ?? 0;
      progressoAtual = (concluidas / totalSessoes).clamp(0.0, 1.0);
      legendaVencimento = '$concluidas de $totalSessoes treinos realizados';
    } else {
      DateTime hoje = DateTime.now();
      DateTime dataCriacao = (data['dataCriacao'] as Timestamp?)?.toDate() ?? hoje;
      DateTime dataVencimento = (data['dataVencimento'] as Timestamp?)?.toDate() ?? hoje.add(const Duration(days: 30));

      int totalDias = dataVencimento.difference(dataCriacao).inDays;
      if (totalDias <= 0) totalDias = 1;
      int diasPassados = hoje.difference(dataCriacao).inDays;
      progressoAtual = (diasPassados / totalDias).clamp(0.0, 1.0);
      legendaVencimento = 'Vence em ${DateFormat('dd/MM').format(dataVencimento)}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceDark,
            AppTheme.surfaceDark.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _navegarParaDetalhes(context, data, doc.id),
          splashColor: AppTheme.primary.withValues(alpha: 0.1),
          highlightColor: AppTheme.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.fitness_center_rounded, color: AppTheme.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['nome'] ?? 'Planilha de Treino',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            legendaVencimento,
                            style: TextStyle(
                              color: AppTheme.textSecondary.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: AppTheme.primary, size: 14),
                  ],
                ),
                const SizedBox(height: 24),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progressoAtual,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanilhaHistoricoCard(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final dataCriacao = (data['dataCriacao'] as Timestamp?)?.toDate();
    final String dataFormatada = dataCriacao != null
        ? DateFormat('dd/MM/yyyy').format(dataCriacao)
        : '--/--/----';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navegarParaDetalhes(context, data, doc.id),
          splashColor: AppTheme.primary.withValues(alpha: 0.12),
          highlightColor: AppTheme.primary.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.history_rounded, color: AppTheme.textSecondary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['nome'] ?? 'Planilha Antiga',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Criada em $dataFormatada',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary, size: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.description_outlined,
            size: 40,
            color: AppTheme.textSecondary.withValues(alpha: 0.2)
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Nenhuma planilha encontrada',
          style: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _navegarParaDetalhes(BuildContext context, Map<String, dynamic> data, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RotinaDetalhePage(
          rotinaData: data,
          rotinaId: id,
          alunoId: alunoId,
          alunoNome: alunoNome,
        ),
      ),
    );
  }
}