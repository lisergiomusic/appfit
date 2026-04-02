import 'package:appfit/core/widgets/app_bar_divider.dart';
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
      backgroundColor: AppColors.background,
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
              color: AppColors.primary,
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
              color: AppColors.iosBlue,
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
                        color: AppColors.labelSecondary.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: const Text('Gerenciar Planilhas', style: AppTheme.pageTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _planilhasStream,
      builder: (context, snapshot) {
        final allDocs = snapshot.data?.docs ?? [];
        final planilhas = allDocs.toList()
          ..sort((a, b) {
            final da =
                (a.data() as Map<String, dynamic>)['dataCriacao'] as Timestamp?;
            final db =
                (b.data() as Map<String, dynamic>)['dataCriacao'] as Timestamp?;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });

        final ativa = planilhas
            .where(
              (doc) => (doc.data() as Map<String, dynamic>)['ativa'] == true,
            )
            .toList();
        final historico = planilhas
            .where(
              (doc) => (doc.data() as Map<String, dynamic>)['ativa'] != true,
            )
            .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
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
                    const SizedBox(height: 32),

                    _buildSectionLabel('Planilha atual'),
                    const SizedBox(height: 12),
                    if (ativa.isNotEmpty)
                      ...ativa.map(
                        (d) => _buildPlanilhaItem(
                          context,
                          d.data() as Map<String, dynamic>,
                          d.id,
                          isAtiva: true,
                        ),
                      )
                    else
                      _buildAtivaEmptyState(),

                    const SizedBox(height: 32),

                    _buildSectionLabel('Anteriores'),
                    const SizedBox(height: 12),
                    if (historico.isNotEmpty)
                      ...historico.map(
                        (d) => _buildPlanilhaItem(
                          context,
                          d.data() as Map<String, dynamic>,
                          d.id,
                        ),
                      )
                    else
                      _buildHistoricoEmptyState(),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: FloatingActionButton.extended(
              onPressed: () => _showAddOptions(context),
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.black,
                size: 24,
              ),
              label: const Text('Nova planilha'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAtivaEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.add_rounded,
              color: AppColors.primary.withValues(alpha: 0.2),
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma planilha ativa',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Toque no botão abaixo para prescrever.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.labelSecondary.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricoEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: AppTheme.cardDecoration,
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history_rounded,
              color: Colors.white.withValues(alpha: 0.1),
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              'Planilhas vencidas aparecerão aqui',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.labelSecondary.withValues(alpha: 0.3),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(label, style: AppTheme.sectionHeader),
    );
  }

  Widget _buildPlanilhaItem(
    BuildContext context,
    Map<String, dynamic> data,
    String id, {
    bool isAtiva = false,
    bool isProgramada = false,
  }) {
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
        DateTime criacao =
            (data['dataCriacao'] as Timestamp?)?.toDate() ?? hoje;
        DateTime venc =
            (data['dataVencimento'] as Timestamp?)?.toDate() ??
            hoje.add(const Duration(days: 30));
        int totalDays = venc.difference(criacao).inDays;
        progress =
            (hoje.difference(criacao).inDays / (totalDays > 0 ? totalDays : 1))
                .clamp(0.0, 1.0);
        infoLabel = 'Vence em ${DateFormat('dd/MM').format(venc)}';
      }
    } else if (isProgramada) {
      statusLabel = 'AGENDADA';
      DateTime dataC =
          (data['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now();
      infoLabel = 'Inicia ${DateFormat('dd/MM').format(dataC)}';
    } else {
      statusLabel = 'FINALIZADA';
      DateTime dataC =
          (data['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now();
      infoLabel = DateFormat('dd MMM yyyy').format(dataC);
    }

    final Color accentColor = isAtiva
        ? AppColors.primary
        : (isProgramada ? AppColors.iosBlue : AppColors.labelSecondary);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
        left: SpacingTokens.screenHorizontalPadding,
        right: SpacingTokens.screenHorizontalPadding,
      ),
      decoration: AppTheme.cardDecoration,
      padding: CardTokens.padding,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        splashColor: AppColors.splash.withAlpha(50),
        highlightColor: AppColors.splash.withAlpha(30),
        onTap: () => _navegarParaDetalhes(context, data, id),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (isAtiva)
                  SizedBox(
                    width: ThumbnailTokens.md,
                    height: ThumbnailTokens.md,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      backgroundColor: accentColor.withValues(alpha: 0.1),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                Icon(
                  isAtiva
                      ? Icons.bolt_rounded
                      : (isProgramada
                            ? Icons.calendar_today_rounded
                            : Icons.history_rounded),
                  color: accentColor,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((data['nome'] ?? 'Planilha'), style: AppTheme.cardTitle),
                  const SizedBox(height: SpacingTokens.titleToSubtitle),
                  Row(
                    children: [
                      if (!isAtiva && !isProgramada)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                        ),

                      Text(infoLabel, style: AppTheme.caption),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              color: AppColors.background,
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'editar':
                    _navegarParaDetalhes(context, data, id);
                    break;
                  case 'stats':
                    // Implementar stats
                    break;
                  case 'alternar_status':
                    // Implementar ativar/pausar
                    break;
                  case 'excluir':
                    // Implementar excluir
                    break;
                }
              },
              itemBuilder: (context) => [
                _buildPopupItem(
                  'alternar_status',
                  isAtiva ? 'Pausar Planilha' : 'Ativar Planilha',
                  isAtiva ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: isAtiva ? Colors.orangeAccent : AppColors.primary,
                ),
                _buildPopupItem('editar', 'Editar', Icons.edit_note_rounded),
                _buildPopupItem(
                  'stats',
                  'Estatísticas',
                  Icons.bar_chart_rounded,
                  enabled: !isProgramada,
                ),
                _buildPopupItem(
                  'excluir',
                  'Excluir',
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    String label,
    IconData icon, {
    Color? color,
    bool enabled = true,
  }) {
    return PopupMenuItem<String>(
      value: value,
      enabled: enabled,
      child: Row(
        children: [
          Icon(
            icon,
            color: (color ?? Colors.white).withValues(alpha: enabled ? 1 : 0.3),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: (color ?? Colors.white).withValues(
                alpha: enabled ? 1 : 0.3,
              ),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navegarParaDetalhes(
    BuildContext context,
    Map<String, dynamic> data,
    String id,
  ) {
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
