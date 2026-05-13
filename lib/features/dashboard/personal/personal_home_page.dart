import 'dart:ui';
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
import '../../financeiro/personal/pages/personal_financeiro_page.dart';
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
                  // Header Sliver Compacto (Apple Inspired)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 16,
                        left: 20,
                        right: 16,
                        bottom: 24,
                      ),
                      child: Row(
                        children: [
                          AppAvatar(
                            name: nome,
                            photoUrl: photoUrl,
                            radius: 20,
                            showBorder: true,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getSaudacao(),
                                  style: AppTheme.technicalLabel.copyWith(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 9,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  nome,
                                  style: AppTheme.heroTitle.copyWith(
                                    fontSize: 22,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GlassIconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PersonalNotificationsPage())
                            ),
                            icon: Icons.notifications_outlined,
                            size: 40,
                            iconSize: 20,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                          // Linha 1: Comunidade & Engajamento (Simétrica)
                          IntrinsicHeight(
                            child: FutureBuilder<ContagemAlunos>(
                              future: _contagensFuture,
                              builder: (context, snapshot) {
                                final contagens = snapshot.data;
                                final ativos = contagens?.ativos.toString() ?? '--';
                                return Row(
                                  children: [
                                    // Alunos Ativos
                                    Expanded(
                                      child: AppTappable(
                                        onPressed: () {},
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.group_rounded, size: 12, color: AppColors.primary.withValues(alpha: 0.5)),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'BASE DE ALUNOS',
                                                    style: AppTheme.technicalLabel.copyWith(
                                                      fontSize: 8,
                                                      color: Colors.white.withValues(alpha: 0.3),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                ativos,
                                                style: AppTheme.title1.copyWith(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.w900,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'EM TREINAMENTO',
                                                style: AppTheme.technicalLabel.copyWith(
                                                  fontSize: 7,
                                                  color: Colors.white.withValues(alpha: 0.2),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Divisor Vertical
                                    Container(
                                      width: 1,
                                      color: Colors.white.withValues(alpha: 0.05),
                                    ),
                                    // Bloco Engajamento Animado
                                    Expanded(
                                      child: AppTappable(
                                        onPressed: () {},
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.local_fire_department_rounded, size: 12, color: AppColors.primary.withValues(alpha: 0.5)),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'ENGAJAMENTO',
                                                    style: AppTheme.technicalLabel.copyWith(
                                                      fontSize: 8,
                                                      color: Colors.white.withValues(alpha: 0.3),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              TweenAnimationBuilder<double>(
                                                tween: Tween<double>(begin: 0.0, end: 0.75),
                                                duration: const Duration(milliseconds: 1500),
                                                curve: Curves.easeOutBack,
                                                builder: (context, value, child) {
                                                  return SizedBox(
                                                    width: 48,
                                                    height: 48,
                                                    child: Stack(
                                                      alignment: Alignment.center,
                                                      children: [
                                                        CircularProgressIndicator(
                                                          value: 1.0,
                                                          strokeWidth: 5,
                                                          color: Colors.white.withValues(alpha: 0.05),
                                                        ),
                                                        CircularProgressIndicator(
                                                          value: value,
                                                          strokeWidth: 5,
                                                          backgroundColor: Colors.transparent,
                                                          color: AppColors.primary,
                                                          strokeCap: StrokeCap.round,
                                                        ),
                                                        Text(
                                                          '${(value * 100).toInt()}%',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w900,
                                                            color: Colors.white,
                                                            fontFamily: 'monospace',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'META DE FREQUÊNCIA',
                                                style: AppTheme.technicalLabel.copyWith(
                                                  fontSize: 7,
                                                  color: Colors.white.withValues(alpha: 0.2),
                                                  letterSpacing: 0.5,
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

                          // Divisor Horizontal
                          Container(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),

                          // Seção: Atenção Crítica (Feed)
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            title: 'ATENÇÃO CRÍTICA',
                            onAction: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PersonalAtencaoPage(personalService: _personalService)),
                            ).then((_) => _refreshContagens()),
                          ),
                          _AtencaoCriticaFeedSection(contagensFuture: _contagensFuture, personalService: _personalService),

                          const SizedBox(height: 24),
                          // Seção: Atividade Recente
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

class _AtencaoCriticaFeedSection extends StatelessWidget {
  final Future<ContagemAlunos>? contagensFuture;
  final PersonalService personalService;

  const _AtencaoCriticaFeedSection({required this.contagensFuture, required this.personalService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ContagemAlunos>(
      future: contagensFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 1, color: AppColors.systemRed)));
        }

        final risco = snapshot.data?.risco ?? 0;

        if (risco == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: AppColors.primary.withValues(alpha: 0.5), size: 16),
                const SizedBox(width: 8),
                Text(
                  'NENHUM ALUNO EM RISCO. EXCELENTE TRABALHO.',
                  style: AppTheme.technicalLabel.copyWith(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          );
        }

        return AppTappable(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PersonalAtencaoPage(personalService: personalService)),
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.systemRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_rounded, color: AppColors.systemRed, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$risco ALUNO${risco > 1 ? 'S' : ''} EM RISCO DE CHURN',
                        style: const TextStyle(
                          color: AppColors.systemRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Alunos sem treino há mais de 7 dias.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.2), size: 16),
              ],
            ),
          ),
        );
      },
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