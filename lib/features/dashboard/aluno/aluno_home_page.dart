import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/aluno_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bar_divider.dart';
import '../../alunos/shared/models/aluno_perfil_data.dart';
import '../../treinos/aluno/pages/aluno_rotina_view_page.dart';
import '../../treinos/shared/models/rotina_model.dart';
import '../../treinos/aluno/pages/aluno_executar_treino_page.dart';
import '../../alunos/shared/widgets/ritmo_da_semana_card.dart';
import '../../treinos/aluno/pages/aluno_sessao_detalhe_page.dart';
import '../../alunos/shared/widgets/aluno_avatar.dart';

class AlunoHomePage extends StatelessWidget {
  final String uid;
  const AlunoHomePage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    // Mapa de seções da interface desta página:
    // 1) Estrutura superior: AppBar, título e ações de navegação.
    // 2) Conteúdo principal: blocos, listas, cards e estados da tela.
    // 3) Ações finais: botões primários, confirmadores e feedbacks.
    final service = AlunoService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('Início'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  color: AppColors.primary,
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
          final rotinaId = data.rotinaId;
          final nomePersonal = data.nomePersonal;

          final nome = aluno['nome']?.toString().split(' ')[0] ?? 'Aluno';
          final photoUrl = aluno['photoUrl'] as String?;
          final recado = aluno['recadoPersonal'] as String?;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.screenHorizontalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: SpacingTokens.screenTopPadding),
                  _buildHeader(nome, photoUrl, nomePersonal),
                  const SizedBox(height: SpacingTokens.xxl),
                  StreamBuilder<QuerySnapshot>(
                    stream: service.getLogsDaSemanaStream(uid),
                    builder: (context, logsSnap) {
                      List<DateTime>? diasTreinados;

                      if (logsSnap.connectionState != ConnectionState.waiting &&
                          logsSnap.hasData) {
                        diasTreinados = logsSnap.data!.docs
                            .map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final ts = data['dataHora'] as Timestamp?;
                              return ts?.toDate();
                            })
                            .whereType<DateTime>()
                            .toList();
                      }

                      return RitmoDaSemanaCard(
                        alunoNome: nome,
                        diasTreinados: diasTreinados,
                        isAlunoView: true,
                      );
                    },
                  ),
                  const SizedBox(height: SpacingTokens.xxl),
                  if (rotina != null) ...[
                    StreamBuilder<QuerySnapshot>(
                      stream: service.getUltimoLogStream(uid),
                      builder: (context, ultimoLogSnap) {
                        final sessoes = (rotina['sessoes'] as List? ?? [])
                            .map(
                              (s) => SessaoTreinoModel.fromFirestore(
                                s as Map<String, dynamic>,
                              ),
                            )
                            .toList();

                        if (sessoes.isEmpty) return const SizedBox.shrink();

                        SessaoTreinoModel proxSessao = sessoes.first;

                        if (ultimoLogSnap.hasData &&
                            ultimoLogSnap.data!.docs.isNotEmpty) {
                          final lastLog =
                              ultimoLogSnap.data!.docs.first.data()
                                  as Map<String, dynamic>;
                          final ultimoNome =
                              lastLog['sessaoNome'] as String? ?? '';
                          final idx = sessoes.indexWhere(
                            (s) => s.nome == ultimoNome,
                          );
                          if (idx != -1) {
                            proxSessao = sessoes[(idx + 1) % sessoes.length];
                          }
                        }

                        return _buildProximoTreinoCard(
                          context,
                          proxSessao,
                          sessoes.indexOf(proxSessao),
                          rotinaId!,
                          uid,
                        );
                      },
                    ),
                    const SizedBox(height: SpacingTokens.xxl),
                  ],
                  Text('Planilha atual', style: AppTheme.sectionHeader),
                  const SizedBox(height: SpacingTokens.labelToField),
                  rotina != null
                      ? _buildRotinaCard(context, rotina, rotinaId)
                      : _buildSemTreinoCard(),
                  const SizedBox(height: SpacingTokens.xxl),
                  if (recado != null && recado.isNotEmpty) ...[
                    _buildRecadoCard(recado),
                    const SizedBox(height: SpacingTokens.xxl),
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

  Widget _buildHeader(String nome, String? photoUrl, String? nomePersonal) {
    return Row(
      children: [
        AlunoAvatar(
          alunoNome: nome,
          photoUrl: photoUrl,
          radius: AvatarTokens.lg,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getSaudacao()},',
              style: AppTheme.caption.copyWith(
                color: AppColors.labelSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(nome, style: AppTheme.title1),

          ],
        ),
      ],
    );
  }

  Widget _buildRotinaCard(
    BuildContext context,
    Map<String, dynamic> rotina,
    String? rotinaId,
  ) {
    final nomeRotina = rotina['nome'] as String? ?? 'Meu treino';
    final objetivo = rotina['objetivo'] as String? ?? '';
    final tipoVencimento = rotina['tipoVencimento'] as String? ?? 'data';

    double progressoAtual = 0.0;
    String legendaVencimento = '';

    if (tipoVencimento == 'sessoes') {
      final totalSessoes = (rotina['vencimentoSessoes'] as int?) ?? 1;
      final concluidas = (rotina['sessoesConcluidas'] as int?) ?? 0;
      progressoAtual = (concluidas / totalSessoes).clamp(0.0, 1.0);
      legendaVencimento =
          '$concluidas de $totalSessoes ${totalSessoes == 1 ? 'sessão' : 'sessões'}';
    } else {
      final hoje = DateTime.now();
      final dataCriacao =
          (rotina['dataCriacao'] as Timestamp?)?.toDate() ?? hoje;
      final dataVencimento =
          (rotina['dataVencimento'] as Timestamp?)?.toDate() ??
          hoje.add(const Duration(days: 30));
      int totalDias = dataVencimento.difference(dataCriacao).inDays;
      if (totalDias <= 0) totalDias = 1;
      final diasPassados = hoje.difference(dataCriacao).inDays;
      progressoAtual = (diasPassados / totalDias).clamp(0.0, 1.0);
      legendaVencimento =
          'Vencimento em ${DateFormat('dd/MM').format(dataVencimento)}';
    }

    return Container(
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: rotinaId != null
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlunoRotinaViewPage(
                    rotinaData: rotina,
                    rotinaId: rotinaId,
                    alunoId: uid,
                  ),
                ),
              )
            : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: progressoAtual,
                      strokeWidth: 6,
                      backgroundColor: AppColors.primary.withAlpha(15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  const Icon(
                    Icons.fitness_center_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeRotina,
                      style: CardTokens.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: SpacingTokens.titleToSubtitle),
                    if (objetivo.isNotEmpty)
                      Text(
                        objetivo,
                        style: CardTokens.cardSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: SpacingTokens.titleToSubtitle),
                    Text(
                      legendaVencimento,
                      style: CardTokens.cardSubtitle.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.labelSecondary.withAlpha(80),
              ),
            ],
          ),
        ),
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

  String _getSaudacao() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) return 'Bom dia';
    if (hora >= 12 && hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  static int _parseDuration(String value) {
    final v = value.trim().toLowerCase();
    final mMatch = RegExp(r'^(\d+)m$').firstMatch(v);
    if (mMatch != null) return int.parse(mMatch.group(1)!) * 60;
    final sMatch = RegExp(r'^(\d+)s$').firstMatch(v);
    if (sMatch != null) return int.parse(sMatch.group(1)!);
    final msMatch = RegExp(r'^(\d+)m(\d+)s$').firstMatch(v);
    if (msMatch != null) {
      return int.parse(msMatch.group(1)!) * 60 + int.parse(msMatch.group(2)!);
    }
    return int.tryParse(v) ?? 0;
  }

  String _calcularTempoSessao(SessaoTreinoModel sessao) {
    int totalSeconds = 0;
    for (final ex in sessao.exercicios) {
      totalSeconds += 120;
      for (final serie in ex.series) {
        final execTime = ex.tipoAlvo == 'Tempo'
            ? _parseDuration(serie.alvo)
            : (int.tryParse(serie.alvo) ?? 0) * 4;
        totalSeconds += execTime + _parseDuration(serie.descanso);
      }
    }
    final d = Duration(seconds: totalSeconds);
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  Widget _buildRecadoCard(String recado) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.cardPaddingH,
        vertical: SpacingTokens.cardPaddingH,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                'Recado do seu Personal',
                style: AppTheme.caption2.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(recado, style: AppTheme.cardSubtitle),
        ],
      ),
    );
  }

  Widget _buildProximoTreinoCard(
    BuildContext context,
    SessaoTreinoModel sessao,
    int sessaoIndex,
    String rotinaId,
    String alunoId,
  ) {
    final letra = String.fromCharCode(65 + (sessaoIndex % 26));

    final totalSeries = sessao.exercicios.fold<int>(
      0,
      (acc, ex) => acc + ex.series.length,
    );

    final grupos = sessao.exercicios
        .expand((ex) => ex.grupoMuscular)
        .toSet()
        .where((g) => g.isNotEmpty && g != 'Geral')
        .take(4)
        .toList();

    final tempoEstimado = _calcularTempoSessao(sessao);

    void iniciar() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlunoExecutarTreinoPage(
          sessao: sessao,
          rotinaId: rotinaId,
          alunoId: alunoId,
        ),
      ),
    );

    void verDetalhe() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlunoSessaoDetalhePage(
          sessao: sessao,
          letra: letra,
          rotinaId: rotinaId,
          alunoId: alunoId,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Próximo treino', style: AppTheme.sectionHeader),
        const SizedBox(height: SpacingTokens.labelToField),
        Material(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              // Header: tappable → vai para detalhes da sessão
              InkWell(
                onTap: verDetalhe,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withAlpha(28),
                        AppColors.primary.withAlpha(5),
                      ],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(22),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(60),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          letra,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sessao.nome,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.labelPrimary,
                                letterSpacing: -0.5,
                                height: 1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (sessao.diaSemana != null &&
                                sessao.diaSemana!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                sessao.diaSemana!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary.withAlpha(200),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                            if (grupos.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 5,
                                runSpacing: 5,
                                children: grupos
                                    .map((g) => _MuscleChip(label: g))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.labelSecondary.withAlpha(80),
                      ),
                    ],
                  ),
                ),
              ),

              Container(height: 1, color: AppColors.labelSecondary.withAlpha(20)),

              // Stats
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Row(
                  children: [
                    _InfoRow(
                      icon: Icons.fitness_center_rounded,
                      label: sessao.exercicios.length != 1
                          ? 'Exercícios'
                          : 'Exercício',
                      value: '${sessao.exercicios.length}',
                    ),
                    _VerticalDivider(),
                    _InfoRow(
                      icon: Icons.repeat_rounded,
                      label: totalSeries != 1 ? 'Séries' : 'Série',
                      value: '$totalSeries',
                    ),
                    _VerticalDivider(),
                    _InfoRow(
                      icon: Icons.timer_outlined,
                      label: 'Estimado',
                      value: tempoEstimado,
                    ),
                  ],
                ),
              ),

              Container(height: 1, color: AppColors.labelSecondary.withAlpha(20)),

              // Ações
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: verDetalhe,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.fillSecondary,
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Ver detalhes',
                            style: TextStyle(
                              color: AppColors.labelPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: iniciar,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Iniciar treino',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
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
            ],
          ),
        ),
      ],
    );
  }
}


class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 11,
                color: AppColors.labelSecondary.withAlpha(140),
              ),
              const SizedBox(width: 4),
              Text(label, style: AppTheme.caption),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.labelPrimary,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.labelSecondary.withAlpha(30),
    );
  }
}


class _MuscleChip extends StatelessWidget {
  final String label;

  const _MuscleChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(label, style: AppTheme.caption2),
    );
  }
}