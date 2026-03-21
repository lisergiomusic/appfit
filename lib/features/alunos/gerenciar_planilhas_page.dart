import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../treinos/rotina_detalhe_page.dart';
import '../treinos/treinos_page.dart';
import 'widgets/aluno_header_section.dart';

/// Tela responsável por gerenciar as planilhas de um aluno específico.
/// Permite visualizar planilhas ativas, programadas e o histórico.
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

  /// Exibe as opções para adicionar uma nova planilha (do zero ou biblioteca).
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nova Planilha',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RotinaDetalhePage(
                      alunoId: alunoId,
                      alunoNome: alunoNome,
                    ),
                  ),
                );
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_rounded, color: AppTheme.primary),
              ),
              title: const Text('Criar do zero', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Comece uma planilha em branco', style: TextStyle(color: AppTheme.textSecondary)),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ),
            const Divider(color: Colors.white10, height: 32),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TreinosPage(
                      alunoId: alunoId,
                      alunoNome: alunoNome,
                    ),
                  ),
                );
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.iosBlue.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.collections_bookmark_rounded, color: AppTheme.iosBlue),
              ),
              title: const Text('Usar da Biblioteca', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Escolha um template pronto', style: TextStyle(color: AppTheme.textSecondary)),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('ADICIONAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, letterSpacing: 1)),
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

          /// Ordenação manual: planilhas mais recentes primeiro (dataCriacao desc).
          final planilhas = allDocs.toList()
            ..sort((a, b) {
              final da = (a.data() as Map<String, dynamic>)['dataCriacao'] as Timestamp?;
              final db = (b.data() as Map<String, dynamic>)['dataCriacao'] as Timestamp?;
              if (da == null) return 1;
              if (db == null) return -1;
              return db.compareTo(da);
            });

          /// Filtros para separação das seções na UI.
          final ativa = planilhas.where((doc) => (doc.data() as Map<String, dynamic>)['ativa'] == true).toList();
          final historico = planilhas.where((doc) => (doc.data() as Map<String, dynamic>)['ativa'] != true).toList();

          /// Mocks temporários para visualização durante o desenvolvimento.
          /// Devem ser removidos após a implementação completa das flags no Firestore.
          final List<Map<String, dynamic>> mockHistorico = [
            {
              'nome': 'Treino Verão 2023',
              'dataCriacao': Timestamp.fromDate(DateTime(2023, 11, 10)),
              'ativa': false,
            },
            {
              'nome': 'Foco em Hipertrofia v2',
              'dataCriacao': Timestamp.fromDate(DateTime(2024, 01, 15)),
              'ativa': false,
            }
          ];

          final List<Map<String, dynamic>> mockFuturas = [
            {
              'nome': 'Pós-Carnaval 2026',
              'dataCriacao': Timestamp.fromDate(DateTime.now().add(const Duration(days: 45))),
              'dataVencimento': Timestamp.fromDate(DateTime.now().add(const Duration(days: 75))),
              'ativa': false,
              'isProgramada': true,
              'tipoVencimento': 'data',
            }
          ];

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column (
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              AlunoHeaderSection(
                alunoId: alunoId,
                alunoNome: alunoNome,
                photoUrl: photoUrl,
                idade: idade,
                peso: peso,
              ),

              const SizedBox(height: 32),

              if (planilhas.isEmpty && mockHistorico.isEmpty && mockFuturas.isEmpty) ...[
                _buildEmptyState(),
              ] else ...[
                /// Seção de Planilha Ativa: Apenas uma deve estar marcada como 'ativa: true'.
                if (ativa.isNotEmpty) ...[
                  _buildSectionLabel('PLANILHA ATIVA'),
                  const SizedBox(height: 12),
                  ...ativa.map((d) => _buildPlanilhaItem(context, d.data() as Map<String, dynamic>, d.id, isAtiva: true)),
                  const SizedBox(height: 32),
                ],

                /// Seção de Planilhas Futuras: Planilhas com data de início posterior a hoje.
                _buildSectionLabel('PLANILHAS FUTURAS'),
                const SizedBox(height: 12),
                ...mockFuturas.map((m) => _buildPlanilhaItem(context, m, 'mock_f', isProgramada: true)),
                const SizedBox(height: 32),

                /// Seção de Histórico: Planilhas finalizadas ou inativas.
                if (historico.isNotEmpty || mockHistorico.isNotEmpty) ...[
                  _buildSectionLabel('HISTÓRICO'),
                  const SizedBox(height: 12),
                  ...historico.map((d) => _buildPlanilhaItem(context, d.data() as Map<String, dynamic>, d.id)),
                  ...mockHistorico.map((m) => _buildPlanilhaItem(context, m, 'mock_h')),
                ],
              ],
            ],
            )
          );
        },
      ),
    );
  }

  /// Constrói o label do cabeçalho de cada seção (ex: HISTÓRICO).
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.textSectionHeaderDark,
          ),
        ],
      ),
    );
  }

  /// Renderiza o card individual de cada planilha.
  /// Calcula o progresso e a legenda baseada no tipo de vencimento (sessões ou data).
  Widget _buildPlanilhaItem(BuildContext context, Map<String, dynamic> data, String id, {bool isAtiva = false, bool isProgramada = false}) {
    String legenda = '';
    double progresso = 0.0;

    if (isAtiva) {
      if (data['tipoVencimento'] == 'sessoes') {
        int total = data['vencimentoSessoes'] ?? 1;
        int concluidas = data['sessoesConcluidas'] ?? 0;
        progresso = (concluidas / total).clamp(0.0, 1.0);
        legenda = '$concluidas de $total treinos realizados';
      } else {
        DateTime hoje = DateTime.now();
        DateTime criacao = (data['dataCriacao'] as Timestamp?)?.toDate() ?? hoje;
        DateTime venc = (data['dataVencimento'] as Timestamp?)?.toDate() ?? hoje.add(const Duration(days: 30));
        int total = venc.difference(criacao).inDays;
        progresso = (hoje.difference(criacao).inDays / (total > 0 ? total : 1)).clamp(0.0, 1.0);
        legenda = 'Vence em ${DateFormat('dd/MM').format(venc)}';
      }
    } else if (isProgramada) {
      DateTime dataC = (data['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now();
      legenda = 'Inicia em ${DateFormat('dd/MM').format(dataC)}';
    } else {
      DateTime dataC = (data['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now();
      legenda = 'Criada em ${DateFormat('dd/MM/yyyy').format(dataC)}';
    }

    final Color statusColor = isAtiva ? AppTheme.primary : (isProgramada ? AppTheme.iosBlue : AppTheme.textSecondary);
    final IconData icon = isAtiva ? Icons.fitness_center_rounded : (isProgramada ? Icons.calendar_today_rounded : Icons.history_rounded);

    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navegarParaDetalhes(context, data, id),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: statusColor, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['nome'] ?? 'Planilha',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              legenda,
                              style: TextStyle(
                                color: AppTheme.textSecondary.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary, size: 12),
                    ],
                  ),
                ),
                if (isAtiva)
                  Container(
                    height: 2,
                    width: double.infinity,
                    color: Colors.white.withValues(alpha: 0.05),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progresso,
                      child: Container(color: AppTheme.primary),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Exibe estado vazio caso não existam planilhas vinculadas.
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

  /// Navega para a página de detalhes da rotina.
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