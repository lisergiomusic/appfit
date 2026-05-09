import 'package:flutter/material.dart';
import '../../../../core/utils/app_ui_utils.dart';
import '../../../../core/utils/auth_utils.dart';
import '../../../../core/services/aluno_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/settings/settings_group.dart';
import '../../shared/models/aluno_perfil_data.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/personal_card.dart';
import 'aluno_dados_fisicos_page.dart';
import 'aluno_editar_perfil_page.dart';
import 'aluno_seguranca_page.dart';

class AlunoContaPage extends StatefulWidget {
  final String uid;

  const AlunoContaPage({super.key, required this.uid});

  @override
  State<AlunoContaPage> createState() => _AlunoContaPageState();
}

class _AlunoContaPageState extends State<AlunoContaPage> {
  late final AlunoService _service;

  @override
  void initState() {
    super.initState();
    _service = AlunoService();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AlunoPerfilData>(
      stream: _service.getAlunoPerfilCompletoStream(widget.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(child: Text('Erro ao carregar perfil', style: TextStyle(color: AppColors.labelSecondary))),
          );
        }

        final data = snapshot.data!;
        final alunoData = data.aluno;

        final nome = alunoData['nome'] as String? ?? 'Aluno';
        final sobrenome = alunoData['sobrenome'] as String? ?? '';
        final nomeCompleto = '$nome $sobrenome'.trim();
        final photoUrl = (alunoData['photo_url'] ?? alunoData['photoUrl']) as String?;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                collapsedHeight: 60,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.background,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                title: Text(
                  'Minha conta',
                  style: AppTheme.pageTitle.copyWith(fontSize: 18),
                ),
                centerTitle: false,
                actions: [
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(
                          Icons.notifications_rounded,
                          color: AppColors.labelSecondary,
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
                    onPressed: () => AppUIUtils.showFutureFeatureWarning(context),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(gradient: AppTheme.premiumGradient),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _buildHero(
                          nomeCompleto: nomeCompleto,
                          photoUrl: photoUrl,
                          isInsideHeader: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.screenHorizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: SpacingTokens.sectionGap),
                      // ── Personal ──────────────────────────────────────────
                      if (data.nomePersonal != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                          child: Text(
                            'Personal trainer',
                            style: AppTheme.sectionHeader,
                          ),
                        ),
                        PersonalCard(
                          nome: data.nomePersonal!,
                          especialidade: data.especialidadePersonal,
                          photoUrl: data.photoUrlPersonal,
                          telefone: data.telefonePersonal,
                        ),
                        const SizedBox(height: SpacingTokens.sectionGap),
                      ],

                      // ── Seções de navegação ────────────────────────────────
                      SettingsGroup(items: [
                        SettingsItem(
                          icon: Icons.person_rounded,
                          iconColor: AppColors.labelSecondary,
                          label: 'Editar perfil',
                          subtitle: 'Nome, data de nascimento, contato',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlunoEditarPerfilPage(
                                uid: alunoData['id']?.toString() ?? widget.uid,
                              ),
                            ),
                          ),
                        ),
                        SettingsItem(
                          icon: Icons.monitor_weight_outlined,
                          iconColor: AppColors.labelSecondary,
                          label: 'Dados físicos',
                          subtitle: 'Peso, altura, objetivo',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlunoDadosFisicosPage(
                                uid: alunoData['id']?.toString() ?? widget.uid,
                              ),
                            ),
                          ),
                        ),
                        SettingsItem(
                          icon: Icons.receipt_long_rounded,
                          iconColor: AppColors.labelSecondary,
                          label: 'Financeiro',
                          subtitle: 'Faturas, histórico de pagamentos',
                          onTap: () => AppUIUtils.showFutureFeatureWarning(context),
                        ),
                        SettingsItem(
                          icon: Icons.shield_outlined,
                          iconColor: AppColors.labelSecondary,
                          label: 'Segurança',
                          subtitle: 'Senha e e-mail de acesso',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AlunoSegurancaPage(),
                            ),
                          ),
                        ),
                        SettingsItem(
                          icon: Icons.tune_rounded,
                          iconColor: AppColors.labelSecondary,
                          label: 'Configurações do app',
                          subtitle: 'Idioma e aparência',
                          onTap: () => AppUIUtils.showFutureFeatureWarning(context),
                        ),
                      ]),
                      const SizedBox(height: SpacingTokens.sectionGap),

                      // ── Zona de perigo ─────────────────────────────────────
                      SettingsGroup(items: [
                        SettingsItem(
                          icon: Icons.logout_rounded,
                          iconColor: AppColors.systemRed,
                          label: 'Sair da conta',
                          labelColor: AppColors.systemRed,
                          onTap: () => AuthUtils.confirmarESair(context),
                        ),
                      ]),

                      const SizedBox(height: SpacingTokens.screenBottomPadding + 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Hero ───────────────────────────────────────────────────────────────────

  Widget _buildHero({
    required String nomeCompleto,
    required String? photoUrl,
    bool isInsideHeader = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: SpacingTokens.screenHorizontalPadding,
        right: SpacingTokens.screenHorizontalPadding,
        top: isInsideHeader ? SpacingTokens.screenTopPadding + 65 : SpacingTokens.screenTopPadding,
        bottom: isInsideHeader ? 20 : 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppAvatar(
            name: nomeCompleto,
            photoUrl: photoUrl,
            radius: AvatarTokens.lg,
            showBorder: false,
          ),
          const SizedBox(height: 16),
          Text(
            nomeCompleto,
            style: AppTheme.title1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
