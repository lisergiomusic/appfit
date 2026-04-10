import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bar_divider.dart';
import 'models/rotina_model.dart';
import 'controllers/executar_treino_controller.dart';
import 'widgets/executar_treino/treino_scrollable_body.dart';
import 'widgets/executar_treino/rest_timer_sheet.dart';

class ExecutarTreinoPage extends StatefulWidget {
  final SessaoTreinoModel sessao;
  final String rotinaId;
  final String alunoId;

  const ExecutarTreinoPage({
    super.key,
    required this.sessao,
    required this.rotinaId,
    required this.alunoId,
  });

  @override
  State<ExecutarTreinoPage> createState() => _ExecutarTreinoPageState();
}

class _ExecutarTreinoPageState extends State<ExecutarTreinoPage> {
  late ExecutarTreinoController _controller;

  // Duration tracking
  late DateTime _startedAt;

  // Recorded data
  final Map<String, dynamic> _recordedData = {};

  // Controllers matrix
  late List<List<TextEditingController>> _repsControllers;
  late List<List<TextEditingController>> _pesoControllers;

  // Rest timer
  final ValueNotifier<int> _restSecondsNotifier = ValueNotifier(0);
  PersistentBottomSheetController? _restSheetController;
  Timer? _restTimer;
  int? _restTotalSeconds;
  String? _restExercicioNome;

  // Elapsed timer
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;

  // Loading
  bool _isLoading = false;

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
  }

  void _initializeRecordedData() {
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
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _elapsedTimer?.cancel();
    _restSecondsNotifier.dispose();

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

  bool _hasAnyProgress() => widget.sessao.exercicios.asMap().keys.any(
    (i) => _completedSeriesForExercise(i) > 0,
  );

  int _parseDescanso(String descanso) {
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

  void _onSerieCompleted(int exercicioIndex, int serieIndex) {
    final key = 'exercicio_$exercicioIndex';
    final currentComplete =
        _recordedData[key]['series'][serieIndex]['completa'] as bool;

    if (currentComplete) {
      // Undo completion
      setState(() {
        _recordedData[key]['series'][serieIndex]['completa'] = false;
      });
      return;
    }

    // Mark complete - capture current input values
    setState(() {
      _recordedData[key]['series'][serieIndex]['completa'] = true;
      _recordedData[key]['series'][serieIndex]['reps'] =
          _repsControllers[exercicioIndex][serieIndex].text;
      _recordedData[key]['series'][serieIndex]['peso'] =
          _pesoControllers[exercicioIndex][serieIndex].text;
    });

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

    _restSheetController = Scaffold.of(context).showBottomSheet(
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
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Finalizar treino?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Suas realizações serão registradas.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CONTINUAR',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'FINALIZAR',
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final elapsed = DateTime.now().difference(_startedAt);
        final duracaoMinutos = elapsed.inMinutes;

        await _controller.saveTreinoLog(
          _recordedData,
          duracaoMinutos: duracaoMinutos,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Treino registrado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: $e'),
              backgroundColor: Colors.red,
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
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Cancelar treino?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Seu progresso será perdido e nada será registrado.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CONTINUAR TREINO',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'CANCELAR TREINO',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) Navigator.pop(context);
    } else {
      // Restart rest timer if it was active
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmarCancelamento();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Column(
            children: [
              Text(widget.sessao.nome, style: AppTheme.pageTitle),
              Text(
                _formatElapsed(_elapsedSeconds),
                style: AppTheme.caption2.copyWith(
                  color: AppColors.labelSecondary,
                ),
              ),
            ],
          ),
          centerTitle: true,
          bottom: const AppBarDivider(),
          actions: [
            TextButton(
              onPressed: _hasAnyProgress() ? _finalizarTreino : null,
              child: Text(
                'Finalizar',
                style: TextStyle(
                  color: _hasAnyProgress()
                      ? AppColors.primary
                      : AppColors.labelTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Cancelar treino',
              onPressed: _confirmarCancelamento,
            ),
          ],
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
              ),
      ),
    );
  }
}
