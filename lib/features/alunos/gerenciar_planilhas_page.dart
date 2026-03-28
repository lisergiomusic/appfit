import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../treinos/rotina_detalhe_page.dart';
import '../treinos/treinos_page.dart';
import 'widgets/aluno_header_section.dart';
import '../../core/services/aluno_service.dart';

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
  String? _idPlanilhaExpandida;
  late final Stream<QuerySnapshot> _planilhasStream;
  final AlunoService _alunoService = AlunoService();

  @override
  void initState() {
    super.initState();
    _planilhasStream = _alunoService.getPlanilhasStream(widget.alunoId);
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,

                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Nova Planilha',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
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
              icon: Icons.add_rounded,
              color: AppTheme.primary,
              title: 'Criar do zero',
              subtitle: 'Comece uma planilha personalizada agora',
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
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
              icon: Icons.auto_awesome_motion_rounded,
              color: AppTheme.iosBlue,
              title: 'Usar da Biblioteca',
              subtitle: 'Escolha um template pronto e economize tempo',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.2)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<QuerySnapshot>(
        stream: _planilhasStream,
        builder: (context, snapshot) {
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

          // Mock data for visual completeness as requested by user's original code
          final List<Map<String, dynamic>> mockHistorico = [
            {'nome': 'Ciclo de Força 2024', 'dataCriacao': Timestamp.fromDate(DateTime(2024, 02, 10)), 'ativa': false},
            {'nome': 'Hipertrofia ABC', 'dataCriacao': Timestamp.fromDate(DateTime(2023, 12, 05)), 'ativa': false}
          ];
          final List<Map<String, dynamic>> mockFuturas = [
            {
              'nome': 'Preparação Verão',
              'dataCriacao': Timestamp.fromDate(DateTime.now().add(const Duration(days: 15))),
              'ativa': false,
              'isProgramada': true,
            }
          ];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                pinned: true,
                backgroundColor: AppTheme.background,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                centerTitle: true,
                title: const Text(
                  'PLANILHAS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    AlunoHeaderSection(
                      alunoId: widget.alunoId,
                      alunoNome: widget.alunoNome,
                      photoUrl: widget.photoUrl,
                      idade: widget.idade,
                      peso: widget.peso,
                    ),
                    const SizedBox(height: 40),

                    if (ativa.isNotEmpty) ...[
                      _buildSectionLabel('EM CURSO'),
                      const SizedBox(height: 16),
                      ...ativa.map((d) => _buildPlanilhaItem(context, d.data() as Map<String, dynamic>, d.id, isAtiva: true)),
                      const SizedBox(height: 32),
                    ],

                    _buildSectionLabel('Planejadas'),
                    const SizedBox(height: 16),
                    ...mockFuturas.map((m) => _buildPlanilhaItem(context, m, 'mock_f', isProgramada: true)),
                    const SizedBox(height: 32),

                    _buildSectionLabel('Anteriores'),
                    const SizedBox(height: 16),
                    ...historico.map((d) => _buildPlanilhaItem(context, d.data() as Map<String, dynamic>, d.id)),
                    ...mockHistorico.map((m) => _buildPlanilhaItem(context, m, 'mock_${m['nome']}')),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        icon: const Icon(Icons.add_rounded, color: Colors.black, size: 24),
        label: const Text(
          'Nova planilha',
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        label,
        style: AppTheme.textSectionHeaderDark,
      ),
    );
  }

  Widget _buildPlanilhaItem(BuildContext context, Map<String, dynamic> data, String id, {bool isAtiva = false, bool isProgramada = false}) {
    final bool isExpanded = _idPlanilhaExpandida == id;
    String statusLabel = '';
    String infoLabel = '';
    double progress = 0.0;

    if (isAtiva) {
      statusLabel = 'ATIVA';
      if (data['tipoVencimento'] == 'sessoes') {
        int total = data['vencimentoSessoes'] ?? 1;
        int concluidas = data['sessoesConcluidas'] ?? 0;
        progress = (concluidas / total).clamp(0.0, 1.0);
        infoLabel = '$concluidas / $total treinos';
      } else {
        DateTime hoje = DateTime.now();
        DateTime criacao = (data['dataCriacao'] as Timestamp?)?.toDate() ?? hoje;
        DateTime venc = (data['dataVencimento'] as Timestamp?)?.toDate() ?? hoje.add(const Duration(days: 30));
        int totalDays = venc.difference(criacao).inDays;
        progress = (hoje.difference(criacao).inDays / (totalDays > 0 ? totalDays : 1)).clamp(0.0, 1.0);
        infoLabel = 'Vence em ${DateFormat('dd/MM').format(venc)}';
      }
    } else if (isProgramada) {
      statusLabel = 'AGENDADA';
      DateTime dataC = (data['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now();
      infoLabel = 'Inicia ${DateFormat('dd/MM').format(dataC)}';
    } else {
      statusLabel = 'FINALIZADA';
      DateTime dataC = (data['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now();
      infoLabel = DateFormat('dd MMM yyyy').format(dataC);
    }

    final Color accentColor = isAtiva ? AppTheme.primary : (isProgramada ? AppTheme.iosBlue : AppTheme.textSecondary);

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        splashColor: AppTheme.splash.withAlpha(50),
        highlightColor: AppTheme.splash.withAlpha(30),
        onTap: () => setState(() => _idPlanilhaExpandida = isExpanded ? null : id),
        child: Column(
          children: [
            Padding(
              padding: AppTheme.edgeInsetsSmall,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 56,
                      height: 56,
                      color: Colors.black.withAlpha(40),


                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isAtiva)
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                backgroundColor: accentColor.withValues(alpha: 0.1),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                          Icon(
                            isAtiva ? Icons.bolt_rounded : (isProgramada ? Icons.calendar_today_rounded : Icons.history_rounded),
                            color: accentColor,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!isAtiva && !isProgramada)
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              infoLabel,
                              style: TextStyle(
                                color: AppTheme.textSecondary.withValues(alpha: 0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (data['nome'] ?? 'Planilha'),
                          style: AppTheme.cardTitle,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Column(
                      children: [
                        Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildActionBtn(
                                  label: 'EDITAR',
                                  icon: Icons.edit_note_rounded,
                                  onTap: () => _navegarParaDetalhes(context, data, id),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionBtn(
                                  label: 'STATS',
                                  icon: Icons.bar_chart_rounded,
                                  onTap: () {},
                                  disabled: isProgramada,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionBtn(
                                  label: isAtiva ? 'PAUSAR' : 'ATIVAR',
                                  icon: isAtiva ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: isAtiva ? Colors.orangeAccent : AppTheme.primary,
                                  onTap: () {},
                                ),
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

  Widget _buildActionBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
    bool disabled = false,
  }) {
    final finalColor = disabled ? Colors.white.withValues(alpha: 0.1) : color;
    return Material(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: finalColor, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: finalColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navegarParaDetalhes(BuildContext context, Map<String, dynamic> data, String id) {
    if (id.startsWith('mock')) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RotinaDetalhePage(
          rotinaData: data,
          rotinaId: id,
          alunoId: widget.alunoId,
          alunoNome: widget.alunoNome,
        ),
      ),
    );
  }
}