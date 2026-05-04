import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/aluno_service.dart';
import '../../../../core/services/exercise_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/cloudinary.dart';
import '../../../treinos/shared/models/exercicio_model.dart';
import '../../../treinos/shared/widgets/executar_treino/serie_badge_info_dialog.dart';
import '../../../alunos/shared/widgets/app_avatar.dart';

class PersonalLogDetalhePage extends StatelessWidget {
  final AtividadeRecenteItem item;

  const PersonalLogDetalhePage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final temFeedback = (item.esforco != null && item.esforco! > 0) ||
        (item.observacoes != null && item.observacoes!.isNotEmpty);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(item.sessaoNome, style: AppTheme.pageTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.screenHorizontalPadding,
          vertical: SpacingTokens.screenTopPadding,
        ),
        children: [
          _CabecalhoCard(item: item),
          if (temFeedback) ...[
            const SizedBox(height: SpacingTokens.sectionGap),
            _FeedbackCard(
              esforco: item.esforco,
              observacoes: item.observacoes,
            ),
          ],
          const SizedBox(height: SpacingTokens.sectionGap),
          _ExerciciosSection(exercicios: item.exercicios),
          const SizedBox(height: SpacingTokens.screenBottomPadding),
        ],
      ),
    );
  }
}

class _CabecalhoCard extends StatelessWidget {
  final AtividadeRecenteItem item;
  const _CabecalhoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat("d 'de' MMM", 'pt_BR').format(item.dataHora);
    final horaFormatada = DateFormat("HH:mm", 'pt_BR').format(item.dataHora);

    // Cálculos de Volume e Séries
    double volumeTotal = 0;
    int seriesTotais = 0;
    for (var ex in item.exercicios) {
      final series = (ex['series'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      seriesTotais += series.length;
      for (var s in series) {
        final peso = double.tryParse(s['pesoRealizado']?.toString() ?? '0') ?? 0;
        final reps = int.tryParse(s['repsRealizadas']?.toString() ?? '0') ?? 0;
        volumeTotal += peso * reps;
      }
    }

    final hasVolume = volumeTotal > 0;
    final volumeDisplay = volumeTotal >= 1000
        ? '${(volumeTotal / 1000).toStringAsFixed(1)}k'
        : volumeTotal.toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Section
        Text(
          item.sessaoNome.isEmpty ? 'Treino concluído' : item.sessaoNome,
          style: AppTheme.bigTitle.copyWith(
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            AppAvatar(
              name: item.alunoNome,
              photoUrl: item.alunoPhotoUrl,
              radius: 10,
              showBorder: false,
            ),
            const SizedBox(width: 8),
            Text(
              '${item.alunoNome} • $dataFormatada, $horaFormatada',
              style: AppTheme.caption.copyWith(
                color: AppColors.labelSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Summary Grid
        Row(
          children: [
            Expanded(
              child: _SummaryItem(
                label: 'DURAÇÃO',
                value: '${item.duracaoMinutos}',
                unit: 'min',
                icon: Icons.timer_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryItem(
                label: hasVolume ? 'VOLUME' : 'SÉRIES',
                value: hasVolume ? volumeDisplay : '$seriesTotais',
                unit: hasVolume ? 'kg' : 'total',
                icon: hasVolume ? Icons.fitness_center_rounded : Icons.reorder_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryItem(
                label: 'ESFORÇO',
                value: item.esforco != null && item.esforco! > 0 ? '${item.esforco}' : '—',
                unit: '/10',
                icon: Icons.bolt_rounded,
                valueColor: (item.esforco != null && item.esforco! > 0)
                    ? _getEsforcoColor(item.esforco!)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getEsforcoColor(int v) {
    if (v <= 5) return AppColors.primary;
    if (v <= 7) return AppColors.accentMetrics;
    if (v <= 9) return const Color(0xFFFF6B35);
    return AppColors.systemRed;
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color? valueColor;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.labelTertiary),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTheme.microLabelTextStyle.copyWith(
                  fontSize: 9,
                  color: AppColors.labelTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.labelPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: AppTheme.caption2.copyWith(
                  color: AppColors.labelTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final int? esforco;
  final String? observacoes;
  const _FeedbackCard({this.esforco, this.observacoes});

  String _label(int v) {
    if (v <= 3) return 'Fácil';
    if (v <= 5) return 'Moderado';
    if (v <= 7) return 'Intenso';
    if (v <= 9) return 'Muito intenso';
    return 'Exaustivo';
  }

  Color _color(int v) {
    if (v <= 5) return AppColors.primary;
    if (v <= 7) return AppColors.accentMetrics;
    if (v <= 9) return const Color(0xFFFF6B35);
    return AppColors.systemRed;
  }

  @override
  Widget build(BuildContext context) {
    final hasEsforco = esforco != null && esforco! > 0;
    final hasObs = observacoes != null && observacoes!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Feedback do aluno', style: AppTheme.sectionHeader),
        const SizedBox(height: SpacingTokens.labelToField),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: Colors.white.withAlpha(8)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (hasEsforco)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _RadialIntensity(valor: esforco!),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _label(esforco!).toUpperCase(),
                              style: AppTheme.microLabelTextStyle.copyWith(
                                color: _color(esforco!),
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Intensidade do Treino',
                              style: AppTheme.cardTitle.copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Escala subjetiva de esforço (RPE)',
                              style: AppTheme.caption.copyWith(
                                color: AppColors.labelTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (hasObs) ...[
                if (hasEsforco)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(height: 1, thickness: 0.5, color: Colors.white.withAlpha(5)),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(15),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Barra vertical de destaque (âncora visual)
                        Container(
                          width: 3,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(120),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.format_quote_rounded,
                                size: 24,
                                color: AppColors.primary.withAlpha(180),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                observacoes!,
                                style: AppTheme.bodyText.copyWith(
                                  color: AppColors.labelSecondary,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 15,
                                  height: 1.5,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RadialIntensity extends StatelessWidget {
  final int valor;
  const _RadialIntensity({required this.valor});

  Color _color(int v) {
    if (v <= 5) return AppColors.primary;
    if (v <= 7) return AppColors.accentMetrics;
    if (v <= 9) return const Color(0xFFFF6B35);
    return AppColors.systemRed;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(valor);
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: CustomPaint(
            painter: _RadialPainter(
              progress: valor / 10,
              color: color,
              backgroundColor: Colors.white.withAlpha(10),
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              valor.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1,
              ),
            ),
            Text(
              'RPE',
              style: AppTheme.microLabelTextStyle.copyWith(
                fontSize: 8,
                color: AppColors.labelTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RadialPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _RadialPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 6.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final foregroundPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      3.14159 * 2 * progress,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ExerciciosSection extends StatelessWidget {
  final List<Map<String, dynamic>> exercicios;
  const _ExerciciosSection({required this.exercicios});

  @override
  Widget build(BuildContext context) {
    if (exercicios.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Execução detalhada', style: AppTheme.sectionHeader),
        const SizedBox(height: SpacingTokens.labelToField),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: Colors.white.withAlpha(8)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < exercicios.length; i++) ...[
                _ExercicioTile(exercicio: exercicios[i]),
                if (i < exercicios.length - 1)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppColors.separator.withAlpha(40),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ExercicioTile extends StatefulWidget {
  final Map<String, dynamic> exercicio;
  const _ExercicioTile({required this.exercicio});

  @override
  State<_ExercicioTile> createState() => _ExercicioTileState();
}

class _ExercicioTileState extends State<_ExercicioTile> {
  final ExerciseService _exerciseService = ExerciseService();
  late final Future<String?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    final nome = widget.exercicio['nome']?.toString() ?? '';
    final mediaUrl = widget.exercicio['mediaUrl']?.toString();

    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      _thumbnailFuture = Future.value(Cloudinary.thumbnail(mediaUrl));
    } else {
      _thumbnailFuture = _exerciseService
          .buscarExercicioPorNome(nome)
          .then((base) => base?.mediaUrl != null ? Cloudinary.thumbnail(base!.mediaUrl!) : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = widget.exercicio['nome']?.toString() ?? '';
    final grupos = (widget.exercicio['grupoMuscular'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    final series =
        (widget.exercicio['series'] as List?)?.cast<Map<String, dynamic>>() ??
            [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Thumbnail(thumbnailFuture: _thumbnailFuture),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome, style: AppTheme.cardTitle.copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      grupos.isEmpty ? 'Geral' : grupos.join(' · '),
                      style: AppTheme.caption2.copyWith(
                        color: AppColors.labelTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (series.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SeriesTable(series: series),
          ],
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final Future<String?> thumbnailFuture;
  const _Thumbnail({required this.thumbnailFuture});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 48,
        height: 48,
        color: Colors.black.withAlpha(40),
        child: FutureBuilder<String?>(
          future: thumbnailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              );
            }
            final url = snapshot.data;
            if (url == null || url.isEmpty) {
              return const Icon(Icons.fitness_center, color: AppColors.labelTertiary, size: 20);
            }
            return CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.black.withAlpha(20)),
              errorWidget: (_, __, ___) => const Icon(Icons.fitness_center, color: AppColors.labelTertiary, size: 20),
            );
          },
        ),
      ),
    );
  }
}

class _SeriesTable extends StatelessWidget {
  final List<Map<String, dynamic>> series;
  const _SeriesTable({required this.series});

  IconData _getIcon(String tipo) {
    switch (tipo) {
      case 'aquecimento':
        return Icons.whatshot_rounded;
      case 'feeder':
        return Icons.trending_up_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  Color _getColor(String tipo) {
    switch (tipo) {
      case 'aquecimento':
        return const Color(0xFF00B4D8);
      case 'feeder':
        return const Color(0xFFFFB703);
      default:
        return const Color(0xFFFF3366);
    }
  }

  TipoSerie _toTipoSerie(String tipo) {
    switch (tipo) {
      case 'aquecimento':
        return TipoSerie.aquecimento;
      case 'feeder':
        return TipoSerie.feeder;
      default:
        return TipoSerie.trabalho;
    }
  }

  @override
  Widget build(BuildContext context) {
    int workSetCounter = 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 40),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'REALIZADO',
                  style: AppTheme.microLabelTextStyle.copyWith(
                    fontSize: 9,
                    color: AppColors.labelTertiary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'ALVO',
                  style: AppTheme.microLabelTextStyle.copyWith(
                    fontSize: 9,
                    color: AppColors.labelTertiary,
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),
        for (var i = 0; i < series.length; i++) ...[
          () {
            final tipoStr = series[i]['tipo']?.toString() ?? 'trabalho';
            final isTrabalho = tipoStr != 'aquecimento' && tipoStr != 'feeder';
            if (isTrabalho) workSetCounter++;
            return _buildSerieRow(context, series[i], isTrabalho ? workSetCounter : 0);
          }(),
          if (i < series.length - 1)
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Divider(
                height: 16,
                thickness: 0.5,
                color: Colors.white.withAlpha(8),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSerieRow(BuildContext context, Map<String, dynamic> serie, int numero) {
    final tipoStr = serie['tipo']?.toString() ?? 'trabalho';
    final tipo = _toTipoSerie(tipoStr);
    final isTrabalho = tipo == TipoSerie.trabalho;
    final concluida = serie['concluida'] == true;
    final peso = serie['pesoRealizado']?.toString() ?? '';
    final reps = serie['repsRealizadas']?.toString() ?? '';
    final pesoAlvo = serie['cargaAlvo']?.toString() ?? '';
    final alvo = serie['alvo']?.toString() ?? '';

    final realizado = peso.isNotEmpty && reps.isNotEmpty ? '$peso kg × $reps' : '—';
    final alvotxt = pesoAlvo.isNotEmpty ? '$pesoAlvo kg × $alvo' : alvo.isNotEmpty ? alvo : '—';

    final color = _getColor(tipoStr);
    final icon = _getIcon(tipoStr);

    final label = tipo == TipoSerie.aquecimento
        ? 'Série de Aquecimento'
        : tipo == TipoSerie.feeder
            ? 'Série Feeder'
            : 'Série de Trabalho';

    return Row(
      children: [
        Tooltip(
          message: label,
          triggerMode: TooltipTriggerMode.tap,
          preferBelow: false,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: isTrabalho
                  ? Text(
                      numero.toString(),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 14,
                      color: color,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            realizado,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: concluida ? AppColors.labelPrimary : AppColors.labelTertiary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            alvotxt,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.labelSecondary.withAlpha(150),
            ),
          ),
        ),
        Icon(
          concluida ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: concluida ? AppColors.primary : AppColors.labelTertiary.withAlpha(60),
        ),
      ],
    );
  }
}