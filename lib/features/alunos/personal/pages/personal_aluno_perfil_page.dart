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
          // Profundidade Atmosférica
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 450,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
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
                  // SliverAppBar Premium com Transição Espacial
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 180,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    leading: const AppNavBackButton(),
                    actions: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.settings,
                            color: AppColors.labelSecondary, size: 22),
                        onPressed: () => _irParaGerenciarAluno(context),
                        padding: const EdgeInsets.only(right: 16),
                      ),
                    ],
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) {
                        final double collapsedHeight = MediaQuery.of(context).padding.top + kToolbarHeight;
                        final double expandedHeight = 180;
                        final double collapseProgress = ((expandedHeight - constraints.biggest.height) / (expandedHeight - collapsedHeight)).clamp(0.0, 1.0);

                        return Stack(
                          children: [
                            // Efeito Glassmorphism quando pinado
                            if (collapseProgress > 0.9)
                              Positioned.fill(
                                child: ClipRect(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                    child: Container(
                                      color: Colors.black.withValues(alpha: 0.5),
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

                  // Conteúdo em Slivers
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 32),

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

                        const SizedBox(height: 48),
                        ],
                        ),
                        ),

                        // The Glass Console - Stretch infinito
                        SliverFillRemaining(
                        hasScrollBody: false,
                        fillOverscroll: true,
                        child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        border: Border(
                          top: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
                          left: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
                          right: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
                          bottom: BorderSide.none,
                        ),
                        ),
                        child: Column(
                        children: [
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

                          const SizedBox(height: 120), // Espaço generoso no final
                        ],
                        ),
                        ),
                        ),
                        ],
                        );
                        },
                        ),
          // Floating Glass CTA Group (Apple-style)
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: Row(
              children: [
                // Botão Primário (Expandido)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: AppPrimaryButton(
                        label: "PRESCREVER TREINO",
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await _exibirOpcoesVincularTreino(context);
                          _carregarDados();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Botão WhatsApp Circular (Glassmorphism)
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 53,
                      height: 53,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.whatsapp,
                          color: Color(0xFF25D366),
                          size: 22,
                        ),
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.antenna_radiowaves_left_right,
                  color: Colors.redAccent.withValues(alpha: 0.4),
                  size: 40,
                ),
                const SizedBox(height: 24),
                const Text(
                  '[ FALHA DE TELEMETRIA ]',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A conexão com o servidor foi interrompida.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                AppTappable(
                  onPressed: _carregarDados,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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

  Future<void> _exibirOpcoesVincularTreino(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Stack(
        children: [
          // Blur de fundo para manter a imersão
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 100), // Espaço para o "pull down"
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF121212), // Um preto levemente iluminado no topo
                      Colors.black,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'PRESCREVER TREINO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selecione o método de construção da nova planilha.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Opção: Template
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
                      
                      const SizedBox(height: 12),
                      
                      // Opção: Do Zero
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
                      
                      const SizedBox(height: 32),
                      
                      // Botão Cancelar (Glass Pill)
                      SizedBox(
                        width: double.infinity,
                        child: AppTappable(
                          onPressed: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
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
      baseColor: Colors.white.withValues(alpha: 0.05),
      highlightColor: Colors.white.withValues(alpha: 0.1),
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
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
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (_) => Container(width: 32, height: 32, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
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