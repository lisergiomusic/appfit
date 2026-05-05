import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/aluno_service.dart';
import '../../../core/services/workout_draft_service.dart';
import '../../../core/utils/app_ui_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../alunos/shared/models/aluno_perfil_data.dart';
import '../../treinos/aluno/pages/aluno_rotina_view_page.dart';
import '../../treinos/shared/models/rotina_model.dart';
import '../../treinos/aluno/pages/aluno_executar_treino_page.dart';
import '../../alunos/shared/widgets/ritmo_da_semana_card.dart';
import '../../treinos/aluno/pages/aluno_sessao_detalhe_page.dart';
import '../../alunos/shared/widgets/app_avatar.dart';

class AlunoHomePage extends StatefulWidget {
  final String uid;
  const AlunoHomePage({super.key, required this.uid});

  @override
  State<AlunoHomePage> createState() => _AlunoHomePageState();
}

class _AlunoHomePageState extends State<AlunoHomePage> {
  late final AlunoService _service;
  late final Stream<AlunoPerfilData> _perfilStream;
  late final Stream<dynamic> _logsSemanaStream;
  late final Stream<dynamic> _ultimoLogStream;

  WorkoutDraft? _activeDraft;

  @override
  void initState() {
    super.initState();
    _service = AlunoService();
    _perfilStream = _service.getAlunoPerfilCompletoStream(widget.uid);
    _logsSemanaStream = _service.getLogsDaSemanaStream(widget.uid);
    _ultimoLogStream = _service.getUltimoLogStream(widget.uid);
    _checkDraft();
  }

  Future<void> _checkDraft() async {
    final draft = await WorkoutDraftService().loadDraft();
    if (mounted && draft != null && draft.alunoId == widget.uid) {
      // Verifica se o rascunho é recente (ex: menos de 6 horas)
      final diff = DateTime.now().difference(draft.lastUpdated);
      if (diff.inHours < 6) {
        setState(() => _activeDraft = draft);
      } else {
        await WorkoutDraftService().clearDraft();
      }
    }
  }

  void _resumeWorkout() async {
    if (_activeDraft == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlunoExecutarTreinoPage(
          sessao: _activeDraft!.sessao,
          rotinaId: _activeDraft!.rotinaId,
          alunoId: _activeDraft!.alunoId,
        ),
      ),
    );

    // Após voltar da execução, verifica se o rascunho ainda existe
    _checkDraft();
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
        title: const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text('Pagina Inicial'),
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
        stream: _perfilStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
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


          final nomeRaw = (aluno['nome'] ?? aluno['display_name'] ?? aluno['full_name'] ?? '').toString();
          final nome = nomeRaw.trim().isEmpty ? 'Aluno' : nomeRaw.trim().split(' ')[0];
          final photoUrl = (aluno['photo_url'] ?? aluno['photoUrl'])?.toString();

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
                  if (_activeDraft != null) ...[
                    const SizedBox(height: SpacingTokens.xxl),
                    _buildResumeWorkoutCard(),
                  ],
                  const SizedBox(height: SpacingTokens.xxl),
                  StreamBuilder<dynamic>(
                    stream: _logsSemanaStream,
                    builder: (context, logsSnap) {
                      List<DateTime>? diasTreinados;

                      if (logsSnap.connectionState != ConnectionState.waiting &&
                          logsSnap.hasData) {
                        final dataList = logsSnap.data as List<Map<String, dynamic>>;
                        diasTreinados = dataList
                            .map((data) {
                              final ts = data['dataHora'];
                              if (ts == null) return null;
                              return DateTime.tryParse(ts.toString());
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
                    StreamBuilder<dynamic>(
                      stream: _ultimoLogStream,
                      builder: (context, ultimoLogSnap) {
                        final sessoes = (rotina['sessoes'] as List? ?? [])
                            .map(
                              (s) => SessaoTreinoModel.fromMap(
                                s as Map<String, dynamic>,
                              ),
                            )
                            .toList();

                        if (sessoes.isEmpty) return const SizedBox.shrink();

                        SessaoTreinoModel proxSessao = sessoes.first;

                        if (ultimoLogSnap.hasData &&
                            ultimoLogSnap.data is List &&
                            (ultimoLogSnap.data as List).isNotEmpty) {
                          final lastLog =
                              (ultimoLogSnap.data as List).first
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
                          widget.uid,
                          rotina,
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
        AppAvatar(
          name: nome,
          photoUrl: photoUrl,
          radius: AvatarTokens.lg,
          showBorder: false,
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

  Widget _buildResumeWorkoutCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withAlpha(200),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(80),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _resumeWorkout,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Treino em andamento',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _activeDraft!.sessao.nome,
                        style: TextStyle(
                          color: Colors.black.withAlpha(160),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: const Text(
                    'Retomar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
      final dataCriacaoStr = rotina['dataCriacao'];
      final dataVencimentoStr = rotina['dataVencimento'];

      final dataCriacao = dataCriacaoStr != null
          ? DateTime.tryParse(dataCriacaoStr.toString()) ?? hoje
          : hoje;
      final dataVencimento = dataVencimentoStr != null
          ? DateTime.tryParse(dataVencimentoStr.toString()) ?? hoje.add(const Duration(days: 30))
          : hoje.add(const Duration(days: 30));
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
                    alunoId: widget.uid,
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

  Future<void> _confirmarIniciarSessao(
    BuildContext context,
    SessaoTreinoModel sessao,
    String rotinaId,
    String alunoId,
  ) async {
    // Se for a mesma sessão do rascunho, retoma direto
    if (_activeDraft != null &&
        _activeDraft!.sessao.nome == sessao.nome &&
        _activeDraft!.rotinaId == rotinaId) {
      _resumeWorkout();
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          _activeDraft != null ? 'Trocar treino?' : 'Iniciar sessão',
          style: AppTheme.title1,
        ),
        content: Text(
          _activeDraft != null
              ? 'Você já tem um progresso salvo em "${_activeDraft!.sessao.nome}". Iniciar este novo treino descartará o rascunho anterior.'
              : 'Pronto para treinar? Você vai executar a sessão "${sessao.nome}" e o tempo de treino começará a contar imediatamente.',
          style: AppTheme.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.labelSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _activeDraft != null ? 'Iniciar e Descartar' : 'Iniciar',
              style: TextStyle(color: _activeDraft != null ? AppColors.systemRed : AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      // Limpa rascunho anterior se existir um diferente
      if (_activeDraft != null) {
        await WorkoutDraftService().clearDraft();
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AlunoExecutarTreinoPage(
            sessao: sessao,
            rotinaId: rotinaId,
            alunoId: alunoId,
          ),
        ),
      );
      _checkDraft();
    }
  }

  Widget _buildProximoTreinoCard(
    BuildContext context,
    SessaoTreinoModel sessao,
    int sessaoIndex,
    String rotinaId,
    String alunoId,
    Map<String, dynamic> rotinaData,
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

    void iniciar() => _confirmarIniciarSessao(
          context,
          sessao,
          rotinaId,
          alunoId,
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
              Container(
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
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: verDetalhe,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
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
                            ],
                          ),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 22,
                        color: AppColors.labelSecondary.withAlpha(120),
                      ),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                      ),
                      onSelected: (value) {
                        if (value == 'detalhes') {
                          verDetalhe();
                        } else if (value == 'escolher') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AlunoRotinaViewPage(
                                rotinaData: rotinaData,
                                rotinaId: rotinaId,
                                alunoId: alunoId,
                              ),
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'escolher',
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz_rounded, size: 20),
                              SizedBox(width: 10),
                              Text('Escolher outro treino'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'detalhes',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 20),
                              SizedBox(width: 10),
                              Text('Ver detalhes'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
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
                child: GestureDetector(
                  onTap: iniciar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                            fontSize: 16,
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