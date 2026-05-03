import 'package:flutter/material.dart';
import '../../../core/models/atencao_item.dart';
import '../../../core/services/personal_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bar_divider.dart';
import '../../alunos/shared/widgets/app_avatar.dart';
import '../../alunos/personal/pages/personal_aluno_perfil_page.dart';

class PersonalAtencaoPage extends StatefulWidget {
  final PersonalService personalService;

  const PersonalAtencaoPage({super.key, required this.personalService});

  @override
  State<PersonalAtencaoPage> createState() => _PersonalAtencaoPageState();
}

class _PersonalAtencaoPageState extends State<PersonalAtencaoPage> {
  late Future<List<AtencaoItem>> _itensFuture;

  @override
  void initState() {
    super.initState();
    _itensFuture = widget.personalService.fetchAtencaoItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: const Text('Atenção necessária'),
        bottom: const AppBarDivider(),
      ),
      body: FutureBuilder<List<AtencaoItem>>(
        future: _itensFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar alertas.',
                style: AppTheme.cardSubtitle,
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 48,
                    color: AppColors.primary.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tudo em ordem por aqui!',
                    style: AppTheme.cardTitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhum aluno precisa de atenção imediata.',
                    style: AppTheme.cardSubtitle,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.paddingScreen,
              vertical: SpacingTokens.screenTopPadding,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _AtencaoCard(item: item);
            },
          );
        },
      ),
    );
  }
}

class _AtencaoCard extends StatelessWidget {
  final AtencaoItem item;

  const _AtencaoCard({required this.item});


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PersonalAlunoPerfilPage(
              alunoId: item.alunoId,
              alunoNome: item.alunoNome,
              photoUrl: item.alunoPhotoUrl,
            ),
          ),
        ),
        child: Padding(
          padding: CardTokens.padding,
          child: Row(
            children: [
              AppAvatar(
                name: item.alunoNome,
                photoUrl: item.alunoPhotoUrl,
                radius: AvatarTokens.md,
                showBorder: false,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(item.alunoNome, style: AppTheme.cardTitle),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: item.tipo.color.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.tipo.label.toUpperCase(),
                            style: AppTheme.caption.copyWith(
                              color: item.tipo.color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.descricao,
                      style: AppTheme.cardSubtitle.copyWith(
                        color: item.tipo == TipoAtencao.feedbackCritico
                          ? item.tipo.color
                          : AppColors.labelSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                item.tipo.icon,
                size: 20,
                color: item.tipo.color.withAlpha(150),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.labelSecondary.withAlpha(80),
              ),
            ],
          ),
        ),
      ),
    );
  }
}