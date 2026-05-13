import 'package:appfit/features/dashboard/personal/personal_atencao_page.dart';
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
      backgroundColor: AppColors.surfaceBlack,
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

          Positioned.fill(
            child: SafeArea(
              top: true,
              bottom: false,
              child: FutureBuilder<Map<String, dynamic>>(
                future: _profileFuture,
                builder: (context, profileSnapshot) {
                  final personalData = profileSnapshot.data;
                  final nome = personalData?['nome']?.toString().split(' ')[0] ?? "PERSONAL";
                  final photoUrl = (personalData?['photo_url'] ?? personalData?['photoUrl'])?.toString();

                  return CustomScrollView(
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      // Header Sliver Compacto (Apple Inspired)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: SpacingTokens.lg,
                            left: SpacingTokens.xl,
                            right: SpacingTokens.lg,
                            bottom: SpacingTokens.xxl,
                          ),
                          child: Row(
                            children: [
                              AppAvatar(
                                name: nome,
                                photoUrl: photoUrl,
                                radius: 20,
                                showBorder: true,
                              ),
                              const SizedBox(width: SpacingTokens.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getSaudacao(),
                                      style: AppTheme.technicalLabel.copyWith(
                                        color: Colors.white.withValues(alpha: GlassTokens.opacityLabel),
                                        fontSize: 9,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      nome,
                                      style: AppTheme.headerTitle,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: SpacingTokens.md),
                              GlassIconButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PersonalNotificationsPage())
                                ),
                                icon: Icons.notifications_outlined,
                                size: 40,
                                iconSize: 20,
                                color: Colors.white.withValues(alpha: GlassTokens.opacityBorder),
                              ),
                            ],
                          ),
                        ),
                      ),
                  // Seção de KPIs Flutuantes (Fora do Console de Vidro)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.xl,
                        vertical: SpacingTokens.sm,
                      ),
                      child: FutureBuilder<ContagemAlunos>(
                        future: _contagensFuture,
                        builder: (context, snapshot) {
                          final contagens = snapshot.data;

                          return Row(
                            children: [
                              // Card: Alunos Ativos (Ratio)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(SpacingTokens.xl),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: GlassTokens.opacityConsole),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: GlassTokens.opacityBorder),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.group_rounded,
                                            size: 12,
                                            color: AppColors.primary.withValues(alpha: GlassTokens.opacityIconPrimary),
                                          ),
                                          const SizedBox(width: SpacingTokens.space6),
                                          Text(
                                            'ALUNOS ATIVOS',
                                            style: AppTheme.technicalLabel.copyWith(
                                              fontSize: 8,
                                              color: Colors.white.withValues(alpha: GlassTokens.opacityLabel),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: SpacingTokens.md),
                                      RichText(
                                        text: TextSpan(
                                          style: AppTheme.title1.copyWith(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                          children: [
                                            TextSpan(text: snapshot.data?.ativos.toString() ?? '--'),
                                            TextSpan(
                                              text: '/${snapshot.data?.total.toString() ?? '--'}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white.withValues(alpha: GlassTokens.opacityTertiaryText),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: SpacingTokens.md),
                              // Card: Alunos em Risco
                              Expanded(
                                child: AppTappable(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => PersonalAtencaoPage(personalService: _personalService)),
                                  ).then((_) => _refreshContagens()),
                                  child: Container(
                                    padding: const EdgeInsets.all(SpacingTokens.xl),
                                    decoration: BoxDecoration(
                                      color: (contagens?.risco ?? 0) > 0
                                          ? AppColors.systemRed.withValues(alpha: GlassTokens.opacityBorder)
                                          : Colors.white.withValues(alpha: GlassTokens.opacityConsole),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                      border: Border.all(
                                        color: (contagens?.risco ?? 0) > 0
                                            ? AppColors.systemRed.withValues(alpha: GlassTokens.opacityHighBorder)
                                            : Colors.white.withValues(alpha: GlassTokens.opacityBorder),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.warning_rounded,
                                              size: 12,
                                              color: (contagens?.risco ?? 0) > 0
                                                  ? AppColors.systemRed
                                                  : Colors.white.withValues(alpha: GlassTokens.opacityLabel)
                                            ),
                                            const SizedBox(width: SpacingTokens.space6),
                                            Text(
                                              'ALUNOS EM RISCO',
                                              style: AppTheme.technicalLabel.copyWith(
                                                fontSize: 8,
                                                color: (contagens?.risco ?? 0) > 0
                                                    ? AppColors.systemRed.withValues(alpha: GlassTokens.opacitySecondaryText)
                                                    : Colors.white.withValues(alpha: GlassTokens.opacityLabel),
                                              ),
                                            ),                                          ],
                                        ),
                                        const SizedBox(height: SpacingTokens.md),
                                        Text(
                                          contagens?.risco.toString() ?? '--',
                                          style: AppTheme.title1.copyWith(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: (contagens?.risco ?? 0) > 0
                                                ? AppColors.systemRed
                                                : Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: SpacingTokens.lg)),
                  // Console de Vidro Principal
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
                          const SizedBox(height: SpacingTokens.xxxl),

                          // Seção: Atividade Recente (Log)
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
                'LOG VAZIO',
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
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.xxl,
          vertical: SpacingTokens.lg,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: GlassTokens.opacitySurface),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  _tempoRelativo(item.dataHora),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: GlassTokens.opacityTertiaryText),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Container(
                  width: 2,
                  height: 20,
                  color: AppColors.primary.withValues(alpha: GlassTokens.opacityTertiaryText),
                ),
              ],
            ),
            const SizedBox(width: SpacingTokens.lg),
            AppAvatar(
              name: item.alunoNome,
              photoUrl: item.alunoPhotoUrl,
              radius: 16,
              showBorder: false,
            ),
            const SizedBox(width: SpacingTokens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.alunoNome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.sessaoNome.isEmpty
                        ? 'Concluiu um treino avulso'
                        : "Concluiu o treino '${item.sessaoNome}'",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: GlassTokens.opacityLabel),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: GlassTokens.opacityBadgeBorder),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}