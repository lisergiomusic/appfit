import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/personal_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_ui_utils.dart';
import '../../../../core/widgets/app_nav_back_button.dart';
import '../../../../core/widgets/app_tappable.dart';
import '../../shared/widgets/app_avatar.dart';
import 'personal_editar_aluno_page.dart';
import 'personal_financeiro_aluno_page.dart';

/// Página de gerenciamento administrativo do aluno.
/// Implementa a interface Glass Console com foco em segurança e ações administrativas.
class PersonalGerenciarAlunoPage extends StatefulWidget {
  final String alunoId;
  final String alunoNome;

  const PersonalGerenciarAlunoPage({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  State<PersonalGerenciarAlunoPage> createState() =>
      _PersonalGerenciarAlunoPageState();
}

class _PersonalGerenciarAlunoPageState
    extends State<PersonalGerenciarAlunoPage> {
  final PersonalService _personalService = PersonalService();
  final UserService _userService = UserService();

  late String _alunoNome;
  String? _photoUrl;
  DateTime? _dataCadastro;

  @override
  void initState() {
    super.initState();
    _alunoNome = widget.alunoNome;
    _buscarDadosAluno();
  }

  /// Busca dados atualizados do perfil do aluno no backend.
  Future<void> _buscarDadosAluno() async {
    try {
      final data = await _userService.getProfile(widget.alunoId);
      if (data.isNotEmpty && mounted) {
        setState(() {
          _alunoNome = '${data['nome'] ?? ''} ${data['sobrenome'] ?? ''}'.trim();
          _photoUrl = data['photo_url'];
          if (data['data_cadastro'] != null) {
            _dataCadastro = DateTime.tryParse((data['data_cadastro']).toString());
          }
        });
      }
    } catch (e) {
      debugPrint("Erro ao buscar dados do aluno: $e");
    }
  }

  /// Navega para a edição cadastral.
  Future<void> _irParaEditar(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalEditarAlunoPage(alunoId: widget.alunoId),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      _buscarDadosAluno();
    }
  }

  /// Navega para o módulo financeiro.
  void _irParaFinanceiro(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalFinanceiroAlunoPage(
          alunoId: widget.alunoId,
          alunoNome: _alunoNome,
          photoUrl: _photoUrl,
          dataCriacao: _dataCadastro,
        ),
      ),
    );
  }

  /// Copia link ou envia convite de acesso.
  void _enviarConviteApp(BuildContext context) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('LINK DE CONVITE COPIADO'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Altera status de bloqueio do aluno.
  void _alternarBloqueio(BuildContext context) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ACESSO BLOQUEADO'),
        backgroundColor: Colors.orangeAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Exibe o modal de exclusão com estética de vidro e gradiente volumétrico.
  Future<void> _excluirAluno(BuildContext context) async {
    HapticFeedback.heavyImpact();
    final confirmar = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
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
                      const Color(0xFF1A1A1A),
                      Colors.black,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(GlassTokens.consoleRadius),
                    topRight: Radius.circular(GlassTokens.consoleRadius),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: SafeArea(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Icon(CupertinoIcons.delete, color: Colors.redAccent, size: 40),
                      const SizedBox(height: 24),
                      Text(
                        'REMOVER ALUNO',
                        style: AppTheme.technicalLabel.copyWith(color: Colors.redAccent),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Deseja remover $_alunoNome definitivamente? Esta ação não pode ser desfeita.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: AppTappable(
                              onPressed: () => Navigator.pop(context, false),
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
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTappable(
                              onPressed: () => Navigator.pop(context, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                                ),
                                child: const Center(
                                  child: Text(
                                    'EXCLUIR',
                                    style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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

    if (confirmar == true) {
      try {
        await _personalService.deletarAluno(widget.alunoId);
        if (context.mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } catch (e) {
        debugPrint("Erro ao excluir aluno: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nomeExibicao = _alunoNome.toTitleCase();

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

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Dinâmico com SliverAppBar
              SliverAppBar(
                pinned: true,
                expandedHeight: SpacingTokens.headerExpanded,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                leading: const AppNavBackButton(),
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final double collapsedHeight = MediaQuery.of(context).padding.top + kToolbarHeight;
                    final double expandedHeight = SpacingTokens.headerExpanded;
                    final double collapseProgress = ((expandedHeight - constraints.biggest.height) / (expandedHeight - collapsedHeight)).clamp(0.0, 1.0);

                    return Stack(
                      children: [
                        if (collapseProgress > 0.9)
                          Positioned.fill(
                            child: ClipRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                child: Container(color: Colors.black.withValues(alpha: 0.5)),
                              ),
                            ),
                          ),
                        FlexibleSpaceBar(
                          centerTitle: true,
                          title: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: collapseProgress > 0.8 ? 1.0 : 0.0,
                            child: Text(
                              'Gerenciar Aluno',
                              style: AppTheme.pageTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                          ),
                          background: Container(
                            padding: EdgeInsets.only(
                              top: 100 - (20 * collapseProgress),
                              left: 20,
                              right: 20,
                            ),
                            child: Opacity(
                              opacity: (1.0 - (collapseProgress * 1.5)).clamp(0.0, 1.0),
                              child: Row(
                                children: [
                                  AppAvatar(
                                    name: nomeExibicao,
                                    photoUrl: _photoUrl,
                                    radius: 32,
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          nomeExibicao,
                                          style: AppTheme.bigTitle.copyWith(fontSize: 22),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _dataCadastro != null
                                              ? 'ALUNO DESDE ${DateFormat("MMMM 'DE' y", "pt_BR").format(_dataCadastro!).toUpperCase()}'
                                              : 'STATUS: ATIVO',
                                          style: AppTheme.technicalLabel.copyWith(
                                            color: Colors.white.withValues(alpha: 0.4),
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
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

              // Glass Console Contínuo
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
                    border: Border.all(color: Colors.white.withValues(alpha: GlassTokens.opacityBorder)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      _buildSectionLabel('CONFIGURAÇÕES DO PERFIL'),
                      _buildActionItem(
                        icon: CupertinoIcons.person_crop_circle_fill,
                        title: 'Editar Informações',
                        subtitle: 'Dados pessoais e de contato',
                        onTap: () => _irParaEditar(context),
                      ),
                      _buildActionItem(
                        icon: CupertinoIcons.paperplane_fill,
                        title: 'Enviar Convite do App',
                        subtitle: 'Link de acesso exclusivo',
                        onTap: () => _enviarConviteApp(context),
                      ),

                      const SizedBox(height: 40),

                      _buildSectionLabel('GESTÃO FINANCEIRA'),
                      _buildActionItem(
                        icon: CupertinoIcons.creditcard_fill,
                        title: 'Financeiro do Aluno',
                        subtitle: 'Faturas e histórico de pagamentos',
                        iconColor: AppColors.primary,
                        onTap: () => _irParaFinanceiro(context),
                      ),

                      const SizedBox(height: 40),

                      _buildSectionLabel('ZONA DE SEGURANÇA'),
                      _buildActionItem(
                        icon: CupertinoIcons.lock_fill,
                        title: 'Bloquear Acesso',
                        subtitle: 'Impedir login temporariamente',
                        iconColor: Colors.orangeAccent,
                        onTap: () => _alternarBloqueio(context),
                      ),
                      _buildActionItem(
                        icon: CupertinoIcons.trash_fill,
                        title: 'Excluir Aluno',
                        subtitle: 'Remover dados permanentemente',
                        iconColor: Colors.redAccent,
                        onTap: () => _excluirAluno(context),
                      ),

                      const SizedBox(height: 120),
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

  /// Constrói um rótulo de seção com tipografia técnica.
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(label, style: AppTheme.sectionHeader),
    );
  }

  /// Constrói um item de ação modular com resposta tátil e escala.
  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return AppTappable(
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(GlassTokens.itemRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.white).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, color: Colors.white.withValues(alpha: 0.1), size: 16),
          ],
        ),
      ),
    );
  }
}