import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/aluno_service.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../../core/widgets/app_bar_divider.dart';
import '../../../core/widgets/app_section_link_button.dart';
import '../../alunos/shared/widgets/aluno_avatar.dart';
import '../../alunos/personal/pages/personal_log_detalhe_page.dart';
import 'personal_atividade_recente_page.dart';

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
  final SupabaseAuthService _authService = SupabaseAuthService();
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
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: const Text('Painel de Controle'),
        ),
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

                if (snapshot.hasData && snapshot.data != null) {
                  final data = snapshot.data!;
                  nome = data['nome']?.toString().split(' ')[0] ?? "Personal";
                  photoUrl = data['photoUrl'] as String?;
                }

                return Padding(
                  padding: const EdgeInsets.only(
                    left: SpacingTokens.screenHorizontalPadding,
                    right: SpacingTokens.screenHorizontalPadding,
                    top: SpacingTokens.screenTopPadding,
                  ),
                  child: Row(
                    children: [
                      AlunoAvatar(
                        alunoNome: nome,
                        photoUrl: photoUrl,
                        radius: AvatarTokens.lg,
                        showBorder: false,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getSaudacao()},',
                            style: AppTheme.caption.copyWith(
                              color: AppColors.labelSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(nome, style: AppTheme.title1),
                        ],
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
                  AppSectionLinkButton(
                    label: 'Ver tudo',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonalAtividadeRecentePage(
                          alunoService: _alunoService,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpacingTokens.labelToField),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingScreen,
              ),
              child: _AtividadeRecenteSection(alunoService: _alunoService),
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

}

class _AtividadeRecenteSection extends StatelessWidget {
  final AlunoService alunoService;
  const _AtividadeRecenteSection({required this.alunoService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AtividadeRecenteItem>>(
      stream: alunoService.getAtividadeRecenteStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmer();
        }

        if (snapshot.hasError) {
          return _buildEmpty();
        }

        final items = (snapshot.data ?? []).take(4).toList();

        if (items.isEmpty) {
          return _buildEmpty();
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: Colors.white.withAlpha(5)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                _AtividadeItem(
                  item: items[i],
                  showDivider: i < items.length - 1,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: CardTokens.padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      child: Center(
        child: Text(
          'Nenhum treino concluído ainda.',
          style: AppTheme.cardSubtitle,
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
    );
  }
}

class _AtividadeItem extends StatelessWidget {
  final AtividadeRecenteItem item;
  final bool showDivider;
  const _AtividadeItem({required this.item, required this.showDivider});

  String _tempoRelativo(DateTime data) {
    final diff = DateTime.now().difference(data);
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Há ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 7) return 'Há ${diff.inDays}d';
    return DateFormat('d MMM', 'pt_BR').format(data);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PersonalLogDetalhePage(item: item),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: CardTokens.padding,
            child: Row(
              children: [
                AlunoAvatar(
                  alunoNome: item.alunoNome,
                  photoUrl: item.alunoPhotoUrl,
                  radius: AvatarTokens.md,
                  showBorder: false,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.alunoNome, style: AppTheme.cardTitle),
                      const SizedBox(height: SpacingTokens.titleToSubtitle),
                      Text(
                        'Concluiu ${item.sessaoNome}',
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
                    Text(_tempoRelativo(item.dataHora), style: AppTheme.caption),
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