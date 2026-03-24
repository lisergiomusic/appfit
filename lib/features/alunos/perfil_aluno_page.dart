import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../treinos/rotina_detalhe_page.dart';
import 'gerenciar_aluno_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/services/aluno_service.dart';
import 'widgets/aluno_header_section.dart';
import 'widgets/ficha_ativa_hero_card.dart';
import 'widgets/ritmo_da_semana_card.dart';
import 'widgets/gestao_section.dart';
import 'models/aluno_perfil_data.dart';

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
    }
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
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Perfil do Aluno',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 0.5,
            color: Colors.white.withAlpha(20),
          ),
        ),
      ),
      body: StreamBuilder<AlunoPerfilData>(
        stream: _alunoService.getAlunoPerfilCompletoStream(widget.alunoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("Erro ao carregar dados", style: TextStyle(color: Colors.white)));
          }

          final data = snapshot.data!;
          final alunoData = data.aluno;
          final photoUrl = alunoData['photoUrl'] as String?;
          final telefone = alunoData['telefone'] as String?;
          final dataNascimento = alunoData['dataNascimento'] as Timestamp?;
          final peso = alunoData['pesoAtual']?.toString() ?? '--';
          final idade = dataNascimento != null ? _calcularIdade(dataNascimento).toString() : '--';

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
                const SizedBox(height: 16),
                const RitmoDaSemanaCard(),
                const SizedBox(height: 32),
                FichaAtivaHeroCard(
                  alunoId: widget.alunoId,
                  alunoNome: widget.alunoNome,
                  onPrescreverTreino: () => _exibirOpcoesVincularTreino(context),
                ),
                const SizedBox(height: 32),
                GestaoSection(
                  alunoId: widget.alunoId,
                  alunoNome: widget.alunoNome,
                  photoUrl: photoUrl,
                  peso: peso,
                  idade: idade,
                ),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withAlpha(5),
      highlightColor: Colors.white.withAlpha(10),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(width: 80, height: 80, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 150, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(width: 100, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: Container(height: 46, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(width: 12),
                  Expanded(child: Container(height: 46, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(width: double.infinity, height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
            ),
            const SizedBox(height: 32),
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(width: double.infinity, height: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
            ),
          ],
        ),
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

  void _exibirOpcoesVincularTreino(BuildContext context) {
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
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
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
                  stream: _alunoService.getRotinasTemplates(),
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

  void _confirmarAtivacaoTemplate(BuildContext context, String templateId, String titulo) {
    int semanasSelecionadas = 4;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Ativar Rotina', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Duração para ${widget.alunoNome}:', style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  value: semanasSelecionadas,
                  dropdownColor: AppTheme.surfaceLight,
                  style: const TextStyle(color: Colors.white),
                  items: [4, 5, 6, 8, 10, 12].map((w) => DropdownMenuItem(value: w, child: Text('$w semanas'))).toList(),
                  onChanged: (v) => setStateDialog(() => semanasSelecionadas = v!),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                  _alunoService.atribuirTreinoAoAluno(
                    alunoId: widget.alunoId,
                    templateId: templateId,
                    duracaoSemanas: semanasSelecionadas,
                  );
                },
                child: const Text('Ativar'),
              ),
            ],
          );
        },
      ),
    );
  }

  int _calcularIdade(Timestamp? dataNascimento) {
    if (dataNascimento == null) return 0;
    DateTime nascimento = dataNascimento.toDate();
    DateTime hoje = DateTime.now();
    int idade = hoje.year - nascimento.year;
    if (hoje.month < nascimento.month || (hoje.month == nascimento.month && hoje.day < nascimento.day)) idade--;
    return idade;
  }
}