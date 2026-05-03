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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text('Minha Conta'),
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
      body: StreamBuilder<AlunoPerfilData>(
        stream: _service.getAlunoPerfilCompletoStream(widget.uid),
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

          final data = snapshot.data!;
          final alunoData = data.aluno;

          final nome = alunoData['nome'] as String? ?? 'Aluno';
          final sobrenome = alunoData['sobrenome'] as String? ?? '';
          final nomeCompleto = '$nome $sobrenome'.trim();
          final photoUrl = (alunoData['photo_url'] ?? alunoData['photoUrl']) as String?;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero ──────────────────────────────────────────
                _buildHero(
                  nomeCompleto: nomeCompleto,
                  photoUrl: photoUrl,
                ),
                const SizedBox(height: SpacingTokens.sectionGap + 8),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.screenHorizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              builder: (_) => AlunoDadosFisicosPage(uid: widget.uid),
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

  // ─── Hero ───────────────────────────────────────────────────────────────────

  Widget _buildHero({
    required String nomeCompleto,
    required String? photoUrl,
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
          ],
        ),
      ),
    );
  }
}