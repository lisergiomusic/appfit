import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/treino_service.dart';
import '../../../../core/services/workout_draft_service.dart';
import '../../shared/models/rotina_model.dart';
import '../../shared/models/historico_treino_model.dart';
import '../../shared/models/exercicio_model.dart';
import '../../shared/widgets/exercicio_thumbnail.dart';
import '../controllers/executar_treino_controller.dart';
import 'aluno_feedback_treino_page.dart';
import '../../shared/widgets/executar_treino/treino_scrollable_body.dart';

/// Tela de execução da sessão com marcação de séries e timer de descanso.
class AlunoExecutarTreinoPage extends StatefulWidget {
  final SessaoTreinoModel sessao;
  final String rotinaId;
  final String alunoId;
  final TreinoService? treinoService;

  const AlunoExecutarTreinoPage({
    super.key,
    required this.sessao,
    required this.rotinaId,
    required this.alunoId,
    this.treinoService,
  });

  @override
  State<AlunoExecutarTreinoPage> createState() =>
      _AlunoExecutarTreinoPageState();
}

class _AlunoExecutarTreinoPageState extends State<AlunoExecutarTreinoPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late ExecutarTreinoController _controller;

  late DateTime _startedAt;
  final Map<String, dynamic> _recordedData = {};
  late List<List<TextEditingController>> _repsControllers;
  late List<List<TextEditingController>> _pesoControllers;

  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;

  final bool _isLoading = false;

  late AnimationController _progressAnimController;
  late Animation<double> _progressAnim;

  // Rest Timer State
  Timer? _restTimer;
  int _restRemainingSeconds = 0;
  int _restTotalSeconds = 0;
  bool _isRestTimerActive = false;
  DateTime? _restEndTime;
  String? _restExerciseName;
  int? _restSetIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ExecutarTreinoController(
      sessao: widget.sessao,
      rotinaId: widget.rotinaId,
      alunoId: widget.alunoId,
      treinoService: widget.treinoService,
    );
    _startedAt = DateTime.now();
    _initializeRecordedData();
    _initializeTextControllers();
    _startElapsedTimer();

    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressAnimController, curve: Curves.easeOut),
    );

    // Carregamento não bloqueante para a tela ficar responsiva desde o início.
    _controller.carregarUltimoHistorico().then((_) {
      if (mounted) setState(() {});
    });

    // Tenta recuperar rascunho anterior se for o mesmo treino
    _loadDraftIfExists();
  }

  Future<void> _loadDraftIfExists() async {
    final draft = await WorkoutDraftService().loadDraft();
    if (draft != null &&
        draft.alunoId == widget.alunoId &&
        draft.rotinaId == widget.rotinaId &&
        draft.sessao.nome == widget.sessao.nome) {
      if (mounted) {
        setState(() {
          _startedAt = draft.startedAt;
          _elapsedSeconds = DateTime.now().difference(_startedAt).inSeconds;
          _recordedData.clear();
          _recordedData.addAll(draft.recordedData);

          // Atualiza os controllers de texto com o que estava no rascunho
          for (var i = 0; i < widget.sessao.exercicios.length; i++) {
            final key = 'exercicio_$i';
            final seriesData = _recordedData[key]?['series'] as List?;
            if (seriesData != null) {
              for (var j = 0; j < seriesData.length; j++) {
                if (j < _repsControllers[i].length) {
                  _repsControllers[i][j].text =
                      seriesData[j]['reps']?.toString() ?? '';
                }
                if (j < _pesoControllers[i].length) {
                  _pesoControllers[i][j].text =
                      seriesData[j]['peso']?.toString() ?? '';
                }
              }
            }
          }
        });
        _animateProgress();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveDraft();
    } else if (state == AppLifecycleState.resumed) {
      _handleRestTimerResumed();
    }
  }

  void _handleRestTimerResumed() {
    if (!_isRestTimerActive || _restEndTime == null) return;

    final now = DateTime.now();
    if (now.isAfter(_restEndTime!)) {
      _finishRestTimer();
    } else {
      setState(() {
        _restRemainingSeconds = _restEndTime!.difference(now).inSeconds;
      });
    }
  }

  void _saveDraft() {
    // Sincroniza o rascunho local com o estado atual antes de fechar/pausar
    // (Apenas se houver algum progresso para evitar IO desnecessário)
    if (_hasAnyProgress()) {
      _controller.saveDraft(
        startedAt: _startedAt,
        recordedData: _recordedData,
      );
    }
  }

  void _initializeRecordedData() {
    // Espelha a estrutura dos exercícios para salvar reps/peso/conclusão por série.
    for (var i = 0; i < widget.sessao.exercicios.length; i++) {
      _recordedData['exercicio_$i'] = {
        'series': List.generate(
          widget.sessao.exercicios[i].series.length,
          (_) => {'reps': '', 'peso': '', 'completa': false},
        ),
      };
    }
  }

  void _initializeTextControllers() {
    _repsControllers = [];
    _pesoControllers = [];
    for (var i = 0; i < widget.sessao.exercicios.length; i++) {
      final exercise = widget.sessao.exercicios[i];
      final repsRow = <TextEditingController>[];
      final pesoRow = <TextEditingController>[];
      for (var j = 0; j < exercise.series.length; j++) {
        repsRow.add(TextEditingController());
        pesoRow.add(TextEditingController());
      }
      _repsControllers.add(repsRow);
      _pesoControllers.add(pesoRow);
    }
  }

  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    _progressAnimController.dispose();
    for (final row in _repsControllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    for (final row in _pesoControllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    _controller.dispose();
    super.dispose();
  }

  String _formatElapsed(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  int _completedSeriesForExercise(int index) {
    final series =
        (_recordedData['exercicio_$index']?['series'] as List?) ?? [];
    return series.where((s) => (s as Map)['completa'] == true).length;
  }

  int get _totalSeries =>
      widget.sessao.exercicios.fold(0, (int sum, e) => sum + e.series.length);

  int get _completedSeries {
    int count = 0;
    for (var i = 0; i < widget.sessao.exercicios.length; i++) {
      count += _completedSeriesForExercise(i);
    }
    return count;
  }

  bool _hasAnyProgress() => _completedSeries > 0;

  void _animateProgress() {
    final target = _totalSeries > 0 ? _completedSeries / _totalSeries : 0.0;
    final oldVal = _progressAnim.value;
    _progressAnim = Tween<double>(begin: oldVal, end: target).animate(
      CurvedAnimation(parent: _progressAnimController, curve: Curves.easeOut),
    );
    _progressAnimController.forward(from: 0);
  }

  void _onVerHistorico(String exercicioNome, List<SerieHistorico> historico) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _UltimoTreinoSheet(
        exercicioNome: exercicioNome,
        historico: historico,
      ),
    );
  }

  void _onSerieCompleted(int exercicioIndex, int serieIndex) {
    final key = 'exercicio_$exercicioIndex';
    final currentComplete =
        _recordedData[key]['series'][serieIndex]['completa'] as bool;

    HapticFeedback.mediumImpact();

    if (currentComplete) {
      setState(() {
        _recordedData[key]['series'][serieIndex]['completa'] = false;
      });
      _animateProgress();
      return;
    }

    // Snapshot da edição atual para garantir consistência no log final.
    setState(() {
      _recordedData[key]['series'][serieIndex]['completa'] = true;
      _recordedData[key]['series'][serieIndex]['reps'] =
          _repsControllers[exercicioIndex][serieIndex].text;
      _recordedData[key]['series'][serieIndex]['peso'] =
          _pesoControllers[exercicioIndex][serieIndex].text;
    });
    _animateProgress();
    _saveDraft();

    // Trigger rest timer
    final exercicio = widget.sessao.exercicios[exercicioIndex];
    final serie = exercicio.series[serieIndex];
    final seconds = _parseRestTime(serie.descanso);
    if (seconds > 0) {
      _startRestTimer(
        seconds,
        exerciseName: exercicio.nome,
        setIndex: serieIndex + 1,
      );
    }
  }

  int _parseRestTime(String rest) {
    final clean = rest.toLowerCase().replaceAll('s', '').trim();
    if (clean.contains(':')) {
      final parts = clean.split(':');
      if (parts.length == 2) {
        final mins = int.tryParse(parts[0]) ?? 0;
        final secs = int.tryParse(parts[1]) ?? 0;
        return (mins * 60) + secs;
      }
    }
    return int.tryParse(clean) ?? 0;
  }

  void _startRestTimer(int seconds, {required String exerciseName, required int setIndex}) {
    _restTimer?.cancel();
    setState(() {
      _restTotalSeconds = seconds;
      _restRemainingSeconds = seconds;
      _isRestTimerActive = true;
      _restEndTime = DateTime.now().add(Duration(seconds: seconds));
      _restExerciseName = exerciseName;
      _restSetIndex = setIndex;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restRemainingSeconds > 1) {
        setState(() {
          _restRemainingSeconds--;
        });
      } else {
        _finishRestTimer();
      }
    });
  }

  void _finishRestTimer() {
    _restTimer?.cancel();
    _restTimer = null;
    HapticFeedback.heavyImpact();
    setState(() {
      _isRestTimerActive = false;
      _restRemainingSeconds = 0;
      _restEndTime = null;
      _restExerciseName = null;
      _restSetIndex = null;
    });
  }

  void _skipRestTimer() {
    _finishRestTimer();
  }

  void _addRestTime(int seconds) {
    if (!_isRestTimerActive) return;
    setState(() {
      _restTotalSeconds += seconds;
      _restRemainingSeconds += seconds;
      _restEndTime = _restEndTime?.add(Duration(seconds: seconds));
    });
  }

  void _onSwapExercise(int index) async {
    final exercicioAtual = widget.sessao.exercicios[index];
    final todasOpcoes = [exercicioAtual, ...exercicioAtual.alternativas];

    final selecionado = await showModalBottomSheet<ExercicioItem>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SwapExerciseSheet(
        selecionados: todasOpcoes,
        atual: exercicioAtual,
      ),
    );

    if (selecionado != null && selecionado != exercicioAtual) {
      setState(() {
        final altIndex = exercicioAtual.alternativas.indexOf(selecionado);
        exercicioAtual.alternativas.removeAt(altIndex);
        
        final anterior = exercicioAtual.clone();
        final novo = selecionado.clone();
        
        // Mantém a prescrição (séries) do Personal, mas clona para evitar referências mútuas
        novo.series = exercicioAtual.series.map((s) => s.clone()).toList();
        
        // Re-organiza a lista de alternativas para permitir a volta
        novo.alternativas = [anterior, ...exercicioAtual.alternativas];

        widget.sessao.exercicios[index] = novo;
        
        // Recarrega o histórico para o novo exercício substituído
        _controller.carregarUltimoHistorico().then((_) {
          if (mounted) setState(() {});
        });

        _saveDraft();
      });
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _finalizarTreino() async {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _FinalizarDialog(),
    );

    if (confirm == true) {
      if (!mounted) return;
      final duracao = DateTime.now().difference(_startedAt).inMinutes;
      final feedback = await Navigator.of(context).push<FeedbackTreino>(
        MaterialPageRoute(
          builder: (_) => AlunoFeedbackTreinoPage(
            sessaoNome: widget.sessao.nome,
            duracaoMinutos: duracao,
          ),
        ),
      );
      if (!mounted) return;
      _controller.saveTreinoLog(
        _recordedData,
        duracaoMinutos: duracao,
        esforco: feedback?.esforco ?? 0,
        observacoes: feedback?.observacoes ?? '',
      );
      await _controller.clearDraft();
      if (mounted) Navigator.of(context).pop();
    } else {
      _startElapsedTimer();
    }
  }

  Future<void> _confirmarCancelamento() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _CancelarDialog(),
    );

    if (confirm == true) {
      await _controller.clearDraft();
      if (mounted) Navigator.pop(context);
    } else {
      _startElapsedTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = _completedSeries;
    final total = _totalSeries;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmarCancelamento();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _WorkoutAppBar(
          sessaoNome: widget.sessao.nome,
          elapsedFormatted: _formatElapsed(_elapsedSeconds),
          completed: completed,
          total: total,
          progressAnim: _progressAnim,
          progressAnimController: _progressAnimController,
          hasProgress: _hasAnyProgress(),
          onFinalizar: _finalizarTreino,
          onCancelar: _confirmarCancelamento,
        ),
        body: Stack(
          children: [
            TreinoScrollableBody(
              sessao: widget.sessao,
              recordedData: _recordedData,
              repsControllers: _repsControllers,
              pesoControllers: _pesoControllers,
              onSerieCompleted: _onSerieCompleted,
              onVerHistorico: _onVerHistorico,
              onSwapExercise: _onSwapExercise,
              alunoId: widget.alunoId,
              ultimoHistorico: _controller.ultimoHistorico,
            ),
            if (_isRestTimerActive)
              Align(
                alignment: Alignment.bottomCenter,
                child: _RestTimerBanner(
                  remainingSeconds: _restRemainingSeconds,
                  totalSeconds: _restTotalSeconds,
                  exerciseName: _restExerciseName ?? '',
                  setIndex: _restSetIndex ?? 0,
                  onSkip: _skipRestTimer,
                  onAdd30s: () => _addRestTime(30),
                ),
              ),
            if (_isLoading)
              Container(
                color: AppColors.background.withAlpha(200),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RestTimerBanner extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final String exerciseName;
  final int setIndex;
  final VoidCallback onSkip;
  final VoidCallback onAdd30s;

  const _RestTimerBanner({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.exerciseName,
    required this.setIndex,
    required this.onSkip,
    required this.onAdd30s,
  });

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withAlpha(200),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withAlpha(20),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(100),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor: Colors.white.withAlpha(20),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(remainingSeconds),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Descanse',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onAdd30s,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '+30s',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onSkip,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Pular',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
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
    );
  }
}

class _WorkoutAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String sessaoNome;
  final String elapsedFormatted;
  final int completed;
  final int total;
  final Animation<double> progressAnim;
  final AnimationController progressAnimController;
  final bool hasProgress;
  final VoidCallback onFinalizar;
  final VoidCallback onCancelar;

  const _WorkoutAppBar({
    required this.sessaoNome,
    required this.elapsedFormatted,
    required this.completed,
    required this.total,
    required this.progressAnim,
    required this.progressAnimController,
    required this.hasProgress,
    required this.onFinalizar,
    required this.onCancelar,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: onCancelar,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.labelSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sessaoNome,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.4,
                              color: AppColors.labelPrimary,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                elapsedFormatted,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.labelTertiary,
                                  letterSpacing: 0.4,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Container(
                                  width: 1,
                                  height: 10,
                                  color: AppColors.labelQuaternary,
                                ),
                              ),
                              Text(
                                '$completed / $total séries',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.labelTertiary,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: GestureDetector(
                        key: ValueKey(hasProgress),
                        onTap: hasProgress ? onFinalizar : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: hasProgress
                                ? AppColors.primary
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: Text(
                            'Finalizar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: hasProgress
                                  ? AppColors.background
                                  : AppColors.labelTertiary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: progressAnim,
              builder: (context, _) {
                final progress = progressAnim.value.clamp(0.0, 1.0);
                return Stack(
                  children: [
                    Container(height: 2, color: AppColors.surfaceLight),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withAlpha(180),
                              AppColors.primary,
                            ],
                          ),
                          boxShadow: progress > 0
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(100),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SwapExerciseSheet extends StatelessWidget {
  final List<ExercicioItem> selecionados;
  final ExercicioItem atual;

  const _SwapExerciseSheet({
    required this.selecionados,
    required this.atual,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.background.withAlpha(235),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trocar exercício',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white24),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha uma das alternativas configuradas pelo seu treinador.',
              style: TextStyle(
                color: Colors.white.withAlpha(120),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ...selecionados.map((ex) {
              final isAtual = ex.nome == atual.nome;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: isAtual ? null : () => Navigator.pop(context, ex),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isAtual ? AppColors.primary.withAlpha(20) : Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isAtual ? AppColors.primary.withAlpha(80) : Colors.white.withAlpha(10),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        ExercicioThumbnail(
                          exercicio: ex,
                          width: 50,
                          height: 50,
                          borderRadius: 12,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex.nome,
                                style: TextStyle(
                                  color: isAtual ? AppColors.primary : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ex.grupoMuscular.join(' • '),
                                style: TextStyle(
                                  color: Colors.white.withAlpha(100),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isAtual)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _FinalizarDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Finalizar treino?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.labelPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Suas realizações serão registradas.',
              style: TextStyle(fontSize: 14, color: AppColors.labelSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: const Center(
                        child: Text(
                          'Continuar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.labelPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: const Center(
                        child: Text(
                          'Finalizar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
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
    );
  }
}

class _CancelarDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.systemRed.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.systemRed,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cancelar treino?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.labelPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nenhum progresso será salvo.',
              style: TextStyle(fontSize: 14, color: AppColors.labelSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: const Center(
                        child: Text(
                          'Continuar treino',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.labelPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.systemRed.withAlpha(220),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      child: const Center(
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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
    );
  }
}

class _UltimoTreinoSheet extends StatelessWidget {
  final String exercicioNome;
  final List<SerieHistorico> historico;

  const _UltimoTreinoSheet({
    required this.exercicioNome,
    required this.historico,
  });

  String _labelTipo(TipoSerie tipo) {
    switch (tipo) {
      case TipoSerie.aquecimento:
        return 'Aquecimento';
      case TipoSerie.feeder:
        return 'Feeder';
      case TipoSerie.trabalho:
        return 'Série';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.lg,
        SpacingTokens.md,
        SpacingTokens.lg,
        SpacingTokens.screenBottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.labelQuaternary,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Text('Último treino', style: AppTheme.title1),
          const SizedBox(height: 4),
          Text(exercicioNome, style: AppTheme.caption),
          const SizedBox(height: SpacingTokens.sectionGap),
          if (historico.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.lg),
              child: Center(
                child: Text(
                  'Nenhum registro encontrado.',
                  style: AppTheme.caption,
                ),
              ),
            )
          else
            ...historico.map((h) {
              final label = '${_labelTipo(h.tipo)} ${h.indexDentroDoTipo + 1}';
              final peso = h.pesoRealizado ?? '—';
              final reps = h.repsRealizadas ?? '—';
              return Padding(
                padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(label, style: AppTheme.bodyText),
                    ),
                    Text(
                      '$peso kg  ×  $reps reps',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.labelPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}