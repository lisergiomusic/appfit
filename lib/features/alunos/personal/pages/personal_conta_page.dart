import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/app_ui_utils.dart';
import '../../../../core/utils/auth_utils.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../aluno/pages/aluno_seguranca_page.dart';
import 'personal_editar_perfil_page.dart';
import '../../../treinos/personal/pages/personal_exercicios_library_page.dart';

/// Página de Ajustes/Conta do Personal com estética Neo-Industrial Glass Console.
/// Consolida todas as configurações em uma interface de painel único e tátil.
class PersonalContaPage extends StatefulWidget {
  final String uid;

  const PersonalContaPage({super.key, required this.uid});

  @override
  State<PersonalContaPage> createState() => _PersonalContaPageState();
}

class _PersonalContaPageState extends State<PersonalContaPage> {
  late final UserService _service;

  @override
  void initState() {
    super.initState();
    _service = UserService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Atmosfera Superior
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

          // Conteúdo Principal
          StreamBuilder<Map<String, dynamic>>(
            stream: _service.getProfileStream(widget.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(
                  child: Text(
                    'ERRO AO CARREGAR PERFIL',
                    style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                );
              }

              final personalData = snapshot.data!;
              final nome = personalData['nome'] as String? ?? 'Personal';
              final sobrenome = personalData['sobrenome'] as String? ?? '';
              final nomeCompleto = '$nome $sobrenome'.trim();
              final photoUrl = personalData['photoUrl'] as String?;

              return CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  // Espaçamento superior fora do console para permitir o scroll limpo
                  SliverToBoxAdapter(
                    child: SizedBox(height: MediaQuery.of(context).padding.top + 76),
                  ),

                  // Console de Vidro Único
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
                          // Hero Section Integrada no topo do console
                          _buildHero(
                            nomeCompleto: nomeCompleto,
                            photoUrl: photoUrl,
                          ),

                          const SizedBox(height: 32),
                          _buildSectionHeader('GESTÃO E PERFIL'),

                          _buildMenuItem(
                            icon: CupertinoIcons.person_crop_circle,
                            label: 'EDITAR PERFIL',
                            subtitle: 'NOME, ESPECIALIDADE E CONTATO',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PersonalEditarPerfilPage(uid: widget.uid),
                              ),
                            ),
                          ),
                          _buildMenuItem(
                            icon: CupertinoIcons.book,
                            label: 'BIBLIOTECA DE EXERCÍCIOS',
                            subtitle: 'GERENCIAR EXERCÍCIOS BASE',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PersonalExerciciosLibraryPage(),
                              ),
                            ),
                          ),
                          _buildMenuItem(
                            icon: CupertinoIcons.money_dollar_circle,
                            label: 'FINANCEIRO',
                            subtitle: 'BALANÇO GERAL E FATURAMENTO',
                            onTap: () => AppUIUtils.showFutureFeatureWarning(context),
                          ),

                          const SizedBox(height: 24),
                          _buildSectionHeader('SEGURANÇA E APP'),

                          _buildMenuItem(
                            icon: CupertinoIcons.shield,
                            label: 'SEGURANÇA',
                            subtitle: 'SENHA E E-MAIL DE ACESSO',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AlunoSegurancaPage(),
                              ),
                            ),
                          ),
                          _buildMenuItem(
                            icon: CupertinoIcons.settings,
                            label: 'CONFIGURAÇÕES DO APP',
                            subtitle: 'IDIOMA E APARÊNCIA',
                            onTap: () => AppUIUtils.showFutureFeatureWarning(context),
                          ),

                          const SizedBox(height: 48),

                          // Danger Zone
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: _buildMenuItem(
                              icon: CupertinoIcons.power,
                              label: 'SAIR DA CONTA',
                              labelColor: AppColors.systemRed,
                              iconColor: AppColors.systemRed,
                              showChevron: false,
                              onTap: () => AuthUtils.confirmarESair(context),
                            ),
                          ),
                          
                          // Buffer de vidro para o efeito infinito
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Header Customizado
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.2),
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            'Ajustes',
                            style: AppTheme.pageTitle,
                          ),
                          // Ações Laterais
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AppTappable(
                                onPressed: () => AppUIUtils.showFutureFeatureWarning(context),
                                child: Stack(
                                  children: [
                                    Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white.withValues(alpha: 0.4),
                                      size: 24,
                                    ),
                                    Positioned(
                                      right: 2,
                                      top: 2,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: AppColors.systemRed,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.black, width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói a seção Hero com Avatar e Nome do Personal.
  Widget _buildHero({
    required String nomeCompleto,
    required String? photoUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 8),
      child: Column(
        children: [
          AppAvatar(
            name: nomeCompleto,
            photoUrl: photoUrl,
            radius: 42,
            showBorder: true,
          ),
          const SizedBox(height: 16),
          Text(
            nomeCompleto,
            style: AppTheme.heroTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'PERSONAL TRAINER',
            style: AppTheme.heroSubtitle.copyWith(
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói um cabeçalho de seção técnica.
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        title,
        style: AppTheme.technicalLabel.copyWith(
          color: Colors.white.withValues(alpha: 0.2),
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  /// Constrói um item de menu tátil e integrado ao Glass Console.
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
    Color? labelColor,
    Color? iconColor,
    bool showChevron = true,
  }) {
    return AppTappable(
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
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
            Icon(
              icon,
              color: iconColor ?? Colors.white.withValues(alpha: 0.2),
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: labelColor ?? Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              Icon(
                CupertinoIcons.chevron_right,
                color: Colors.white.withValues(alpha: 0.1),
                size: 14,
              ),
          ],
        ),
      ),
    );
  }
}