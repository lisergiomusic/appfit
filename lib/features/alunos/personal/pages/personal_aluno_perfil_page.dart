import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/services/personal_service.dart';
import '../../../../core/services/aluno_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_ui_utils.dart';
import '../../../../core/widgets/app_nav_back_button.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../../../core/widgets/glass_icon_button.dart';
import '../../../../core/widgets/glass_primary_button.dart';
import '../../../treinos/personal/pages/personal_rotina_detalhe_page.dart';
import '../../shared/models/aluno_perfil_data.dart';
import '../../shared/widgets/aluno_header_section.dart';
import '../../shared/widgets/ficha_ativa_hero_card.dart';
import '../../shared/widgets/gestao_section.dart';
import '../../shared/widgets/ritmo_da_semana_card.dart';
import 'personal_gerenciar_aluno_page.dart';
import 'personal_gerenciar_planilhas_page.dart';

/// Página de perfil detalhado do aluno para a visão do Personal Trainer.
/// Implementa uma interface Neo-Industrial com arquitetura Sliver e Glassmorphism.
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

  /// Inicializa os streams de dados do perfil e logs semanais.
  void _carregarDados() {
    setState(() {
      _perfilStream = _alunoService.getAlunoPerfilCompletoStream(widget.alunoId);
      _logsSemanaStream = _alunoService.getLogsDaSemanaStream(widget.alunoId);
    });
  }

  /// Navega para a página de edição/gerenciamento dos dados cadastrais do aluno.
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Efeito de profundidade com gradiente atmosférico no topo.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: SpacingTokens.atmosphereHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: GlassTokens.opacityAtmosphere),
                    AppColors.primary.withValues(alpha: GlassTokens.opacityAtmosphereSubtle),
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

              // Processamento de dados do aluno com formatação Title Case.
              final alunoData = data.aluno;
              final String nomeFirestore =
                  '${alunoData['nome'] ?? ''} ${alunoData['sobrenome'] ?? ''}'
                      .trim();
              final String nomeExibicao = (nomeFirestore.isNotEmpty
                  ? nomeFirestore
                  : widget.alunoNome).toTitleCase();

              final photoUrl = alunoData['photoUrl'] as String?;
              final dataNascimentoRaw = alunoData['data_nascimento'] ?? alunoData['dataNascimento'];
              final DateTime? dataNascimento = dataNascimentoRaw != null ? DateTime.tryParse(dataNascimentoRaw.toString()) : null;
              final peso = alunoData['peso_atual'] ?? alunoData['pesoAtual'] ?? '--';
              final idade = dataNascimento != null
                  ? _calcularIdade(dataNascimento).toString()
                  : '--';

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // AppBar dinâmica que transiciona o nome do aluno para o título ao rolar.
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: SpacingTokens.headerExpanded,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    leading: const AppNavBackButton(),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GlassIconButton(
                          onPressed: () => _irParaGerenciarAluno(context),
                          icon: CupertinoIcons.settings,
                          iconColor: AppColors.labelSecondary,
                          size: 48,
                          iconSize: 22,
                          color: Colors.transparent,
                          hasBorder: false,
                        ),
                      ),
                    ],
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) {
                        final double collapsedHeight = MediaQuery.of(context).padding.top + kToolbarHeight;
                        final double expandedHeight = SpacingTokens.headerExpanded;
                        final double collapseProgress = ((expandedHeight - constraints.biggest.height) / (expandedHeight - collapsedHeight)).clamp(0.0, 1.0);

                        return Stack(
                          children: [
                            // Efeito de vidro borrado quando a AppBar está recolhida.
                            if (collapseProgress > 0.9)
                              Positioned.fill(
                                child: ClipRect(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: GlassTokens.blurHeader,
                                      sigmaY: GlassTokens.blurHeader
                                    ),
                                    child: Container(
                                      color: Colors.black.withValues(alpha: GlassTokens.opacityBackdrop),
                                    ),
                                  ),
                                ),
                              ),

                            FlexibleSpaceBar(
                              centerTitle: true,
                              title: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: collapseProgress > 0.8 ? 1.0 : 0.0,
                                child: Text(
                                  nomeExibicao,
                                  style: AppTheme.pageTitle.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.0,
                                  ),
                                ),
                              ),
                              background: Container(
                                padding: EdgeInsets.only(
                                  top: 100 - (20 * collapseProgress),
                                  left: SpacingTokens.screenHorizontalPadding,
                                  right: SpacingTokens.screenHorizontalPadding,
                                ),
                                child: Opacity(
                                  opacity: (1.0 - (collapseProgress * 1.5)).clamp(0.0, 1.0),
                                  child: Transform.scale(
                                    scale: (1.0 - (collapseProgress * 0.2)).clamp(0.8, 1.0),
                                    child: AlunoHeaderSection(
                                      alunoId: widget.alunoId,
                                      alunoNome: nomeExibicao,
                                      photoUrl: widget.photoUrl ?? photoUrl,
                                      idade: idade,
                                      peso: peso.toString(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Seção de métricas rápidas (consistência semanal).
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: SpacingTokens.xxxl),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.screenHorizontalPadding),
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

                        const SizedBox(height: SpacingTokens.huge),
                      ],
                    ),
                  ),

                  // Console de Gestão: Ficha Ativa e Histórico.
                  // Utiliza SliverFillRemaining para estender o fundo de vidro infinitamente.
                  SliverFillRemaining(
                    hasScrollBody: false,
                    fillOverscroll: true,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: GlassTokens.consoleMarginH),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: GlassTokens.opacityConsole),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(GlassTokens.consoleRadius),
                          topRight: Radius.circular(GlassTokens.consoleRadius),
                        ),
                        border: Border(
                          top: BorderSide(color: Colors.white.withValues(alpha: GlassTokens.opacityBorder), width: 1),
                          left: BorderSide(color: Colors.white.withValues(alpha: GlassTokens.opacityBorder), width: 1),
                          right: BorderSide(color: Colors.white.withValues(alpha: GlassTokens.opacityBorder), width: 1),
                          bottom: BorderSide.none,
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: SpacingTokens.screenBottomPadding),

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

                          const SizedBox(height: SpacingTokens.screenBottomPadding),

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

                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Botões de ação flutuantes com estética de vidro e efeito tátil.
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: GlassPrimaryButton(
                    label: "Prescrever Treino",
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      await _exibirOpcoesVincularTreino(context);
                      _carregarDados();
                    },
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                GlassIconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                  },
                  customIcon: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: Color(0xFF25D366),
                    size: 22,
                  ),
                  size: 56,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Renderiza o estado de erro imersivo quando falha o carregamento dos dados.
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingTokens.xxl),
            margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.xxl),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: GlassTokens.opacitySurface),
              borderRadius: BorderRadius.circular(GlassTokens.consoleRadius),
              border: Border.all(color: Colors.white.withValues(alpha: GlassTokens.opacityBorder)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.antenna_radiowaves_left_right,
                  color: Colors.redAccent.withValues(alpha: 0.4),
                  size: 40,
                ),
                const SizedBox(height: SpacingTokens.xxl),
                const Text(
                  '[ ERRO DE REDE ]',
                  style: AppTheme.telemetryFailure,
                ),
                const SizedBox(height: SpacingTokens.md),
                Text(
                  'A conexão com o servidor foi interrompida.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xxxl),
                AppTappable(
                  onPressed: _carregarDados,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.xxl,
                      vertical: SpacingTokens.md
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: GlassTokens.opacityAtmosphereSubtle),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withValues(alpha: GlassTokens.opacityHighBorder)),
                    ),
                    child: const Text(
                      'TENTAR RECONEXÃO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Exibe o modal customizado para seleção do método de prescrição de treino.
  Future<void> _exibirOpcoesVincularTreino(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: GlassTokens.blurStandard,
                sigmaY: GlassTokens.blurStandard
              ),
              child: Container(color: Colors.black.withValues(alpha: GlassTokens.opacityBackdrop)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 100),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      GlassTokens.modalGradientTop,
                      GlassTokens.modalGradientBottom,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(GlassTokens.consoleRadius),
                    topRight: Radius.circular(GlassTokens.consoleRadius),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: GlassTokens.opacityHighBorder),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.xl,
                  vertical: SpacingTokens.xxxl
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: GlassTokens.opacityHighBorder),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.xxxl),
                      const Text(
                        'PRESCREVER TREINO',
                        style: AppTheme.technicalLabel,
                      ),
                      const SizedBox(height: SpacingTokens.sm),
                      Text(
                        'Selecione o método de construção da nova planilha.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.screenBottomPadding),

                      _buildModalItem(
                        context,
                        icon: CupertinoIcons.square_stack_3d_up,
                        title: 'Usar um Template',
                        subtitle: 'Puxar de um treino pré-configurado',
                        onTap: () {
                          Navigator.pop(context);
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
                      ),

                      const SizedBox(height: SpacingTokens.md),

                      _buildModalItem(
                        context,
                        icon: CupertinoIcons.add_circled,
                        title: 'Criar do Zero',
                        subtitle: 'Montar uma rotina personalizada agora',
                        onTap: () {
                          Navigator.pop(context);
                          _criarPlanilhaDoZero(context);
                        },
                      ),

                      const SizedBox(height: SpacingTokens.xxxl),

                      SizedBox(
                        width: double.infinity,
                        child: AppTappable(
                          onPressed: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.lg),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: GlassTokens.opacityConsole),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: Colors.white.withValues(alpha: GlassTokens.opacityBorder)),
                            ),
                            child: const Center(
                              child: Text(
                                'CANCELAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói um item de seleção modular para o modal.
  Widget _buildModalItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AppTappable(
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.xl),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: GlassTokens.opacityConsole),
          borderRadius: BorderRadius.circular(GlassTokens.itemRadius),
          border: Border.all(color: Colors.white.withValues(alpha: GlassTokens.opacityBorder)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: SpacingTokens.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: Colors.white.withValues(alpha: 0.2),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Executa a lógica de criação de uma planilha vazia.
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

  /// Helper para calcular a idade do aluno a partir da data de nascimento.
  int _calcularIdade(DateTime dataNascimento) {
    final hoje = DateTime.now();
    int idade = hoje.year - dataNascimento.year;
    if (hoje.month < dataNascimento.month ||
        (hoje.month == dataNascimento.month && hoje.day < dataNascimento.day)) {
      idade--;
    }
    return idade;
  }

  /// Constrói o esqueleto (Skeleton) de carregamento da página mantendo a estrutura de vidro.
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: GlassTokens.opacityAtmosphereSubtle),
      highlightColor: Colors.white.withValues(alpha: GlassTokens.opacityHighBorder),
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: SpacingTokens.headerExpanded,
            backgroundColor: Colors.transparent,
            leading: const SizedBox.shrink(),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.only(
                  top: 100,
                  left: SpacingTokens.screenHorizontalPadding,
                  right: SpacingTokens.screenHorizontalPadding,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 140, height: 16, color: Colors.white),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(width: 60, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100))),
                            const SizedBox(width: 8),
                            Container(width: 60, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: SpacingTokens.xxxl),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (_) => Container(width: 32, height: 32, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
                  ),
                ),
                const SizedBox(height: SpacingTokens.huge),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: GlassTokens.consoleMarginH),
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: GlassTokens.opacityConsole),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(GlassTokens.consoleRadius),
                      topRight: Radius.circular(GlassTokens.consoleRadius),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}