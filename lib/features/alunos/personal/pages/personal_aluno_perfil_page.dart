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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: const AppNavBackButton(),
        title: const Text('Perfil do Aluno', style: AppTheme.pageTitle),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.settings,
                color: AppColors.labelSecondary, size: 22),
            onPressed: () => _irParaGerenciarAluno(context),
            padding: const EdgeInsets.only(right: 16),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Preto Absoluto de fundo para contraste infinito
          Container(color: Colors.black),
          
          // Gradiente Atmosférico de Profundidade
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 400,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          StreamBuilder<AlunoPerfilData>(
            stream: _perfilStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerLoading();
              }

              if (snapshot.hasError) {
                return _buildErrorState();
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

              return SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.screenHorizontalPadding),
                        child: AlunoHeaderSection(
                          alunoId: widget.alunoId,
                          alunoNome: nomeExibicao,
                          photoUrl: widget.photoUrl ?? photoUrl,
                          idade: idade,
                          peso: peso.toString(),
                        ),
                      ),
                      
                      const SizedBox(height: SpacingTokens.xxl),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.screenHorizontalPadding),
                        child: _buildActions(context, telefone),
                      ),

                      const SizedBox(height: 32),

                      // The Glass Console - A placa única de vidro
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 32),
                              
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: StreamBuilder<dynamic>(
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
                              ),

                              const SizedBox(height: 40),
                              
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: FichaAtivaHeroCard(
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
                                    _carregarDados();
                                  },
                                ),
                              ),

                              const SizedBox(height: 40),

                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: GestaoSection(
                                  alunoId: widget.alunoId,
                                  alunoNome: nomeExibicao,
                                  photoUrl: photoUrl,
                                  peso: peso.toString(),
                                  idade: idade,
                                ),
                              ),
                              
                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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

  Widget _buildActions(BuildContext context, String? telefone) {
    return Row(
      children: [
        AppTappable(
          onPressed: () => _abrirWhatsApp(context, telefone),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(SpacingTokens.sm),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: Color(0xFF25D366),
                  size: 16,
                ),
                const SizedBox(width: 12),
                const Text(
                  'MENSAGEM',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Novo Botão de Quick Insight (Placeholder técnico)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 18),
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
              ).then((_) => _carregarDados());
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
        ).then((_) => _carregarDados());
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