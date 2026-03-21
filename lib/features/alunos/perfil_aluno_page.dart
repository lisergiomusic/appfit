import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../treinos/rotina_detalhe_page.dart';
import 'gerenciar_aluno_page.dart';
import 'feedback_historico_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'gerenciar_planilhas_page.dart';
import '../../core/services/aluno_service.dart';
import 'widgets/aluno_header_section.dart';

/// Tela de perfil detalhado do aluno.
/// Concentra informações de saúde, frequência semanal e gestão de planilhas.
class PerfilAlunoPage extends StatefulWidget {
  final String alunoId;
  final String alunoNome;
  final String? photoUrl;

  const PerfilAlunoPage({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    this.photoUrl,
  });

  @override
  State<PerfilAlunoPage> createState() => _PerfilAlunoPageState();
}

class _PerfilAlunoPageState extends State<PerfilAlunoPage> {
  late final AlunoService _alunoService;

  @override
  void initState() {
    super.initState();
    _alunoService = AlunoService();
  }

  /// Tenta abrir o WhatsApp do aluno com uma mensagem pré-definida.
  /// Limpa caracteres não numéricos e adiciona o prefixo do país (55).
  Future<void> _abrirWhatsApp(BuildContext context, String? telefone) async {
    if (telefone == null || telefone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Telefone não cadastrado para este aluno.'),
        ),
      );
      return;
    }

    final numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = "https://wa.me/55$numeroLimpo";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
      }
    }
  }

  /// Clona um template de rotina da biblioteca e atribui ao aluno atual.
  /// Define a planilha como ativa e desativa planilhas anteriores.
  Future<void> _atribuirTreinoAoAluno(
    BuildContext context,
    String templateId,
    String nomeRotina,
    int duracaoSemanas,
  ) async {
    try {
      final templateDoc = await FirebaseFirestore.instance
          .collection('rotinas')
          .doc(templateId)
          .get();
      if (!templateDoc.exists) return;

      // Desativa todas as rotinas que estavam marcadas como ativas para este aluno.
      final rotinasAntigas = await FirebaseFirestore.instance
          .collection('rotinas')
          .where('alunoId', isEqualTo: widget.alunoId)
          .where('ativa', isEqualTo: true)
          .get();

      for (var doc in rotinasAntigas.docs) {
        await doc.reference.update({'ativa': false});
      }

      final rotinaData = templateDoc.data() as Map<String, dynamic>;

      // Atualiza os metadados para o novo aluno.
      rotinaData['alunoId'] = widget.alunoId;
      rotinaData['ativa'] = true;
      rotinaData['dataCriacao'] = FieldValue.serverTimestamp();
      rotinaData['dataVencimento'] = Timestamp.fromDate(
        DateTime.now().add(Duration(days: duracaoSemanas * 7)),
      );

      await FirebaseFirestore.instance.collection('rotinas').add(rotinaData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rotina "$nomeRotina" ativada com sucesso!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erro ao vincular rotina: $e");
    }
  }

  /// Exibe diálogo para confirmar a ativação de um template e definir sua duração.
  void _confirmarAtivacaoTemplate(
    BuildContext context,
    String templateId,
    String titulo,
  ) {
    int semanasSelecionadas = 4;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Ativar Rotina',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Defina a duração da rotina "$titulo" para ${widget.alunoNome}:',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  initialValue: semanasSelecionadas,
                  dropdownColor: AppTheme.surfaceLight,
                  style: const TextStyle(color: Colors.white),
                  items: [4, 5, 6, 8, 10, 12]
                      .map(
                        (w) => DropdownMenuItem(
                          value: w,
                          child: Text('$w semanas'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setStateDialog(() => semanasSelecionadas = v!),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                  _atribuirTreinoAoAluno(
                    context,
                    templateId,
                    titulo,
                    semanasSelecionadas,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Ativar Ficha',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Modal de "Nova Rotina": Oferece opção de criar do zero ou listar templates da biblioteca.
  void _exibirOpcoesVincularTreino(BuildContext context) {
    final String? personalId = FirebaseAuth.instance.currentUser?.uid;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Nova Rotina',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
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
                icon: const Icon(Icons.add_circle_outline, color: Colors.black),
                label: const Text(
                  'Criar do Zero',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white10)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OU ESCOLHA DA BIBLIOTECA',
                      style: AppTheme.textSectionHeaderDark,
                    ),
                  ),
                  const Expanded(child: Divider(color: Colors.white10)),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rotinas')
                      .where('personalId', isEqualTo: personalId)
                      .where('alunoId', isNull: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'Sua biblioteca está vazia.',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        var rotina = doc.data() as Map<String, dynamic>;
                        int qtdSessoes = rotina['sessoes'] != null
                            ? (rotina['sessoes'] as List).length
                            : 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: AppTheme.surfaceLight.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _confirmarAtivacaoTemplate(
                                context,
                                doc.id,
                                rotina['nome'] ?? 'Rotina',
                              ),
                              splashColor: AppTheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              highlightColor: AppTheme.primary.withValues(
                                alpha: 0.06,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 4,
                                ),
                                title: Text(
                                  rotina['nome'] ?? 'Rotina',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '$qtdSessoes sessões planejadas',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
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

  void _irParaGerenciarAluno(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GerenciarAlunoPage(
          alunoId: widget.alunoId,
          alunoNome: widget.alunoNome,
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
          'Perfil do Aluno',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: const [SizedBox(width: 48)],
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: _alunoService.getAlunoStream(widget.alunoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }
          final alunoData =
              snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final photoUrl = alunoData['photoUrl'] as String?;
          final telefone = alunoData['telefone'] as String?;
          final dataNascimento = alunoData['dataNascimento'] as Timestamp?;
          final peso = alunoData['pesoAtual']?.toString() ?? '--';
          final idade = dataNascimento != null
              ? calcularIdade(dataNascimento).toString()
              : '--';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 24),
                AlunoHeaderSection(
                  alunoId: widget.alunoId,
                  alunoNome: widget.alunoNome,
                  photoUrl: widget.photoUrl ?? photoUrl,
                  idade: idade,
                  peso: peso,
                ),
                const SizedBox(height: 16),
                _buildActions(context, telefone),
                const SizedBox(height: 32),
                _buildRitmoDaSemana(),
                const SizedBox(height: 32),
                _buildFichaAtivaHeroCard(context),
                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GESTÃO', style: AppTheme.textSectionHeaderDark),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLarge,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _buildManagementItem(
                              context,
                              icon: Icons.description_outlined,
                              title: 'Planilhas de Treino',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        GerenciarPlanilhasPage(
                                          alunoId: widget.alunoId,
                                          alunoNome: widget.alunoNome,
                                          photoUrl: photoUrl,
                                          peso: peso,
                                          idade: idade,
                                        ),
                                  ),
                                );
                              },
                              showBorder: true,
                            ),

                            _buildManagementItem(
                              context,
                              icon: Icons.history_edu_rounded,
                              title: 'Histórico de Feedbacks',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FeedbackHistoricoPage(
                                      alunoNome: widget.alunoNome,
                                    ),
                                  ),
                                );
                              },
                              showBorder: true,
                            ),

                            _buildManagementItem(
                              context,
                              icon: Icons.query_stats_rounded,
                              title: 'Avaliação Física',
                              onTap: () {},
                              showBorder: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  Padding _buildActions(BuildContext context, String? telefone) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _abrirWhatsApp(context, telefone),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  color: AppTheme.primary,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'CONVERSAR',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _irParaGerenciarAluno(context),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.settings_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'GERENCIAR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
    );
  }

  /// Constrói um item de menu para a seção de Gestão.
  Widget _buildManagementItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool showBorder,
  }) {
    return Material(
      color: AppTheme.surfaceDark,
      child: InkWell(
        onTap: onTap,
        splashColor: AppTheme.splash,
        highlightColor: AppTheme.splash.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: showBorder
                ? Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.textSecondary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Exibe o componente visual de frequência semanal do aluno.
  /// No momento utiliza dados mockados para exibição.
  Widget _buildRitmoDaSemana() {
    final dias = [
      {'dia': 'S', 'status': 'feito'},
      {'dia': 'T', 'status': 'feito'},
      {'dia': 'Q', 'status': 'futuro'},
      {'dia': 'Q', 'status': 'feito'},
      {'dia': 'S', 'status': 'feito'},
      {'dia': 'S', 'status': 'futuro'},
      {'dia': 'D', 'status': 'futuro'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('FREQUÊNCIA SEMANAL', style: AppTheme.textSectionHeaderDark),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Ver Histórico',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dias.map((d) {
              final isFeito = d['status'] == 'feito';
              final isFalta = d['status'] == 'falta';
              final isFuturo = d['status'] == 'futuro';

              return Column(
                children: [
                  Text(
                    d['dia']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isFuturo
                          ? AppTheme.textSecondary.withValues(alpha: 0.5)
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isFeito
                          ? AppTheme.primary
                          : (isFalta
                                ? Colors.redAccent.withValues(alpha: 0.2)
                                : Colors.transparent),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isFeito
                            ? AppTheme.primary
                            : (isFalta
                                  ? Colors.redAccent.withValues(alpha: 0.5)
                                  : AppTheme.textSecondary.withValues(
                                      alpha: 0.15,
                                    )),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: isFeito
                          ? const Icon(
                              Icons.check,
                              color: Colors.black,
                              size: 20,
                            )
                          : (isFalta
                                ? const Icon(
                                    Icons.close,
                                    color: Colors.redAccent,
                                    size: 18,
                                  )
                                : Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: AppTheme.textSecondary.withValues(
                                        alpha: 0.3,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  )),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Card em destaque que mostra a planilha atualmente ativa do aluno.
  /// Calcula e exibe o progresso visual (circular) baseado no tempo ou sessões concluídas.
  Widget _buildFichaAtivaHeroCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rotinas')
            .where('alunoId', isEqualTo: widget.alunoId)
            .where('ativa', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyRoutineState(context);
          }

          var treinoDoc = snapshot.data!.docs.first;
          var rotina = treinoDoc.data() as Map<String, dynamic>;

          String tipoVencimento = rotina['tipoVencimento'] ?? 'data';
          double progressoAtual = 0.0;
          String legendaVencimento = '';
          String objetivo = rotina['objetivo'] ?? 'Objetivo não definido';

          // Lógica de cálculo de progresso para a barra circular.
          if (tipoVencimento == 'sessoes') {
            int totalSessoes = rotina['vencimentoSessoes'] ?? 1;
            int concluidas = rotina['sessoesConcluidas'] ?? 0;
            progressoAtual = (concluidas / totalSessoes).clamp(0.0, 1.0);
            legendaVencimento = '$concluidas / $totalSessoes concluídos';
          } else {
            DateTime hoje = DateTime.now();
            DateTime dataCriacao =
                (rotina['dataCriacao'] as Timestamp?)?.toDate() ?? hoje;
            DateTime dataVencimento =
                (rotina['dataVencimento'] as Timestamp?)?.toDate() ??
                hoje.add(const Duration(days: 30));
            int totalDias = dataVencimento.difference(dataCriacao).inDays;
            if (totalDias <= 0) totalDias = 1;
            int diasPassados = hoje.difference(dataCriacao).inDays;
            progressoAtual = (diasPassados / totalDias).clamp(0.0, 1.0);
            legendaVencimento =
                'Venc: ${DateFormat('dd/MM').format(dataVencimento)}';
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PLANILHA ATUAL', style: AppTheme.textSectionHeaderDark),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RotinaDetalhePage(
                                rotinaData: rotina,
                                rotinaId: treinoDoc.id,
                                alunoId: widget.alunoId,
                                alunoNome: widget.alunoNome,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          child: Row(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 58,
                                    height: 58,
                                    child: CircularProgressIndicator(
                                      value: progressoAtual,
                                      strokeWidth: 4,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        AppTheme.primary,
                                      ),
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.fitness_center_rounded,
                                      color: AppTheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (rotina['nome'] ?? 'Ficha de Treino')
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      objetivo,
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.05,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(100),
                                      ),
                                      child: Text(
                                        legendaVencimento,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppTheme.textSecondary,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Análise de progressão em desenvolvimento',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.auto_graph_rounded,
                                  color: AppTheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'EVOLUÇÃO DE CARGAS',
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Analisar progressão desta planilha',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppTheme.primary.withValues(alpha: 0.5),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Estado exibido quando o aluno não possui nenhuma planilha ativa.
  Widget _buildEmptyRoutineState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PLANO ATUAL', style: AppTheme.textSectionHeaderDark),
        const SizedBox(height: 12),
        Material(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _exibirOpcoesVincularTreino(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Prescrever Treino',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Função utilitária para calcular a idade do aluno a partir do seu nascimento.
int calcularIdade(Timestamp? dataNascimento) {
  if (dataNascimento == null) return 0;
  DateTime nascimento = dataNascimento.toDate();
  DateTime hoje = DateTime.now();
  int idade = hoje.year - nascimento.year;
  if (hoje.month < nascimento.month ||
      (hoje.month == nascimento.month && hoje.day < nascimento.day)) {
    idade--;
  }
  return idade;
}