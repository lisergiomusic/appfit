import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bar_divider.dart';
import 'models/rotina_model.dart';
import 'models/exercicio_model.dart';
import 'controllers/executar_treino_controller.dart';

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
  int _currentExerciseIndex = 0;
  int _currentSerieIndex = 0;
  int? _restTimer;
  Timer? _timer;
  final Map<String, dynamic> _recordedData = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = ExecutarTreinoController(
      sessao: widget.sessao,
      rotinaId: widget.rotinaId,
      alunoId: widget.alunoId,
    );
    _initializeRecordedData();
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

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startRestTimer(String descansoStr) {
    _timer?.cancel();

    int segundos = _parseDescanso(descansoStr);
    _restTimer = segundos;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _restTimer = _restTimer! - 1;
      });

      if (_restTimer! <= 0) {
        _timer?.cancel();
        _advanceToNextSerie();
      }
    });
  }

  int _parseDescanso(String descanso) {
    final cleaned = descanso.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 60;
  }

  void _advanceToNextSerie() {
    final exercise = widget.sessao.exercicios[_currentExerciseIndex];

    if (_currentSerieIndex < exercise.series.length - 1) {
      setState(() {
        _currentSerieIndex++;
        _restTimer = null;
      });
    } else if (_currentExerciseIndex < widget.sessao.exercicios.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSerieIndex = 0;
        _restTimer = null;
      });
    }
  }

  void _markSerieComplete() {
    final key = 'exercicio_$_currentExerciseIndex';
    _recordedData[key]['series'][_currentSerieIndex]['completa'] = true;
    _startRestTimer(
      widget
          .sessao
          .exercicios[_currentExerciseIndex]
          .series[_currentSerieIndex]
          .descanso,
    );
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
        await _controller.saveTreinoLog(_recordedData);
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

  @override
  Widget build(BuildContext context) {
    final exercise = widget.sessao.exercicios[_currentExerciseIndex];
    final serie = exercise.series[_currentSerieIndex];
    final progressTotal =
        ((_currentExerciseIndex * 100) +
            (_currentSerieIndex * (100 / exercise.series.length))) /
        widget.sessao.exercicios.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.sessao.nome),
        bottom: const AppBarDivider(),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _restTimer != null
          ? _buildRestScreen()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingScreen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressBar(progressTotal),
                    const SizedBox(height: SpacingTokens.sectionGap),
                    _buildExerciseHeader(exercise),
                    const SizedBox(height: SpacingTokens.sectionGap),
                    _buildSerieInput(serie),
                    const SizedBox(height: SpacingTokens.sectionGap),
                    _buildActionButtons(),
                    const SizedBox(height: SpacingTokens.screenBottomPadding),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Exercício ${_currentExerciseIndex + 1} de ${widget.sessao.exercicios.length}',
              style: AppTheme.formLabel,
            ),
            Text(
              'Série ${_currentSerieIndex + 1} de ${widget.sessao.exercicios[_currentExerciseIndex].series.length}',
              style: AppTheme.caption2,
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress / 100,
            minHeight: 8,
            backgroundColor: AppColors.primary.withAlpha(15),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseHeader(ExercicioItem exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(exercise.nome, style: AppTheme.pageTitle),
        if (exercise.grupoMuscular.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              children: exercise.grupoMuscular
                  .map(
                    (g) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(g, style: AppTheme.caption2),
                    ),
                  )
                  .toList(),
            ),
          ),
        if (exercise.hasInstrucoesPadrao ||
            exercise.hasInstrucoesPersonalizadas)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                if (exercise.hasInstrucoesPadrao)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.labelQuaternary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.instrucoesPadraoTexto!,
                          style: AppTheme.cardSubtitle,
                        ),
                      ],
                    ),
                  ),
                if (exercise.hasInstrucoesPadrao &&
                    exercise.hasInstrucoesPersonalizadas)
                  const SizedBox(height: 8),
                if (exercise.hasInstrucoesPersonalizadas)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instruções do personal',
                          style: AppTheme.caption.copyWith(
                            color: AppColors.labelSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          exercise.instrucoesPersonalizadasTexto!,
                          style: AppTheme.cardSubtitle,
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

  Widget _buildSerieInput(SerieItem serie) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Série ${_currentSerieIndex + 1}', style: AppTheme.pageTitle),
          const SizedBox(height: SpacingTokens.sectionGap),
          _buildInputField(
            label: 'Repetições (alvo: ${serie.alvo})',
            hint: 'Quantas reps completou?',
            onChanged: (value) {
              final key = 'exercicio_$_currentExerciseIndex';
              _recordedData[key]['series'][_currentSerieIndex]['reps'] = value;
            },
          ),
          const SizedBox(height: SpacingTokens.sectionGap),
          _buildInputField(
            label: 'Peso utilizado (alvo: ${serie.carga}kg)',
            hint: 'Qual peso em kg?',
            onChanged: (value) {
              final key = 'exercicio_$_currentExerciseIndex';
              _recordedData[key]['series'][_currentSerieIndex]['peso'] = value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.formLabel),
        const SizedBox(height: 8),
        TextField(
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _markSerieComplete,
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('Série Completa'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        if (_currentExerciseIndex == widget.sessao.exercicios.length - 1 &&
            _currentSerieIndex ==
                widget.sessao.exercicios[_currentExerciseIndex].series.length -
                    1)
          ElevatedButton.icon(
            onPressed: _finalizarTreino,
            icon: const Icon(Icons.flag_rounded),
            label: const Text('Finalizar Treino'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildRestScreen() {
    final minutos = _restTimer! ~/ 60;
    final segundos = _restTimer! % 60;
    final timeStr =
        '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Descansando...', style: AppTheme.title1),
          const SizedBox(height: SpacingTokens.xxl),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withAlpha(30),
            ),
            child: Center(
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.xxl),
          Text(
            'Próxima série em alguns segundos...',
            style: AppTheme.cardSubtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacingTokens.sectionGap),
          ElevatedButton(
            onPressed: () {
              _timer?.cancel();
              setState(() => _restTimer = null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Próximo Exercício'),
          ),
        ],
      ),
    );
  }
}
