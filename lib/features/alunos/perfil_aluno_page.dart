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
  Future<void> _abrirWhatsApp(BuildContext context, String? telefone) async {
    if (telefone == null || telefone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefone não cadastrado.')),
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

      final rotinasAntigas = await FirebaseFirestore.instance
          .collection('rotinas')
          .where('alunoId', isEqualTo: widget.alunoId)
          .where('ativa', isEqualTo: true)
          .get();

      for (var doc in rotinasAntigas.docs) {
        await doc.reference.update({'ativa': false});
      }

      final rotinaData = templateDoc.data() as Map<String, dynamic>;
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
            content: Text('Rotina "$nomeRotina" ativada!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erro ao vincular rotina: $e");
    }
  }

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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Duração para ${widget.alunoNome}:',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  value: semanasSelecionadas,
                  dropdownColor: AppTheme.surfaceLight,
                  style: const TextStyle(color: Colors.white),
                  items: [4, 5, 6, 8, 10, 12]
                      .map((w) => DropdownMenuItem(value: w, child: Text('$w semanas')))
                      .toList(),
                  onChanged: (v) => setStateDialog(() => semanasSelecionadas = v!),
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
                child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                  _atribuirTreinoAoAluno(context, templateId, titulo, semanasSelecionadas);
                },
                child: const Text('Ativar'),
              ),
            ],
          );
        },
      ),
    );
  }

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
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(2.5),
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
                icon: const Icon(Icons.add_circle_outline, color: Colors.black, size: 20),
                label: const Text('CRIAR DO ZERO'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white10)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('DA BIBLIOTECA', style: AppTheme.textSectionHeaderDark),
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
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'Sua biblioteca está vazia.',
                          style: TextStyle(color: AppTheme.textSecondary.withAlpha(100)),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        var rotina = doc.data() as Map<String, dynamic>;
                        int qtdSessoes = rotina['sessoes'] != null ? (rotina['sessoes'] as List).length : 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight.withAlpha(20),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withAlpha(5)),
                          ),
                          child: ListTile(
                            onTap: () => _confirmarAtivacaoTemplate(context, doc.id, rotina['nome'] ?? 'Rotina'),
                            title: Text(rotina['nome'] ?? 'Rotina', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('$qtdSessoes sessões planejadas', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            trailing: const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 22),
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
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Perfil do Aluno',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, letterSpacing: -0.3),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 0.5,
            color: Colors.white.withAlpha(20),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _alunoService.getAlunoStream(widget.alunoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          final alunoData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final photoUrl = alunoData['photoUrl'] as String?;
          final telefone = alunoData['telefone'] as String?;
          final dataNascimento = alunoData['dataNascimento'] as Timestamp?;
          final peso = alunoData['pesoAtual']?.toString() ?? '--';
          final idade = dataNascimento != null ? calcularIdade(dataNascimento).toString() : '--';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 16),
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
                _buildGestaoSection(context, photoUrl, peso, idade),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActions(BuildContext context, String? telefone) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _abrirWhatsApp(context, telefone),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.whatsapp, color: AppTheme.primary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'CONVERSAR',
                      style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => _irParaGerenciarAluno(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'GERENCIAR',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
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

  Widget _buildGestaoSection(BuildContext context, String? photoUrl, String peso, String idade) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('GESTÃO', style: AppTheme.textSectionHeaderDark),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: Colors.white.withAlpha(5)),
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
                        builder: (context) => GerenciarPlanilhasPage(
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
                        builder: (context) => FeedbackHistoricoPage(alunoNome: widget.alunoNome),
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
    );
  }

  Widget _buildManagementItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool showBorder,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: showBorder ? Border(bottom: BorderSide(color: Colors.white.withAlpha(10), width: 0.5)) : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.textSecondary.withAlpha(150), size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary.withAlpha(80), size: 20),
            ],
          ),
        ),
      ),
    );
  }

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
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('FREQUÊNCIA SEMANAL', style: AppTheme.textSectionHeaderDark),
              TextButton(
                onPressed: () {},
                child: const Text('VER TUDO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: Colors.white.withAlpha(5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dias.map((d) {
              final isFeito = d['status'] == 'feito';
              final isFuturo = d['status'] == 'futuro';

              return Column(
                children: [
                  Text(
                    d['dia']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isFuturo ? AppTheme.textSecondary.withAlpha(100) : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isFeito ? AppTheme.primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isFeito ? AppTheme.primary : AppTheme.textSecondary.withAlpha(30),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: isFeito
                          ? const Icon(Icons.check, color: Colors.black, size: 18)
                          : Container(width: 4, height: 4, decoration: BoxDecoration(color: AppTheme.textSecondary.withAlpha(50), shape: BoxShape.circle)),
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

  Widget _buildFichaAtivaHeroCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingScreen),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rotinas')
            .where('alunoId', isEqualTo: widget.alunoId)
            .where('ativa', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyRoutineState(context);
          }

          var treinoDoc = snapshot.data!.docs.first;
          var rotina = treinoDoc.data() as Map<String, dynamic>;
          String objetivo = rotina['objetivo'] ?? 'Objetivo não definido';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PLANILHA ATUAL', style: AppTheme.textSectionHeaderDark),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(color: Colors.white.withAlpha(5)),
                ),
                child: Material(
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
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.fitness_center_rounded, color: AppTheme.primary, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (rotina['nome'] ?? 'Ficha de Treino').toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(objetivo, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary.withAlpha(80), size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyRoutineState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PLANILHA ATUAL', style: AppTheme.textSectionHeaderDark),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _exibirOpcoesVincularTreino(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: AppTheme.primary.withAlpha(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.primary.withAlpha(20), shape: BoxShape.circle),
                  child: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 28),
                ),
                const SizedBox(height: 12),
                const Text('Prescrever Treino', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

int calcularIdade(Timestamp? dataNascimento) {
  if (dataNascimento == null) return 0;
  DateTime nascimento = dataNascimento.toDate();
  DateTime hoje = DateTime.now();
  int idade = hoje.year - nascimento.year;
  if (hoje.month < nascimento.month || (hoje.month == nascimento.month && hoje.day < nascimento.day)) idade--;
  return idade;
}