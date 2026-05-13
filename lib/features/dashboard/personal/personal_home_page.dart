import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/aluno_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/personal_service.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/widgets/app_tappable.dart';
import '../../../core/widgets/glass_icon_button.dart';
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
  Future<Map<String, dynamic>>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _refreshContagens();
    _profileFuture = _userService.getProfile(_authService.currentUser?.id ?? '');
  }

  void _refreshContagens() {
    setState(() {
      _contagensFuture = _personalService.fetchContagens();
    });
  }

  String _getSaudacao() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) return 'BOM DIA';
    if (hora >= 12 && hora < 18) return 'BOA TARDE';
    return 'BOA NOITE';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Atmosfera Superior (Efeito de profundidade)
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

          FutureBuilder<Map<String, dynamic>>(
            future: _profileFuture,
            builder: (context, profileSnapshot) {
              final personalData = profileSnapshot.data;
              final nome = personalData?['nome']?.toString().split(' ')[0] ?? "PERSONAL";
              final photoUrl = (personalData?['photo_url'] ?? personalData?['photoUrl'])?.toString();

              return CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  // Header Sliver com Avatar e Notificação
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 32,
                        left: 24,
                        right: 24,
                        bottom: 40,
                      ),
                      child: Row(
                        children: [
                          AppAvatar(
                            name: nome,
                            photoUrl: photoUrl,
                            radius: 32, // Aumentado para mais impacto visual (Apple Style)
                            showBorder: true,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getSaudacao(),
                                  style: AppTheme.heroSubtitle.copyWith(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 10,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  nome,
                                  style: AppTheme.heroTitle.copyWith(
                                    fontSize: 26, // Título mais imersivo
                                    letterSpacing: -1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GlassIconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PersonalNotificationsPage())
                            ),
                            icon: Icons.notifications_outlined,
                            size: 48,
                            iconSize: 24,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Console de Vidro Principal (Infinite Scroll)
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // Grid de Métricas Técnicas
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: FutureBuilder<ContagemAlunos>(
                              future: _contagensFuture,
                              builder: (context, snapshot) {
                                final contagens = snapshot.data;
                                final ativos = contagens?.ativos.toString() ?? '--';
                                final risco = contagens?.risco.toString() ?? '--';

                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricTile(
                                        label: 'ALUNOS ATIVOS',
                                        value: ativos,
                                        icon: Icons.group_rounded,
                                        color: AppColors.primary,
                                        onTap: () {},
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.white.withValues(alpha: 0.05),
                                    ),
                                    Expanded(
                                      child: _buildMetricTile(
                                        label: 'ATENÇÃO CRÍTICA',
                                        value: risco,
                                        icon: Icons.warning_rounded,
                                        color: (contagens?.risco ?? 0) > 0
                                          ? AppColors.systemRed
                                          : AppColors.labelSecondary.withValues(alpha: 0.3),
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => PersonalAtencaoPage(personalService: _personalService)),
                                        ).then((_) => _refreshContagens()),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 40),
                          _buildSectionHeader(
                            title: 'ATIVIDADE RECENTE',
                            onAction: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PersonalAtividadeRecentePage(personalService: _personalService)),
                            ),
                          ),

                          _AtividadeRecenteSection(personalService: _personalService),

                          const Spacer(),
                          const SizedBox(height: 120), // Buffer infinito
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Constrói um tile de métrica técnica integrada ao console.
  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppTappable(
      onPressed: onTap,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.technicalLabel.copyWith(

                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.title1.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace', // Estética técnica
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o cabeçalho de seção dentro do console.
  Widget _buildSectionHeader({required String title, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTheme.sectionHeader,
          ),
          if (onAction != null)
            AppTappable(
              onPressed: onAction,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'VER TUDO',
                  style: AppTheme.sectionAction,
                ),
              ),
            ),
        ],
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
          return const Center(child: CircularProgressIndicator(strokeWidth: 1, color: AppColors.primary));
        }

        final items = (snapshot.data ?? []).take(5).toList();

        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40.0),
            child: Center(
              child: Text(
                'SEM ATIVIDADE RECENTE',
                style: AppTheme.technicalLabel.copyWith(
                  color: Colors.white.withValues(alpha: 0.05),
                  fontSize: 10,
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            for (var item in items)
              _AtividadeItem(item: item),
          ],
        );
      },
    );
  }
}

class _AtividadeItem extends StatelessWidget {
  final AtividadeRecenteItem item;
  const _AtividadeItem({required this.item});

  String _tempoRelativo(DateTime data) {
    final diff = DateTime.now().difference(data);
    if (diff.inMinutes < 60) return '${diff.inMinutes}M';
    if (diff.inHours < 24) return '${diff.inHours}H';
    return DateFormat('dd/MM').format(data);
  }

  @override
  Widget build(BuildContext context) {
    return AppTappable(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PersonalLogDetalhePage(item: item),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.03),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            AppAvatar(
              name: item.alunoNome,
              photoUrl: item.alunoPhotoUrl,
              radius: 20,
              showBorder: false,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.alunoNome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.sessaoNome.isEmpty
                      ? 'Concluiu um treino'
                      : 'Concluiu o treino ${item.sessaoNome}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _tempoRelativo(item.dataHora),
              style: AppTheme.technicalLabel.copyWith(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}