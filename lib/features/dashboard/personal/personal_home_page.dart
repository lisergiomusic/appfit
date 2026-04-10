import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/aluno_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_bar_divider.dart';
import '../../../core/widgets/app_section_link_button.dart';

class PersonalHomePage extends StatefulWidget {
  final VoidCallback? onNovoAlunoTap;
  final VoidCallback? onCriarRotinaTap;

  const PersonalHomePage({
    super.key,
    this.onNovoAlunoTap,
    this.onCriarRotinaTap,
  });

  @override
  State<PersonalHomePage> createState() => _PersonalHomePageState();
}

class _PersonalHomePageState extends State<PersonalHomePage> {
  final AuthService _authService = AuthService();
  final AlunoService _alunoService = AlunoService();
  late final Future<ContagemAlunos> _contagensFuture;

  @override
  void initState() {
    super.initState();
    _contagensFuture = _alunoService.fetchContagens();
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
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('Painel de Controle'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.systemRed,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: const AppBarDivider(),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: _authService.getCurrentUserData(),
              builder: (context, snapshot) {
                String nome = "...";
                String? photoUrl;
                String tipoUsuarioLabel = 'Usuario';

                if (snapshot.hasData && snapshot.data != null) {
                  final data = snapshot.data!;
                  nome = data['nome']?.toString().split(' ')[0] ?? "Usuário";
                  photoUrl = data['photoUrl'] as String?;

                  final tipoUsuario = data['tipoUsuario']
                      ?.toString()
                      .toLowerCase();
                  if (tipoUsuario == 'personal') {
                    tipoUsuarioLabel = 'Personal Trainer';
                  } else if (tipoUsuario == 'aluno') {
                    tipoUsuarioLabel = 'Aluno';
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(
                    left: AppTheme.paddingScreen,
                    right: AppTheme.paddingScreen,
                    top: SpacingTokens.screenTopPadding,
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: AvatarTokens.lg,
                            backgroundColor: AppColors.surfaceLight,
                            backgroundImage:
                                photoUrl != null && photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null || photoUrl.isEmpty
                                ? const Icon(
                                    Icons.person_rounded,
                                    color: AppColors.labelSecondary,
                                    size: 34,
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getSaudacao()}, $nome',
                                style: AppTheme.title1,
                              ),
                              const SizedBox(height: AppTheme.radiusXS),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: PillTokens.decoration,
                                child: Text(
                                  tipoUsuarioLabel,
                                  style: PillTokens.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: SpacingTokens.xxl),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingScreen,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FutureBuilder<ContagemAlunos>(
                      future: _contagensFuture,
                      builder: (context, snapshot) {
                        String trendText = 'Calculando...';
                        IconData trendIcon = Icons.pie_chart_rounded;
                        Color trendColor = AppColors.primary;

                        if (snapshot.hasData) {
                          final contagens = snapshot.data!;
                          final percentualAtivos = contagens.total > 0
                              ? ((contagens.ativos / contagens.total) * 100)
                                    .round()
                              : 0;
                          trendText = '$percentualAtivos% da base ativa';
                        } else if (snapshot.hasError) {
                          trendText = 'Indicador indisponivel';
                          trendIcon = Icons.info_outline_rounded;
                          trendColor = AppColors.labelSecondary;
                        }

                        final ativosCount = snapshot.hasData
                            ? snapshot.data!.ativos.toString()
                            : snapshot.hasError
                            ? '--'
                            : '...';

                        return _buildStatCard(
                          label: 'Alunos ativos',
                          value: ativosCount,
                          trendText: trendText,
                          trendIcon: trendIcon,
                          trendColor: trendColor,
                          onTap: () {},
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      label: 'Atenção necessária',
                      value: '05',
                      trendText: 'Pendentes',
                      trendIcon: Icons.error_rounded,
                      trendColor: AppColors.accentMetrics,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpacingTokens.sectionGap),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingScreen,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Atividade recente', style: AppTheme.sectionHeader),
                  AppSectionLinkButton(label: 'Ver tudo', onPressed: () {}),
                ],
              ),
            ),
            const SizedBox(height: SpacingTokens.labelToField),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingScreen,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  border: Border.all(color: Colors.white.withAlpha(5)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _buildRecentActivityItem(
                      name: 'Cristiano Ronaldo',
                      action: 'Concluiu Treino A',
                      time: 'Há 2h',
                      showDivider: true,
                    ),
                    _buildRecentActivityItem(
                      name: 'Paola Oliveira',
                      action: 'Atualizou medidas',
                      time: 'Há 4h',
                      showDivider: true,
                    ),
                    _buildRecentActivityItem(
                      name: 'Everton Ribeiro',
                      action: 'Novo PR no Supino',
                      time: 'Ontem',
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  String _getSaudacao() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) return 'Bom dia';
    if (hora >= 12 && hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String trendText,
    required IconData trendIcon,
    required Color trendColor,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: Padding(
          padding: CardTokens.padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTheme.formLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: SpacingTokens.labelToField),
                    Text(value, style: AppTheme.title1),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(trendIcon, size: 12, color: trendColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            trendText,
                            style: AppTheme.caption.copyWith(color: trendColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.labelSecondary.withAlpha(80),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityItem({
    required String name,
    required String action,
    required String time,
    required bool showDivider,
    String? photoUrl,
  }) {
    return InkWell(
      onTap: () {},
      child: Column(
        children: [
          Padding(
            padding: CardTokens.padding,
            child: Row(
              children: [
                CircleAvatar(
                  radius: AvatarTokens.md,
                  backgroundColor: AppColors.surfaceLight,
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          color: AppColors.labelSecondary,
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTheme.cardTitle),
                      const SizedBox(height: SpacingTokens.titleToSubtitle),
                      Text(
                        action,
                        style: AppTheme.cardSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(time, style: AppTheme.caption),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.labelSecondary.withAlpha(80),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showDivider)
            Padding(
              padding: const EdgeInsets.only(left: 68),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.separator,
              ),
            ),
        ],
      ),
    );
  }
}
