import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/aluno_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import '../../shared/models/aluno_perfil_data.dart';
import '../../shared/widgets/aluno_avatar.dart';

class AlunoPerfilPage extends StatefulWidget {
  final String uid;

  const AlunoPerfilPage({super.key, required this.uid});

  @override
  State<AlunoPerfilPage> createState() => _AlunoPerfilPageState();
}

class _AlunoPerfilPageState extends State<AlunoPerfilPage> {
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


  Future<void> _abrirWhatsApp(String telefone) async {
    final numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/55$numeroLimpo');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sair(BuildContext context) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirma ?? false) {
      await AuthService().signOut();
      if (mounted && context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ChecagemPagina()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text('Meu Perfil'),
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
            onPressed: () {},
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
          final photoUrl = alunoData['photoUrl'] as String?;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(
                  nomeCompleto: nomeCompleto,
                  photoUrl: photoUrl,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.screenHorizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: SpacingTokens.xxl),

                      // ── Personal ──────────────────────────────────────────
                      if (data.nomePersonal != null) ...[
                        _buildPersonalCard(
                          nome: data.nomePersonal!,
                          especialidade: data.especialidadePersonal,
                          photoUrl: data.photoUrlPersonal,
                          telefone: data.telefonePersonal,
                        ),
                        const SizedBox(height: SpacingTokens.xxl),
                      ],

                      // ── Seções de navegação ────────────────────────────────
                      _buildSettingsGroup([
                        _SettingsItem(
                          icon: Icons.person_rounded,
                          iconColor: AppColors.labelSecondary,
                          label: 'Editar perfil',
                          subtitle: 'Nome, data de nascimento, contato',
                          onTap: () {},
                        ),
                        _SettingsItem(
                          icon: Icons.monitor_weight_outlined,
                          iconColor: AppColors.labelSecondary,
                          label: 'Dados físicos',
                          subtitle: 'Peso, altura, objetivo',
                          onTap: () {},
                        ),
                        _SettingsItem(
                          icon: Icons.shield_outlined,
                          iconColor: AppColors.labelSecondary,
                          label: 'Segurança',
                          subtitle: 'Senha e e-mail de acesso',
                          onTap: () {},
                        ),
                        _SettingsItem(
                          icon: Icons.tune_rounded,
                          iconColor: AppColors.labelSecondary,
                          label: 'Configurações do app',
                          subtitle: 'Idioma e aparência',
                          onTap: () {},
                        ),
                      ]),
                      const SizedBox(height: SpacingTokens.md),

                      // ── Zona de perigo ─────────────────────────────────────
                      _buildSettingsGroup([
                        _SettingsItem(
                          icon: Icons.logout_rounded,
                          iconColor: AppColors.systemRed,
                          label: 'Sair da conta',
                          labelColor: AppColors.systemRed,
                          onTap: () => _sair(context),
                        ),
                        _SettingsItem(
                          icon: Icons.delete_outline_rounded,
                          iconColor: AppColors.systemRed,
                          label: 'Excluir conta',
                          labelColor: AppColors.systemRed,
                          onTap: () {},
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
            child: Column(
              children: [
                AlunoAvatar(
                  alunoNome: nomeCompleto,
                  photoUrl: photoUrl,
                  radius: AvatarTokens.lg,
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
        ],
      ),
    );
  }

  // ─── Personal card ──────────────────────────────────────────────────────────

  Widget _buildPersonalCard({
    required String nome,
    String? especialidade,
    String? photoUrl,
    String? telefone,
  }) {
    final hasPhone = telefone != null && telefone.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Green accent bar
            Container(
              width: 3,
              color: AppColors.primary,
            ),
            const SizedBox(width: 14),
            // Avatar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: AlunoAvatar(
                alunoNome: nome,
                photoUrl: photoUrl,
                radius: AvatarTokens.md,
              ),
            ),
            const SizedBox(width: 12),
            // Name + specialty
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(nome, style: AppTheme.cardTitle),
                    if (especialidade != null) ...[
                      const SizedBox(height: 3),
                      Text(especialidade, style: AppTheme.caption2),
                    ],
                  ],
                ),
              ),
            ),
            // WhatsApp button
            Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: hasPhone ? () => _abrirWhatsApp(telefone) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasPhone
                        ? AppColors.primary.withAlpha(20)
                        : AppColors.fillSecondary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.whatsapp,
                        size: 15,
                        color: hasPhone
                            ? AppColors.primary
                            : AppColors.labelSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Chamar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: hasPhone
                              ? AppColors.primary
                              : AppColors.labelSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Settings helpers ────────────────────────────────────────────────────────

  Widget _buildNavCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.cardPaddingH,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: SpacingTokens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                      color: AppColors.labelPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTheme.caption2),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.labelSecondary.withAlpha(80),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<_SettingsItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildSettingsRow(items[i]),
            if (i < items.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 52,
                color: Color(0x14EBEBF5),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsRow(_SettingsItem item) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SpacingTokens.cardPaddingH,
          vertical: item.subtitle != null ? 12 : 15,
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 19, color: item.iconColor),
            const SizedBox(width: SpacingTokens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                      color: item.labelColor ?? AppColors.labelPrimary,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(item.subtitle!, style: AppTheme.caption2),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.labelSecondary.withAlpha(80),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final Color? labelColor;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    this.labelColor,
    required this.onTap,
  });
}

// ignore: unused_element — será movido para a sub-página de dados físicos
class _PesoEditSheet extends StatefulWidget {
  final String uid;
  final double? pesoAtual;
  final AlunoService service;
  final Function(double) onPesoAtualizado;

  const _PesoEditSheet({
    required this.uid,
    required this.pesoAtual,
    required this.service,
    required this.onPesoAtualizado,
  });

  @override
  State<_PesoEditSheet> createState() => _PesoEditSheetState();
}

class _PesoEditSheetState extends State<_PesoEditSheet> {
  late TextEditingController _pesoController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pesoController = TextEditingController(
      text: widget.pesoAtual?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _pesoController.dispose();
    super.dispose();
  }

  Future<void> _salvarPeso() async {
    final pesoText = _pesoController.text.trim();
    if (pesoText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite um peso válido')));
      return;
    }

    final peso = double.tryParse(pesoText);
    if (peso == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formato inválido. Use números.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final alunoDoc = await widget.service.getAluno(widget.uid);
      final alunoData = alunoDoc.data() as Map<String, dynamic>;

      await widget.service.atualizarAluno(
        alunoId: widget.uid,
        nome: alunoData['nome'] ?? '',
        sobrenome: alunoData['sobrenome'] ?? '',
        email: alunoData['email'] ?? '',
        peso: peso,
      );

      widget.onPesoAtualizado(peso);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Peso atualizado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao atualizar peso: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.only(
        left: SpacingTokens.screenHorizontalPadding,
        right: SpacingTokens.screenHorizontalPadding,
        top: SpacingTokens.lg,
        bottom: keyboardHeight + SpacingTokens.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Atualizar peso', style: AppTheme.title1),
          const SizedBox(height: SpacingTokens.sectionGap),
          TextField(
            controller: _pesoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !_isSaving,
            decoration: InputDecoration(
              hintText: 'Ex: 75.5',
              suffixText: 'kg',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                borderSide: const BorderSide(color: AppColors.fillSecondary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                borderSide: const BorderSide(color: AppColors.fillSecondary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.sectionGap),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.fillSecondary,
                    disabledBackgroundColor: AppColors.fillSecondary.withAlpha(
                      100,
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _salvarPeso,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.labelSecondary,
                            ),
                          ),
                        )
                      : const Text('Salvar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}