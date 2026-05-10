import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/personal_service.dart';
import '../../../../core/services/aluno_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_nav_back_button.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../../treinos/personal/pages/personal_rotina_detalhe_page.dart';
import '../../shared/models/aluno_perfil_data.dart';
import '../../shared/widgets/aluno_header_section.dart';
import '../../shared/widgets/ficha_ativa_hero_card.dart';
import '../../shared/widgets/gestao_section.dart';
import '../../shared/widgets/ritmo_da_semana_card.dart';
import 'personal_gerenciar_aluno_page.dart';
import 'personal_gerenciar_planilhas_page.dart';

class PersonalAlunoPerfilPage extends StatefulWidget {
  final String alunoId;
  final String alunoNome;
  final String? photoUrl;

  const PersonalAlunoPerfilPage({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    this.photoUrl,
  });

  @override
  State<PersonalAlunoPerfilPage> createState() =>
      _PersonalAlunoPerfilPageState();
}

class _PersonalAlunoPerfilPageState extends State<PersonalAlunoPerfilPage> {
  late final AlunoService _alunoService;
  late final PersonalService _personalService;

  late Stream<AlunoPerfilData> _perfilStream;
  late Stream<dynamic> _logsSemanaStream;

  bool _isManualLoading = false;

  @override
  void initState() {
    super.initState();
    _alunoService = AlunoService();
    _personalService = PersonalService();
    _carregarDados();
  }

  void _carregarDados() {
    setState(() {
      _perfilStream = _alunoService.getAlunoPerfilCompletoStream(widget.alunoId);
      _logsSemanaStream = _alunoService.getLogsDaSemanaStream(widget.alunoId);
    });
  }

  /// Força o recarregamento dos dados (Trigger manual)
  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _isManualLoading = true);
    _carregarDados();
    // Pequeno delay para garantir que o spinner seja percebido e o banco processado
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isManualLoading = false);
  }

  Future<void> _abrirWhatsApp(BuildContext context, String? telefone) async {
    HapticFeedback.lightImpact();
    if (telefone == null || telefone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Telefone não cadastrado.')));
      return;
    }

    final numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = "https://wa.me/55$numeroLimpo";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _irParaGerenciarAluno(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalGerenciarAlunoPage(
          alunoId: widget.alunoId,
          alunoNome: widget.alunoNome,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          StreamBuilder<AlunoPerfilData>(
            stream: _perfilStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !_isManualLoading) {
                return _buildShimmerLoading();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.systemRed, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          "Erro ao carregar perfil.",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        AppPrimaryButton(
                          label: "Tentar Novamente",
                          onPressed: _carregarDados,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final data = snapshot.data;
              if (data == null) return const SizedBox.shrink();

              final alunoData = data.aluno;
              final String nomeFirestore =
                  '${alunoData['nome'] ?? ''} ${alunoData['sobrenome'] ?? ''}'
                      .trim();
              final String nomeExibicao = nomeFirestore.isNotEmpty
                  ? nomeFirestore
                  : widget.alunoNome;

              final photoUrl = alunoData['photoUrl'] as String?;
              final telefone = alunoData['telefone'] as String?;
              final dataNascimentoRaw = alunoData['data_nascimento'] ?? alunoData['dataNascimento'];
              final DateTime? dataNascimento = dataNascimentoRaw != null ? DateTime.tryParse(dataNascimentoRaw.toString()) : null;
              final peso = alunoData['peso_atual'] ?? alunoData['pesoAtual'] ?? '--';
              final idade = dataNascimento != null
                  ? _calcularIdade(dataNascimento).toString()
                  : '--';

              return RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceDark,
                edgeOffset: 120,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    _buildSliverAppBar(nomeExibicao),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.screenHorizontalPadding,
                        vertical: SpacingTokens.screenTopPadding,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          AlunoHeaderSection(
                            alunoId: widget.alunoId,
                            alunoNome: nomeExibicao,
                            photoUrl: widget.photoUrl ?? photoUrl,
                            idade: idade,
                            peso: peso.toString(),
                          ),
                          const SizedBox(height: 24),
                          _buildActions(context, telefone),
                          const SizedBox(height: SpacingTokens.sectionGap),
                          StreamBuilder<dynamic>(
                            stream: _logsSemanaStream,
                            builder: (context, logsSnapshot) {
                              List<DateTime>? treinados;
                              if (logsSnapshot.hasData) {
                                final list = logsSnapshot.data as List;
                                treinados = list
                                    .map((d) => DateTime.tryParse(d['dataHora'].toString()))
                                    .whereType<DateTime>()
                                    .toList();
                              }
                              return RitmoDaSemanaCard(
                                alunoNome: nomeExibicao,
                                diasTreinados: treinados,
                              );
                            },
                          ),
                          const SizedBox(height: SpacingTokens.xxl),
                          FichaAtivaHeroCard(
                            alunoId: widget.alunoId,
                            alunoNome: nomeExibicao,
                            photoUrl: widget.photoUrl ?? photoUrl,
                            peso: peso.toString(),
                            idade: idade,
                            rotinaAtiva: data.rotinaAtiva,
                            rotinaId: data.rotinaId,
                            onPrescreverTreino: () async {
                              HapticFeedback.lightImpact();
                              await _exibirOpcoesVincularTreino(context);
                              _refresh();
                            },
                          ),
                          const SizedBox(height: SpacingTokens.xxl),
                          GestaoSection(
                            alunoId: widget.alunoId,
                            alunoNome: nomeExibicao,
                            photoUrl: photoUrl,
                            peso: peso.toString(),
                            idade: idade,
                          ),
                          const SizedBox(height: 64),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_isManualLoading)
            Container(
              color: Colors.black.withAlpha(150),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(String nome) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: const AppNavBackButton(),
      actions: [
        IconButton(
          icon: const Icon(CupertinoIcons.settings, color: AppColors.labelSecondary, size: 22),
          onPressed: () => _irParaGerenciarAluno(context),
          padding: const EdgeInsets.only(right: 16),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: Container(
          decoration: BoxDecoration(gradient: AppTheme.premiumGradient),
        ),
        titlePadding: const EdgeInsets.only(left: 52, bottom: 16),
        centerTitle: false,
        title: Text('Perfil do Aluno', style: AppTheme.pageTitle),
      ),
    );
  }

  Widget _buildActions(BuildContext context, String? telefone) {
    return Row(
      children: [
        Expanded(
          child: AppTappable(
            onPressed: () => _abrirWhatsApp(context, telefone),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: AppTheme.premiumCardDecoration,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(FontAwesomeIcons.whatsapp,
                      color: Color(0xFF25D366), size: 18),
                  const SizedBox(width: 8),
                  Text('WHATSAPP', style: AppTheme.sectionAction.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exibirOpcoesVincularTreino(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Prescrever Treino'),
        message: const Text('Como deseja montar a planilha do aluno?'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              // Redirecionar para a gestão de planilhas onde ele pode escolher.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PersonalGerenciarPlanilhasPage(
                    alunoId: widget.alunoId,
                    alunoNome: widget.alunoNome,
                    photoUrl: widget.photoUrl,
                    peso: '--',
                    idade: '--',
                  ),
                ),
              ).then((_) => _refresh());
            },
            child: const Text('Usar um Template'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              _criarPlanilhaDoZero(context);
            },
            child: const Text('Criar do Zero'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  Future<void> _criarPlanilhaDoZero(BuildContext context) async {
    try {
      final String? newId = await _personalService.criarRotinaVazia(
        alunoId: widget.alunoId,
        alunoNome: widget.alunoNome,
      );

      if (newId != null && context.mounted) {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PersonalRotinaDetalhePage(
              rotinaId: newId,
              alunoId: widget.alunoId,
              alunoNome: widget.alunoNome,
              rotinaData: const {'nome': 'Nova Planilha', 'objetivo': ''},
            ),
          ),
        ).then((_) => _refresh());
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar: $e')),
        );
      }
    }
  }

  int _calcularIdade(DateTime dataNascimento) {
    final hoje = DateTime.now();
    int idade = hoje.year - dataNascimento.year;
    if (hoje.month < dataNascimento.month ||
        (hoje.month == dataNascimento.month && hoje.day < dataNascimento.day)) {
      idade--;
    }
    return idade;
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withAlpha(5),
      highlightColor: Colors.white.withAlpha(10),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.screenHorizontalPadding),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Row(
              children: [
                Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 150, height: 20, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 100, height: 14, color: Colors.white),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
            Container(width: double.infinity, height: 150, color: Colors.white),
            const SizedBox(height: 20),
            Container(width: double.infinity, height: 200, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
