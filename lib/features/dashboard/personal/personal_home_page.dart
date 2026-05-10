import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/aluno_service.dart';
import '../../../core/services/personal_service.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/widgets/app_section_link_button.dart';
import '../../alunos/shared/widgets/app_avatar.dart';
import '../../alunos/personal/pages/personal_log_detalhe_page.dart';
import 'personal_atividade_recente_page.dart';
import 'personal_atencao_page.dart';
import 'personal_notificacoes_page.dart';

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
  final UserService _userService = UserService();
  final PersonalService _personalService = PersonalService();
  Future<ContagemAlunos>? _contagensFuture;

  @override
  void initState() {
    super.initState();
    _refreshContagens();
  }

  void _refreshContagens() {
    setState(() {
      _contagensFuture = _personalService.fetchContagens();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userService.getProfile(_authService.currentUser?.id ?? ''),
        builder: (context, snapshot) {
          String nome = "Personal";
          String? photoUrl;

          if (snapshot.hasData && snapshot.data != null) {
            final data = snapshot.data!;
            nome = data['nome']?.toString().split(' ')[0] ?? "Personal";
            photoUrl = (data['photo_url'] ?? data['photoUrl'])?.toString();
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(nome, photoUrl),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.screenHorizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: SpacingTokens.xxl),
                      Row(
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
                                      ? ((contagens.ativos / contagens.total) * 100).round()
                                      : 0;
                                  trendText = '$percentualAtivos% da base ativa';
                                } else if (snapshot.hasError) {
                                  trendText = 'Indisponível';
                                  trendIcon = Icons.info_outline_rounded;
                                  trendColor = AppColors.labelSecondary;
                                }

                                final ativosCount = snapshot.hasData
                                    ? snapshot.data!.ativos.toString()
                                    : snapshot.hasError ? '--' : '...';

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
                            child: FutureBuilder<ContagemAlunos>(
                              future: _contagensFuture,
                              builder: (context, snapshot) {
                                final count = snapshot.hasData
                                    ? snapshot.data!.risco.toString()
                                    : snapshot.hasError ? '--' : '...';

                                return _buildStatCard(
                                  label: 'Atenção necessária',
                                  value: count,
                                  trendText: 'Novos alertas',
                                  trendIcon: Icons.error_rounded,
                                  trendColor: (snapshot.data?.risco ?? 0) > 0
                                      ? AppColors.systemRed
                                      : AppColors.accentMetrics,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => PersonalAtencaoPage(personalService: _personalService)),
                                  ).then((_) => _refreshContagens()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SpacingTokens.xxl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ATIVIDADE RECENTE', style: AppTheme.sectionHeader),
                          AppSectionLinkButton(
                            label: 'VER MAIS',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PersonalAtividadeRecentePage(personalService: _personalService)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SpacingTokens.labelToField),
                      _AtividadeRecenteSection(personalService: _personalService),
                      const SizedBox(height: SpacingTokens.screenBottomPadding + 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(String nome, String? photoUrl) {
    return SliverAppBar(
      expandedHeight: 120,
      collapsedHeight: 70,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: Container(
          decoration: BoxDecoration(gradient: AppTheme.premiumGradient),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppAvatar(name: nome, photoUrl: photoUrl, radius: 18, showBorder: false),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_getSaudacao()},', style: AppTheme.premiumLabel.copyWith(fontSize: 8)),
                Text(nome, style: AppTheme.pageTitle.copyWith(fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.labelSecondary, size: 24),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalNotificationsPage())),
        ),
        const SizedBox(width: 8),
      ],
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
      decoration: AppTheme.premiumCardDecoration,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.formLabel.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: SpacingTokens.labelToField),
              Text(value, style: AppTheme.title1.copyWith(fontSize: 24)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(trendIcon, size: 14, color: trendColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      trendText,
                      style: AppTheme.caption.copyWith(color: trendColor, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _AtividadeRecenteSection extends StatelessWidget {
  final PersonalService personalService;
  const _AtividadeRecenteSection({required this.personalService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AtividadeRecenteItem>>(
      stream: personalService.getAtividadeRecenteStream(),
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
          decoration: AppTheme.premiumCardDecoration,
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
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.premiumCardDecoration,
      width: double.infinity,
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 40, color: AppColors.labelSecondary.withAlpha(50)),
          const SizedBox(height: 12),
          Text(
            'Nenhuma atividade',
            style: AppTheme.cardTitle,
          ),
          const SizedBox(height: 4),
          Text(
            'Os treinos concluídos aparecerão aqui.',
            style: AppTheme.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Container(
      height: 160,
      decoration: AppTheme.premiumCardDecoration,
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AppAvatar(
                  name: item.alunoNome,
                  photoUrl: item.alunoPhotoUrl,
                  radius: 20,
                  showBorder: false,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.alunoNome, style: AppTheme.cardTitle),
                      const SizedBox(height: 4),
                      Text(
                        item.sessaoNome.isEmpty
                            ? 'Concluiu um treino'
                            : 'Concluiu o treino "${item.sessaoNome}"',
                        style: AppTheme.caption,
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
                    Text(_tempoRelativo(item.dataHora), style: AppTheme.premiumLabel.copyWith(fontSize: 10)),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.labelSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showDivider)
            Padding(
              padding: const EdgeInsets.only(left: 70),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: Colors.white.withAlpha(10),
              ),
            ),
        ],
      ),
    );
  }
}