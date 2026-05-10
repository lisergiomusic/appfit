import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:ui';
import '../../../core/services/aluno_service.dart';
import '../../../core/services/workout_draft_service.dart';
import '../../../core/utils/app_ui_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../treinos/aluno/pages/aluno_rotina_view_page.dart';
import '../../treinos/shared/models/rotina_model.dart';
import '../../treinos/aluno/pages/aluno_executar_treino_page.dart';
import '../../alunos/shared/widgets/ritmo_da_semana_card.dart';
import '../../treinos/aluno/pages/aluno_sessao_detalhe_page.dart';
import '../../alunos/shared/widgets/app_avatar.dart';
import '../../alunos/shared/models/aluno_perfil_data.dart';

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
  String? _selectedCoverGroup;
  String? _manualSessaoOverrideName;

  static const Map<String, String> _muscleImageMap = {
    'peito': 'chest.jpg',
    'costas': 'back.jpg',
    'pernas': 'legs.jpg',
    'deltóides': 'deltoides.jpg',
    'deltoides': 'deltoides.jpg',
    'glúteos': 'gluteos.jpg',
    'gluteos': 'gluteos.jpg',
    'triceps': 'triceps.jpg',
    'tríceps': 'triceps.jpg',
    'biceps': 'biceps.jpg',
    'bíceps': 'biceps.jpg',
  };

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
    _checkDraft();
  }

  String _getSaudacao() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) return 'Bom dia';
    if (hora >= 12 && hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String? _lastSortedSessao;

  void _sortearCapa(SessaoTreinoModel sessao) {
    if (_selectedCoverGroup != null && _lastSortedSessao == sessao.nome) return;

    final grupos = sessao.exercicios
        .expand((e) => e.grupoMuscular)
        .toSet()
        .toList();

    final gruposValidos = grupos
        .where((g) => _muscleImageMap.containsKey(g.toLowerCase()))
        .toList();

    if (gruposValidos.isNotEmpty) {
      final sorteado = gruposValidos[Random().nextInt(gruposValidos.length)];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedCoverGroup = sorteado;
            _lastSortedSessao = sessao.nome;
          });
        }
      });
    }
  }

  String? _getCoverUrl(String? group) {
    if (group == null) return null;
    final fileName = _muscleImageMap[group.toLowerCase()];
    if (fileName == null) return null;
    return 'https://rqsonrzagxvmmkjzshcl.supabase.co/storage/v1/object/public/workout_covers/$fileName';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<AlunoPerfilData>(
        stream: _perfilStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Erro ao carregar dados.', style: TextStyle(color: AppColors.labelSecondary)));
          }

          final data = snapshot.data!;
          final aluno = data.aluno;
          final rotina = data.rotinaAtiva;
          final rotinaId = data.rotinaId;

          final nomeRaw = (aluno['nome'] ?? aluno['display_name'] ?? aluno['full_name'] ?? '').toString();
          final nome = nomeRaw.trim().isEmpty ? 'Aluno' : nomeRaw.trim().split(' ')[0];
          final photoUrl = (aluno['photo_url'] ?? aluno['photoUrl'])?.toString();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(nome, photoUrl),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.screenHorizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_activeDraft != null) ...[
                        const SizedBox(height: SpacingTokens.xxl),
                        _buildResumeWorkoutCard(),
                      ],
                      const SizedBox(height: SpacingTokens.xxl),
                      if (rotina != null) ...[
                        _buildNextWorkoutSection(rotina, rotinaId!, widget.uid),
                        const SizedBox(height: SpacingTokens.xxl),
                      ],
                      _buildWeeklyRhythmSection(nome),
                      const SizedBox(height: SpacingTokens.xxl),
                      Text('PLANILHA ATUAL', style: AppTheme.sectionHeader),
                      const SizedBox(height: SpacingTokens.labelToField),
                      rotina != null ? _buildRotinaCard(context, rotina, rotinaId) : _buildSemTreinoCard(),
                      const SizedBox(height: SpacingTokens.screenBottomPadding + 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(String nome, String? photoUrl) {
    return SliverAppBar(
      expandedHeight: 120,
      collapsedHeight: 70,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: Container(
          decoration: BoxDecoration(gradient: AppTheme.premiumGradient),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppAvatar(name: nome, photoUrl: photoUrl, radius: 18, showBorder: false),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_getSaudacao()},', style: AppTheme.premiumLabel.copyWith(fontSize: 8)),
                Text(nome, style: AppTheme.pageTitle.copyWith(fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.labelSecondary, size: 24),
          onPressed: () => AppUIUtils.showFutureFeatureWarning(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildResumeWorkoutCard() {
    return Container(
      decoration: AppTheme.premiumCardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _resumeWorkout,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill, color: AppColors.primary, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TREINO EM ANDAMENTO', style: AppTheme.premiumLabel.copyWith(color: AppColors.primary, letterSpacing: 1.0)),
                      const SizedBox(height: 4),
                      Text(_activeDraft!.sessao.nome, style: AppTheme.title1.copyWith(fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.labelSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyRhythmSection(String nome) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                StreamBuilder<dynamic>(
          stream: _logsSemanaStream,
          builder: (context, logsSnap) {
            List<DateTime>? diasTreinados;
            if (logsSnap.hasData) {
              final dataList = logsSnap.data as List<Map<String, dynamic>>;
              diasTreinados = dataList.map((data) => DateTime.tryParse(data['dataHora'].toString())).whereType<DateTime>().toList();
            }
            return RitmoDaSemanaCard(alunoNome: nome, diasTreinados: diasTreinados, isAlunoView: true);
          },
        ),
      ],
    );
  }

  Widget _buildNextWorkoutSection(Map<String, dynamic> rotina, String rotinaId, String alunoId) {
    return StreamBuilder<dynamic>(
      stream: _ultimoLogStream,
      builder: (context, ultimoLogSnap) {
        final sessoes = (rotina['sessoes'] as List? ?? []).map((s) => SessaoTreinoModel.fromMap(s as Map<String, dynamic>)).toList();
        if (sessoes.isEmpty) return const SizedBox.shrink();

        SessaoTreinoModel proxSessao = sessoes.first;

        if (_manualSessaoOverrideName != null) {
          proxSessao = sessoes.firstWhere((s) => s.nome == _manualSessaoOverrideName, orElse: () => sessoes.first);
        } else if (ultimoLogSnap.hasData && ultimoLogSnap.data is List && (ultimoLogSnap.data as List).isNotEmpty) {
          final lastLog = (ultimoLogSnap.data as List).first as Map<String, dynamic>;
          final ultimoNome = lastLog['sessaoNome'] as String? ?? '';
          final idx = sessoes.indexWhere((s) => s.nome == ultimoNome);
          if (idx != -1) proxSessao = sessoes[(idx + 1) % sessoes.length];
        }

        // Sorteia a capa APÓS identificar qual é a próxima sessão
        _sortearCapa(proxSessao);

        return _NextWorkoutCard(
          sessao: proxSessao,
          sessaoIndex: sessoes.indexOf(proxSessao),
          rotinaId: rotinaId,
          alunoId: alunoId,
          rotinaData: rotina,
          coverUrl: _getCoverUrl(_selectedCoverGroup),
          tempoEstimado: proxSessao.calcularTempoEstimado(),
          onSwitchRequested: () => _mostrarModalSessoes(context, sessoes, proxSessao),
          onStart: () =>
              _confirmarIniciarSessao(context, proxSessao, rotinaId, alunoId),
        );
      },
    );
  }

  void _mostrarModalSessoes(BuildContext context, List<SessaoTreinoModel> sessoes, SessaoTreinoModel atual) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXL)),
        title: Text('Próximo treino', style: AppTheme.title1),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: sessoes.length,
            separatorBuilder: (_, __) => Divider(color: Colors.white.withAlpha(20), height: 1),
            itemBuilder: (context, index) {
              final s = sessoes[index];
              final isSelected = s.nome == atual.nome;
              return ListTile(
                onTap: () {
                  setState(() => _manualSessaoOverrideName = s.nome);
                  Navigator.pop(context);
                },
                contentPadding: EdgeInsets.zero,
                title: Text(s.nome, style: TextStyle(color: isSelected ? AppColors.primary : Colors.white70, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
                trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20) : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('FECHAR', style: AppTheme.premiumLabel)),
        ],
      ),
    );
  }

    Widget _buildRotinaCard(BuildContext context, Map<String, dynamic> rotina, String? rotinaId) {
    final nomeRotina = rotina['nome'] as String? ?? 'Meu treino';
    final tipoVencimento = rotina['tipoVencimento'] as String? ?? 'data';

    String legendaVencimento = '';

    if (tipoVencimento == 'sessoes') {
      final totalSessoes = (rotina['vencimentoSessoes'] as int?) ?? 1;
      final concluidas = (rotina['sessoesConcluidas'] as int?) ?? 0;
      legendaVencimento = '$concluidas de $totalSessoes ${totalSessoes == 1 ? 'sessão' : 'sessões'}';
    } else {
      final hoje = DateTime.now();
      final dataVencimento = DateTime.tryParse(rotina['dataVencimento']?.toString() ?? '') ?? hoje.add(const Duration(days: 30));
      legendaVencimento = 'Vencimento em ${DateFormat('dd/MM').format(dataVencimento)}';
    }

    return Container(
      decoration: AppTheme.premiumCardDecoration,
      child: InkWell(
        onTap: rotinaId != null ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => AlunoRotinaViewPage(rotinaData: rotina, rotinaId: rotinaId, alunoId: widget.uid))) : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20), 
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_motion_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nomeRotina, style: AppTheme.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(legendaVencimento, style: AppTheme.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.labelTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSemTreinoCard() {
    return Container(
      width: double.infinity,
      decoration: AppTheme.premiumCardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.fitness_center_rounded, size: 40, color: AppColors.labelSecondary.withAlpha(50)),
          const SizedBox(height: 12),
          Text('Nenhum treino atribuído', style: AppTheme.cardTitle),
          Text('Aguarde seu personal atribuir uma rotina.', style: AppTheme.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<void> _confirmarIniciarSessao(BuildContext context, SessaoTreinoModel sessao, String rotinaId, String alunoId) async {
    if (_activeDraft != null && _activeDraft!.sessao.nome == sessao.nome && _activeDraft!.rotinaId == rotinaId) {
      _resumeWorkout();
      return;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(_activeDraft != null ? 'Trocar treino?' : 'Iniciar sessão', style: AppTheme.title1),
        content: Text(_activeDraft != null ? 'Você já tem um progresso salvo. Iniciar este novo treino descartará o rascunho anterior.' : 'Pronto para treinar? Você vai executar "${sessao.nome}".', style: AppTheme.bodyText),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: AppColors.labelSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(_activeDraft != null ? 'Iniciar e Descartar' : 'Iniciar', style: TextStyle(color: _activeDraft != null ? AppColors.systemRed : AppColors.primary))),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      if (_activeDraft != null) await WorkoutDraftService().clearDraft();
      await Navigator.push(context, MaterialPageRoute(builder: (context) => AlunoExecutarTreinoPage(sessao: sessao, rotinaId: rotinaId, alunoId: alunoId)));
      _checkDraft();
    }
  }
}

class _NextWorkoutCard extends StatelessWidget {
  final SessaoTreinoModel sessao;
  final int sessaoIndex;
  final String rotinaId;
  final String alunoId;
  final Map<String, dynamic> rotinaData;
  final String? coverUrl;
  final String tempoEstimado;
  final VoidCallback onStart;
  final VoidCallback onSwitchRequested;

  const _NextWorkoutCard({
    required this.sessao,
    required this.sessaoIndex,
    required this.rotinaId,
    required this.alunoId,
    required this.rotinaData,
    this.coverUrl,
    required this.tempoEstimado,
    required this.onStart,
    required this.onSwitchRequested,
  });

  @override
  Widget build(BuildContext context) {
    final letra = String.fromCharCode(65 + (sessaoIndex % 26));
    final totalSeries = sessao.exercicios.fold<int>(0, (acc, ex) => acc + ex.series.length);
    final grupos = sessao.exercicios.expand((ex) => ex.grupoMuscular).toSet().where((g) => g.isNotEmpty && g != 'Geral').take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PRÓXIMO TREINO', style: AppTheme.sectionHeader),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlunoSessaoDetalhePage(sessao: sessao, letra: letra, rotinaId: rotinaId, alunoId: alunoId))),
              child: const Text('DETALHES', style: AppTheme.premiumLabel),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.labelToField),
        Container(
          decoration: AppTheme.premiumCardDecoration.copyWith(
            image: coverUrl != null ? DecorationImage(
              image: CachedNetworkImageProvider(coverUrl!),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black.withAlpha(160), BlendMode.darken),
            ) : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onStart,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.center,
                            child: Text(letra, style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sessao.nome, style: AppTheme.title1.copyWith(fontSize: 22, color: Colors.white)),
                                if (grupos.isNotEmpty) Text(grupos.join(' • '), style: AppTheme.caption.copyWith(color: Colors.white70, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const Icon(Icons.play_circle_fill, color: AppColors.primary, size: 48),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                _Stat(icon: Icons.fitness_center, value: '${sessao.exercicios.length}', label: 'Exs'),
                                _Stat(icon: Icons.repeat, value: '$totalSeries', label: 'Séries'),
                                _Stat(icon: Icons.timer_outlined, value: tempoEstimado, label: 'Est'),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: onSwitchRequested,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(20),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: Colors.white.withAlpha(40), width: 0.5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text('TROCAR', style: AppTheme.premiumLabel.copyWith(color: Colors.white, fontSize: 10, letterSpacing: 1)),
                                    ],
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
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTheme.title1.copyWith(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: AppTheme.formLabel.copyWith(
              fontSize: 10,
              letterSpacing: 0.5,
              color: AppColors.labelSecondary,
            ),
          ),
        ],
      ),
    );
  }
}