import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../treinos/rotina_detalhe_page.dart';
import '../treinos/treinos_page.dart';
import 'widgets/aluno_header_section.dart';

class GerenciarPlanilhasPage extends StatefulWidget {
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
    required this.idade,
  });

  @override
  State<GerenciarPlanilhasPage> createState() => _GerenciarPlanilhasPageState();
}

class _GerenciarPlanilhasPageState extends State<GerenciarPlanilhasPage> {
  // Variável para controlar qual card está expandido
  String? _idPlanilhaExpandida;

  // Stream declarada aqui para evitar flickering no build
  late final Stream<QuerySnapshot> _planilhasStream;

  @override
  void initState() {
    super.initState();
    _planilhasStream = FirebaseFirestore.instance
        .collection('rotinas')
        .where('alunoId', isEqualTo: widget.alunoId)
        .snapshots();
  }

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
                      alunoId: widget.alunoId,
                      alunoNome: widget.alunoNome,
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
              title: const Text('Criar do zero',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Comece uma planilha em branco',
                  style: TextStyle(color: AppTheme.textSecondary)),
              trailing:
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ),
            const Divider(color: Colors.white10, height: 32),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TreinosPage(
                      alunoId: widget.alunoId,
                      alunoNome: widget.alunoNome,
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
                child: const Icon(Icons.collections_bookmark_rounded,
                    color: AppTheme.iosBlue),
              ),
              title: const Text('Usar da Biblioteca',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Escolha um template pronto',
                  style: TextStyle(color: AppTheme.textSecondary)),
              trailing:
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        backgroundColor: AppTheme.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _planilhasStream,
        builder: (context, snapshot) {
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

          final List<Map<String, dynamic>> mockHistorico = [
            {'nome': 'Treino Verão 2023', 'dataCriacao': Timestamp.fromDate(DateTime(2023, 11, 10)), 'ativa': false},
            {'nome': 'Foco em Hipertrofia v2', 'dataCriacao': Timestamp.fromDate(DateTime(2024, 01, 15)), 'ativa': false}
          ];

          final List<Map<String, dynamic>> mockFuturas = [
            {
              'nome': 'Pós-Carnaval 2026',
              'dataCriacao': Timestamp.fromDate(DateTime.now().add(const Duration(days: 45))),
              'ativa': false,
              'isProgramada': true,
            }
          ];

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                AlunoHeaderSection(
                  alunoId: widget.alunoId,
                  alunoNome: widget.alunoNome,
                  photoUrl: widget.photoUrl,
                  idade: widget.idade,
                  peso: widget.peso,
                ),
                const SizedBox(height: 32),

                if (ativa.isNotEmpty) ...[
                  _buildSectionLabel('PLANILHA ATIVA'),
                  const SizedBox(height: 16),
                  ...ativa.map((d) => _buildPlanilhaItem(context, d.data() as Map<String, dynamic>, d.id, isAtiva: true)),
                  const SizedBox(height: 32),
                ],

                _buildSectionLabel('PLANILHAS FUTURAS'),
                const SizedBox(height: 16),
                ...mockFuturas.map((m) => _buildPlanilhaItem(context, m, 'mock_f', isProgramada: true)),
                const SizedBox(height: 32),

                _buildSectionLabel('HISTÓRICO'),
                const SizedBox(height: 16),
                ...historico.map((d) => _buildPlanilhaItem(context, d.data() as Map<String, dynamic>, d.id)),
                ...mockHistorico.map((m) => _buildPlanilhaItem(context, m, 'mock_${m['nome']}')),

                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(width: 4, height: 14, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(label, style: AppTheme.textSectionHeaderDark.copyWith(color: Colors.white.withValues(alpha: 0.9), letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildPlanilhaItem(BuildContext context, Map<String, dynamic> data, String id, {bool isAtiva = false, bool isProgramada = false}) {
    final bool isExpanded = _idPlanilhaExpandida == id;
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
      legenda = 'Finalizada em ${DateFormat('dd/MM/yyyy').format(dataC)}';
    }

    final Color statusColor = isAtiva ? AppTheme.primary : (isProgramada ? AppTheme.iosBlue : AppTheme.textSecondary);

    return AnimatedContainer(
      key: ValueKey('card_$id'),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isExpanded
              ? AppTheme.primary.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          setState(() {
            _idPlanilhaExpandida = isExpanded ? null : id;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAtiva)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: LinearProgressIndicator(
                  value: progresso,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  minHeight: 4,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      isAtiva ? Icons.fitness_center : (isProgramada ? Icons.calendar_today : Icons.history),
                      color: statusColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (data['nome'] ?? 'Planilha').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          legenda,
                          style: TextStyle(
                            color: AppTheme.textSecondary.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.expand_more, color: Colors.white24),
                  ),
                ],
              ),
            ),

            // AnimatedSize substitui o AnimatedCrossFade para uma transição de altura muito mais fluida
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Column(
                children: [
                  Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          icon: Icons.edit_note_rounded,
                          label: 'DETALHES',
                          color: Colors.white70,
                          onTap: () => _navegarParaDetalhes(context, data, id),
                        ),
                        _buildActionButton(
                          icon: Icons.auto_graph_rounded,
                          label: 'EVOLUÇÃO',
                          color: isProgramada ? Colors.white24 : AppTheme.primary,
                          onTap: () {
                            if (isProgramada) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Disponível após o início do treino'), behavior: SnackBarBehavior.floating),
                              );
                            }
                          },
                        ),
                        _buildActionButton(
                          icon: isAtiva ? Icons.pause_circle : Icons.play_circle,
                          label: isAtiva ? 'PAUSAR' : 'ATIVAR',
                          color: isAtiva ? Colors.orangeAccent : AppTheme.primary,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  void _navegarParaDetalhes(BuildContext context, Map<String, dynamic> data, String id) {
    if (id.startsWith('mock')) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => RotinaDetalhePage(rotinaData: data, rotinaId: id, alunoId: widget.alunoId, alunoNome: widget.alunoNome)));
  }
}