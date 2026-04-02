import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/aluno_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bar_divider.dart';
import '../alunos/models/aluno_perfil_data.dart';

class AlunoHomePage extends StatelessWidget {
  final String uid;
  const AlunoHomePage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final service = AlunoService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Início'),
        bottom: const AppBarDivider(),
      ),
      body: StreamBuilder<AlunoPerfilData>(
        stream: service.getAlunoPerfilCompletoStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                'Erro ao carregar dados.',
                style: TextStyle(color: AppColors.labelSecondary),
              ),
            );
          }

          final data = snapshot.data!;
          final aluno = data.aluno;
          final rotina = data.rotinaAtiva;

          final nome = aluno['nome']?.toString().split(' ')[0] ?? 'Aluno';
          final photoUrl = aluno['photoUrl'] as String?;
          final ultimoTreino = aluno['ultimoTreino'] as Timestamp?;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingScreen,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: SpacingTokens.screenTopPadding),
                  _buildHeader(nome, photoUrl),
                  const SizedBox(height: SpacingTokens.xxl),
                  Text('Seu treino', style: AppTheme.sectionHeader),
                  const SizedBox(height: SpacingTokens.labelToField),
                  rotina != null
                      ? _buildRotinaCard(rotina, ultimoTreino)
                      : _buildSemTreinoCard(),
                  if (rotina != null) ...[
                    const SizedBox(height: SpacingTokens.sectionGap),
                    Text('Sessões', style: AppTheme.sectionHeader),
                    const SizedBox(height: SpacingTokens.labelToField),
                    _buildSessoesList(rotina),
                  ],
                  const SizedBox(height: SpacingTokens.screenBottomPadding),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String nome, String? photoUrl) {
    return Row(
      children: [
        CircleAvatar(
          radius: AvatarTokens.lg,
          backgroundColor: AppColors.surfaceLight,
          backgroundImage:
              photoUrl != null && photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
          child:
              photoUrl == null || photoUrl.isEmpty
                  ? const Icon(
                      Icons.person_rounded,
                      color: AppColors.labelSecondary,
                      size: 28,
                    )
                  : null,
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_getSaudacao()}, $nome', style: AppTheme.title1),
            const SizedBox(height: SpacingTokens.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                'Aluno',
                style: AppTheme.caption2.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRotinaCard(
    Map<String, dynamic> rotina,
    Timestamp? ultimoTreino,
  ) {
    final nomeRotina = rotina['nome'] as String? ?? 'Meu treino';
    final sessoes = (rotina['sessoes'] as List?)?.length ?? 0;
    final tipoVencimento = rotina['tipoVencimento'] as String?;

    String vencimentoText = '';
    if (tipoVencimento == 'data') {
      final ts = rotina['dataVencimento'] as Timestamp?;
      if (ts != null) {
        vencimentoText =
            "Vence em ${DateFormat("d 'de' MMM", 'pt_BR').format(ts.toDate())}";
      }
    } else if (tipoVencimento == 'sessoes') {
      final alvo = rotina['vencimentoSessoes'] as int?;
      if (alvo != null) vencimentoText = '$alvo sessões no plano';
    }

    final int diasDesdeUltimoTreino =
        ultimoTreino != null
            ? DateTime.now().difference(ultimoTreino.toDate()).inDays
            : -1;

    String ultimoTreinoText;
    Color ultimoTreinoCor;
    if (diasDesdeUltimoTreino < 0) {
      ultimoTreinoText = 'Nenhum treino registrado';
      ultimoTreinoCor = AppColors.labelSecondary;
    } else if (diasDesdeUltimoTreino == 0) {
      ultimoTreinoText = 'Você treinou hoje!';
      ultimoTreinoCor = AppColors.primary;
    } else if (diasDesdeUltimoTreino == 1) {
      ultimoTreinoText = 'Último treino: ontem';
      ultimoTreinoCor = AppColors.labelSecondary;
    } else {
      ultimoTreinoText = 'Último treino: há $diasDesdeUltimoTreino dias';
      ultimoTreinoCor =
          diasDesdeUltimoTreino >= 7
              ? AppColors.accentMetrics
              : AppColors.labelSecondary;
    }

    return Container(
      width: double.infinity,
      decoration: AppTheme.cardDecoration,
      padding: CardTokens.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nomeRotina, style: AppTheme.cardTitle),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            '$sessoes ${sessoes == 1 ? 'sessão' : 'sessões'}',
            style: AppTheme.cardSubtitle,
          ),
          if (vencimentoText.isNotEmpty) ...[
            const SizedBox(height: SpacingTokens.sm),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 12,
                  color: AppColors.labelSecondary,
                ),
                const SizedBox(width: 4),
                Text(vencimentoText, style: AppTheme.caption),
              ],
            ),
          ],
          const SizedBox(height: SpacingTokens.sm),
          Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.separator,
          ),
          const SizedBox(height: SpacingTokens.sm),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 12,
                color: ultimoTreinoCor,
              ),
              const SizedBox(width: 4),
              Text(
                ultimoTreinoText,
                style: AppTheme.caption.copyWith(color: ultimoTreinoCor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSemTreinoCard() {
    return Container(
      width: double.infinity,
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.cardPaddingH,
        vertical: SpacingTokens.xxl,
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 40,
            color: AppColors.labelSecondary.withAlpha(80),
          ),
          const SizedBox(height: SpacingTokens.sm),
          const Text('Nenhum treino atribuído', style: AppTheme.cardTitle),
          const SizedBox(height: SpacingTokens.xs),
          const Text(
            'Aguarde seu personal atribuir uma rotina.',
            style: AppTheme.cardSubtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSessoesList(Map<String, dynamic> rotina) {
    final sessoes = (rotina['sessoes'] as List?) ?? [];
    if (sessoes.isEmpty) return const SizedBox.shrink();

    return Column(
      children: sessoes.asMap().entries.map((entry) {
        final i = entry.key;
        final sessao = entry.value as Map<String, dynamic>? ?? {};
        final nomeSessao =
            sessao['nome'] as String? ??
            'Treino ${String.fromCharCode(65 + i)}';
        final exercicios = (sessao['exercicios'] as List?)?.length ?? 0;
        final isLast = i == sessoes.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : SpacingTokens.listItemGap),
          child: Container(
            decoration: AppTheme.cardDecoration,
            padding: CardTokens.padding,
            child: Row(
              children: [
                Container(
                  width: ThumbnailTokens.md,
                  height: ThumbnailTokens.md,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + i),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nomeSessao, style: AppTheme.cardTitle),
                      const SizedBox(height: SpacingTokens.xs),
                      Text(
                        '$exercicios ${exercicios == 1 ? 'exercício' : 'exercícios'}',
                        style: AppTheme.cardSubtitle,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.labelSecondary.withAlpha(80),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getSaudacao() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) return 'Bom dia';
    if (hora >= 12 && hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }
}
