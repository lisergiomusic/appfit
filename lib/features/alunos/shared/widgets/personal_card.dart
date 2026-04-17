import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import 'aluno_avatar.dart';

class PersonalCard extends StatelessWidget {
  final String nome;
  final String? especialidade;
  final String? photoUrl;
  final String? telefone;

  const PersonalCard({
    super.key,
    required this.nome,
    this.especialidade,
    this.photoUrl,
    this.telefone,
  });

  Future<void> _abrirWhatsApp(BuildContext context, String telefone) async {
    final numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/55$numeroLimpo');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o WhatsApp')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao tentar abrir o WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = telefone != null && telefone!.trim().isNotEmpty;

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
                showBorder: false,
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
                      Text(especialidade!, style: AppTheme.caption2),
                    ],
                  ],
                ),
              ),
            ),
            // WhatsApp button
            Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: hasPhone
                    ? AppColors.primary.withAlpha(20)
                    : AppColors.fillSecondary,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                child: InkWell(
                  onTap: hasPhone ? () => _abrirWhatsApp(context, telefone!) : null,
                  splashColor: AppColors.splash,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            ),
          ],
        ),
      ),
    );
  }
}