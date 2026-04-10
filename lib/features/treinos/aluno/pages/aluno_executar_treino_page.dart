import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../../core/theme/app_theme.dart';
import '../../shared/models/rotina_model.dart';
import '../controllers/executar_treino_controller.dart';
import '../../shared/widgets/executar_treino/treino_scrollable_body.dart';
import '../../shared/widgets/executar_treino/rest_timer_sheet.dart';

/// Tela de execução da sessão com marcação de séries e timer de descanso.
class AlunoExecutarTreinoPage extends StatefulWidget {
  final SessaoTreinoModel sessao;
  final String rotinaId;
  final String alunoId;

  const AlunoExecutarTreinoPage({
    super.key,
    required this.sessao,
    required this.rotinaId,
    required this.alunoId,
  });

  @override
  State<AlunoExecutarTreinoPage> createState() =>
      _AlunoExecutarTreinoPageState();
}

class _AlunoExecutarTreinoPageState extends State<AlunoExecutarTreinoPage>
    with TickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late ExecutarTreinoController _controller;

  late DateTime _startedAt;
  final Map<String, dynamic> _recordedData = {};
  late List<List<TextEditingController>> _repsControllers;
  late List<List<TextEditingController>> _pesoControllers;

  final ValueNotifier<int> _restSecondsNotifier = ValueNotifier(0);
  PersistentBottomSheetController? _restSheetController;
  Timer? _restTimer;
  int? _restTotalSeconds;
  String? _restExercicioNome;

  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;

  bool _isLoading = false;

  late AnimationController _progressAnimController;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _controller = ExecutarTreinoController(
      sessao: widget.sessao,
      rotinaId: widget.rotinaId,
      alunoId: widget.alunoId,
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
    _restTimer?.cancel();
    _elapsedTimer?.cancel();
    _restSecondsNotifier.dispose();
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
      widget.sessao.exercicios.fold(0, (sum, e) => sum + e.series.length);

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

  int _parseDescanso(String descanso) {
    // Aceita formatos como "90", "90s" e "1m 30s".
    final cleaned = descanso.trim().toLowerCase();
    final mMatch = RegExp(r'(\d+)\s*m').firstMatch(cleaned);
    final sMatch = RegExp(r'(\d+)\s*s').firstMatch(cleaned);
    if (mMatch != null || sMatch != null) {
      final minutes = mMatch != null ? int.parse(mMatch.group(1)!) : 0;
      final seconds = sMatch != null ? int.parse(sMatch.group(1)!) : 0;
      return (minutes * 60) + seconds;
    }
    return int.tryParse(RegExp(r'\d+').firstMatch(cleaned)?.group(0) ?? '') ??
        60;
  }

  void _onMarcarTodasSeries(int exercicioIndex, bool marcar) {
    final key = 'exercicio_$exercicioIndex';
    HapticFeedback.mediumImpact();
    setState(() {
      final series = _recordedData[key]['series'] as List;
      for (var i = 0; i < series.length; i++) {
        series[i]['completa'] = marcar;
        if (marcar) {
          series[i]['reps'] = _repsControllers[exercicioIndex][i].text;
          series[i]['peso'] = _pesoControllers[exercicioIndex][i].text;
        }
      }
    });
    _animateProgress();
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

    final serie = widget.sessao.exercicios[exercicioIndex].series[serieIndex];
    _startRestTimer(
      serie.descanso,
      widget.sessao.exercicios[exercicioIndex].nome,
    );
  }

  void _startRestTimer(String descansoStr, String exercicioNome) {
    _restTimer?.cancel();
    _restSheetController?.close();

    final totalSeconds = _parseDescanso(descansoStr);
    _restSecondsNotifier.value = totalSeconds;
    _restTotalSeconds = totalSeconds;
    _restExercicioNome = exercicioNome;

    _restSheetController = _scaffoldKey.currentState!.showBottomSheet(
      (ctx) => ValueListenableBuilder<int>(
        valueListenable: _restSecondsNotifier,
        builder: (context, seconds, _) => RestTimerSheet(
          remainingSeconds: seconds,
          totalSeconds: _restTotalSeconds!,
          exercicioNome: _restExercicioNome!,
          onSkip: _skipRest,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = _restSecondsNotifier.value - 1;
      _restSecondsNotifier.value = next;
      if (next <= 0) {
        timer.cancel();
        _dismissRestSheet();
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    _dismissRestSheet();
  }

  void _dismissRestSheet() {
    _restSheetController?.close();
    _restSheetController = null;
    _restSecondsNotifier.value = 0;
  }

  Future<void> _finalizarTreino() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _FinalizarDialog(),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final elapsed = DateTime.now().difference(_startedAt);
        await _controller.saveTreinoLog(
          _recordedData,
          duracaoMinutos: elapsed.inMinutes,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Treino registrado com sucesso!'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: $e'),
              backgroundColor: AppColors.systemRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmarCancelamento() async {
    _restTimer?.cancel();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _CancelarDialog(),
    );

    if (confirm == true) {
      if (mounted) Navigator.pop(context);
    } else {
      if (_restTotalSeconds != null && _restTotalSeconds! > 0) {
        _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          final next = _restSecondsNotifier.value - 1;
          _restSecondsNotifier.value = next;
          if (next <= 0) {
            timer.cancel();
            _dismissRestSheet();
          }
        });
      }
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
        key: _scaffoldKey,
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
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : TreinoScrollableBody(
                sessao: widget.sessao,
                recordedData: _recordedData,
                repsControllers: _repsControllers,
                pesoControllers: _pesoControllers,
                onSerieCompleted: _onSerieCompleted,
                onMarcarTodasSeries: _onMarcarTodasSeries,
                alunoId: widget.alunoId,
                ultimoHistorico: _controller.ultimoHistorico,
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
