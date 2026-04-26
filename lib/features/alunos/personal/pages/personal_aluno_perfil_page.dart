import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/aluno_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bar_divider.dart';
import '../../../../core/widgets/app_nav_back_button.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../../treinos/personal/pages/personal_rotina_detalhe_page.dart';
import '../../shared/models/aluno_perfil_data.dart';
import '../../shared/widgets/aluno_header_section.dart';
import '../../shared/widgets/ficha_ativa_hero_card.dart';
import '../../shared/widgets/gestao_section.dart';
import '../../shared/widgets/ritmo_da_semana_card.dart';
import 'personal_ativar_template_page.dart';
import 'personal_gerenciar_aluno_page.dart';

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

  late final Stream<AlunoPerfilData> _perfilStream;
  late final Stream<QuerySnapshot> _logsSemanaStream;

  // Último dado recebido — exibido enquanto o stream reemite, evitando shimmer
  // desnecessário quando o cache local já tem os dados.
  AlunoPerfilData? _ultimoPerfil;
  List<DateTime>? _ultimosDiasTreinados;

  @override
  void initState() {
    super.initState();
    _alunoService = AlunoService();
    _perfilStream = _alunoService.getAlunoPerfilCompletoStream(widget.alunoId);
    _logsSemanaStream = _alunoService.getLogsDaSemanaStream(widget.alunoId);
  }

  Future<void> _abrirWhatsApp(BuildContext context, String? telefone) async {
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
    // Mapa de seções da interface desta página:
    // 1) Estrutura superior: AppBar, título e ações de navegação.
    // 2) Conteúdo principal: blocos, listas, cards e estados da tela.
    // 3) Ações finais: botões primários, confirmadores e feedbacks.
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppNavBackButton(),
        title: const Text('Perfil do Aluno'),
        bottom: const AppBarDivider(),
      ),
      body: StreamBuilder<AlunoPerfilData>(
        stream: _perfilStream,
        builder: (context, snapshot) {
          // Usa dado em cache se o stream está recomeçando — evita shimmer
          // desnecessário quando voltamos de uma página filha.
          final perfilAtual = snapshot.data ?? _ultimoPerfil;

          if (snapshot.connectionState == ConnectionState.waiting &&
              perfilAtual == null) {
            return _buildShimmerLoading();
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final stack = snapshot.stackTrace;
            debugPrint('[PERFIL_ERROR] Error: $error\nStack: $stack');

            // Se já temos um perfil (cache), não mostra erro de tela cheia,
            // apenas loga. Isso evita que falhas em streams secundários
            // quebrem a visualização principal.
            if (perfilAtual == null) {
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
                        "Erro ao carregar perfil completo.",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$error",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.labelSecondary),
                      ),
                      const SizedBox(height: 24),
                      AppPrimaryButton(
                        label: "Tentar Novamente",
                        onPressed: () {
                          setState(() {
                            _perfilStream = _alunoService
                                .getAlunoPerfilCompletoStream(widget.alunoId);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
          }

          if (perfilAtual == null) {
            return const Center(
              child: Text(
                "Nenhum dado encontrado para este aluno.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.labelSecondary),
              ),
            );
          }

          // Atualiza o cache local sempre que chega dado novo.
          if (snapshot.hasData) _ultimoPerfil = snapshot.data;

          final data = perfilAtual;
          final alunoData = data.aluno;
          final String nomeFirestore =
              '${alunoData['nome'] ?? ''} ${alunoData['sobrenome'] ?? ''}'
                  .trim();
          final String nomeExibicao = nomeFirestore.isNotEmpty
              ? nomeFirestore
              : widget.alunoNome;

          final photoUrl = alunoData['photoUrl'] as String?;
          final telefone = alunoData['telefone'] as String?;
          final dataNascimento = alunoData['dataNascimento'] as Timestamp?;
          final peso = alunoData['pesoAtual']?.toString() ?? '--';
          final idade = dataNascimento != null
              ? _calcularIdade(dataNascimento).toString()
              : '--';

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: SpacingTokens.screenHorizontalPadding,
              vertical: SpacingTokens.screenTopPadding,
            ),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                AlunoHeaderSection(
                  alunoId: widget.alunoId,
                  alunoNome: nomeExibicao,
                  photoUrl: widget.photoUrl ?? photoUrl,
                  idade: idade,
                  peso: peso,
                ),
                const SizedBox(height: 16),
                _buildActions(context, telefone),
                const SizedBox(height: SpacingTokens.sectionGap),
                StreamBuilder<QuerySnapshot>(
                  stream: _logsSemanaStream,
                  builder: (context, logsSnapshot) {
                    if (logsSnapshot.hasData) {
                      _ultimosDiasTreinados = logsSnapshot.data!.docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        return (d['dataHora'] as Timestamp).toDate();
                      }).toList();
                    }
                    return RitmoDaSemanaCard(
                      alunoNome: nomeExibicao,
                      diasTreinados: _ultimosDiasTreinados,
                    );
                  },
                ),
                const SizedBox(height: SpacingTokens.xxl),
                FichaAtivaHeroCard(
                  alunoId: widget.alunoId,
                  alunoNome: nomeExibicao,
                  photoUrl: widget.photoUrl ?? photoUrl,
                  peso: peso,
                  idade: idade,
                  rotinaAtiva: data.rotinaAtiva,
                  rotinaId: data.rotinaId,
                  onPrescreverTreino: () =>
                      _exibirOpcoesVincularTreino(context),
                ),
                const SizedBox(height: SpacingTokens.xxl),
                GestaoSection(
                  alunoId: widget.alunoId,
                  alunoNome: nomeExibicao,
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
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.screenHorizontalPadding,
          vertical: SpacingTokens.screenTopPadding,
        ),
        child: Column(
          children: [
            const SizedBox(height: SpacingTokens.screenTopPadding),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ],
        ),
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
              height: ButtonTokens.primaryHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(ButtonTokens.primaryRadius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Conversar',
                        style: ButtonTokens.primaryTextStyle.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: SpacingTokens.sm),
        Expanded(
          child: AppTappable(
            onPressed: () => _irParaGerenciarAluno(context),
            child: Container(
              height: ButtonTokens.secondaryHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.fillSecondary,
                borderRadius: BorderRadius.circular(
                  ButtonTokens.secondaryRadius,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.settings,
                    color: AppColors.labelPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Gerenciar',
                        style: ButtonTokens.secondaryTextStyle,
                      ),
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

  void _exibirOpcoesVincularTreino(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        final rotinasStream = _alunoService.getRotinasTemplates();
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingScreen,
            vertical: 12,
          ),
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
              Center(
                child: const Text('Nova Planilha', style: AppTheme.pageTitle),
              ),
              const SizedBox(height: SpacingTokens.sectionGap),
              AppPrimaryButton(
                label: 'Criar do zero',
                icon: Icons.add_circle_outline,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PersonalRotinaDetalhePage(
                        alunoId: widget.alunoId,
                        alunoNome: widget.alunoNome,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: SpacingTokens.sectionGap),
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white10)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Da Biblioteca', style: AppTheme.sectionHeader),
                  ),
                  const Expanded(child: Divider(color: Colors.white10)),
                ],
              ),
              const SizedBox(height: SpacingTokens.sectionGap),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: rotinasStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          snapshot.hasError
                              ? 'Erro ao carregar biblioteca.'
                              : 'Sua biblioteca está vazia.',
                          style: TextStyle(
                            color: AppColors.labelSecondary.withAlpha(100),
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
                          decoration: AppTheme.cardDecoration.copyWith(
                            color: AppColors.surfaceLight,
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PersonalAtivarTemplatePage(
                                        templateId: doc.id,
                                        alunoId: widget.alunoId,
                                        alunoNome: widget.alunoNome,
                                      ),
                                ),
                              );
                            },
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(40),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSM,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.fitness_center,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
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
                                color: AppColors.labelSecondary,
                                fontSize: 13,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.add_circle_outline,
                              color: AppColors.primary,
                              size: 22,
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
        );
      },
    );
  }

  int _calcularIdade(Timestamp? dataNascimento) {
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
}