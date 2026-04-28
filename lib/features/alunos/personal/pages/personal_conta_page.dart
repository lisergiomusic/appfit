import 'package:flutter/material.dart';
import '../../../../core/utils/app_ui_utils.dart';
import '../../../../core/utils/auth_utils.dart';
import '../../../../core/services/aluno_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/settings/settings_group.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../aluno/pages/aluno_seguranca_page.dart';

class PersonalContaPage extends StatefulWidget {
  final String uid;

  const PersonalContaPage({super.key, required this.uid});

  @override
  State<PersonalContaPage> createState() => _PersonalContaPageState();
}

class _PersonalContaPageState extends State<PersonalContaPage> {
  late final AlunoService _service;

  @override
  void initState() {
    super.initState();
    _service = AlunoService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text('Ajustes'),
        ),
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
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _service.getPersonalPerfilStream(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text(
                'Erro ao carregar perfil',
                style: TextStyle(color: AppColors.labelSecondary),
              ),
            );
          }

          final personalData = snapshot.data!;
          final nome = personalData['nome'] as String? ?? 'Personal';
          final sobrenome = personalData['sobrenome'] as String? ?? '';
          final nomeCompleto = '$nome $sobrenome'.trim();
          final photoUrl = personalData['photoUrl'] as String?;
          final especialidade = personalData['especialidade'] as String? ?? 'Geral';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero ──────────────────────────────────────────
                _buildHero(
                  nomeCompleto: nomeCompleto,
                  photoUrl: photoUrl,
                  especialidade: especialidade,
                ),
                const SizedBox(height: SpacingTokens.sectionGap + 8),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.screenHorizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Configurações do Personal ─────────────────────────
                      Padding(
                        padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                        child: Text(
                          'Minha conta',
                          style: AppTheme.sectionHeader,
                        ),
                      ),
                      SettingsGroup(items: [
                        SettingsItem(
                          icon: Icons.person_rounded,
                          iconColor: AppColors.labelSecondary,
                          label: 'Editar perfil',
                          subtitle: 'Nome, especialidade e contato',
                          onTap: () => AppUIUtils.showFutureFeatureWarning(context),
                        ),
                        SettingsItem(
                          icon: Icons.library_books_rounded,
                          iconColor: AppColors.labelSecondary,
                          label: 'Biblioteca de exercícios',
                          subtitle: 'Gerenciar exercícios base',
                          onTap: () => AppUIUtils.showFutureFeatureWarning(context),
                        ),
                        SettingsItem(
                          icon: Icons.receipt_long_rounded,
                          iconColor: AppColors.labelSecondary,
                          label: 'Financeiro',
                          subtitle: 'Balanço geral e faturamento',
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

                      const SizedBox(height: SpacingTokens.screenBottomPadding),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero({
    required String nomeCompleto,
    required String? photoUrl,
    required String especialidade,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SpacingTokens.screenHorizontalPadding,
          SpacingTokens.screenTopPadding,
          SpacingTokens.screenHorizontalPadding,
          0,
        ),
        child: Column(
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
            const SizedBox(height: 4),
            Text(
              especialidade,
              style: AppTheme.caption.copyWith(
                color: AppColors.labelSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}