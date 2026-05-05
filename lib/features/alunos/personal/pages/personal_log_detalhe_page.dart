import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/aluno_service.dart';
import '../../../../core/services/exercise_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/cloudinary.dart';
import '../../../alunos/shared/widgets/app_avatar.dart';
import 'personal_aluno_perfil_page.dart';

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
        elevation: 0,
        scrolledUnderElevation: 0,
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

class _Thumbnail extends StatelessWidget {
  final Future<String?> thumbnailFuture;
  const _Thumbnail({required this.thumbnailFuture});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withAlpha(40),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      clipBehavior: Clip.antiAlias,
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
            return const Icon(Icons.fitness_center, color: AppColors.labelTertiary, size: 22);
          }
          return CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: Colors.black.withAlpha(20)),
            errorWidget: (_, _, _) => const Icon(Icons.fitness_center, color: AppColors.labelTertiary, size: 22),
          );
        },
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
          style: AppTheme.bigTitle,
        ),
        const SizedBox(height: 12),
        InkWell(
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Execução Detalhada', style: AppTheme.sectionHeader),
            Text(
              '${exercicios.length} EXERCÍCIOS',
              style: AppTheme.microLabelTextStyle.copyWith(color: AppColors.labelTertiary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: exercicios.length,
          itemBuilder: (context, index) => _ExercicioPerformanceCard(
            exercicio: exercicios[index],
            index: index + 1,
          ),
        ),
      ],
    );
  }
}

class _ExercicioPerformanceCard extends StatefulWidget {
  final Map<String, dynamic> exercicio;
  final int index;
  const _ExercicioPerformanceCard({required this.exercicio, required this.index});

  @override
  State<_ExercicioPerformanceCard> createState() => _ExercicioPerformanceCardState();
}

class _ExercicioPerformanceCardState extends State<_ExercicioPerformanceCard> {
  final ExerciseService _exerciseService = ExerciseService();
  late final Future<String?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    final nome = widget.exercicio['nome']?.toString() ?? '';
    final mediaUrl = widget.exercicio['media_url']?.toString();

    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      _thumbnailFuture = Future.value(Cloudinary.thumbnail(mediaUrl));
    } else {
      _thumbnailFuture = _exerciseService
          .buscarExercicioPorNome(nome)
          .then((base) {
            final url = base?.mediaUrl;
            return url != null ? Cloudinary.thumbnail(url) : null;
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = widget.exercicio['nome']?.toString() ?? '';
    final series = (widget.exercicio['series'] as List?)?.cast<Map<String, dynamic>>() ?? [];


    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header com Info de Performance
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumbnail(thumbnailFuture: _thumbnailFuture),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome.toUpperCase(),
                        style: AppTheme.cardTitle.copyWith(
                          fontSize: 15,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _Badge(
                            label: '${series.length} SÉRIES',
                            color: AppColors.labelSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de Séries (Layout Moderno)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(20),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header das Colunas
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          'SÉRIE',
                          style: AppTheme.microLabelTextStyle.copyWith(
                            fontSize: 9,
                            color: AppColors.labelTertiary,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Text(
                          'EXECUTADO',
                          style: AppTheme.microLabelTextStyle.copyWith(
                            fontSize: 9,
                            color: AppColors.labelTertiary,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          'META',
                          style: AppTheme.microLabelTextStyle.copyWith(
                            fontSize: 9,
                            color: AppColors.labelTertiary,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < series.length; i++)
                  _SeriePerformanceRow(
                    serie: series[i],
                    index: i,
                    totalSeries: series.length,
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriePerformanceRow extends StatelessWidget {
  final Map<String, dynamic> serie;
  final int index;
  final int totalSeries;

  const _SeriePerformanceRow({
    required this.serie,
    required this.index,
    required this.totalSeries,
  });

  @override
  Widget build(BuildContext context) {
    final tipoStr = serie['tipo']?.toString() ?? 'trabalho';
    final concluida = serie['concluida'] == true;
    final pesoReal = serie['pesoRealizado']?.toString() ?? '0';
    final repsReal = serie['repsRealizadas']?.toString() ?? '0';
    final repsAlvo = serie['alvo']?.toString() ?? '0';


    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(concluida ? 5 : 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Indicador de Ordem
          _OrderCircle(index: index + 1, tipo: tipoStr),
          const SizedBox(width: 24),

          // Dados Realizados (Destaque Principal)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  pesoReal,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: concluida ? AppColors.labelPrimary : AppColors.labelTertiary,
                  ),
                ),
                Text('kg', style: AppTheme.caption2.copyWith(color: AppColors.labelTertiary)),
                const SizedBox(width: 8),
                Text(
                  '×',
                  style: TextStyle(color: AppColors.primary.withAlpha(150), fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  repsReal,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: concluida ? AppColors.labelPrimary : AppColors.labelTertiary,
                  ),
                ),
                Text(' reps', style: AppTheme.caption2.copyWith(color: AppColors.labelTertiary)),
              ],
            ),
          ),

          // Comparativo com Alvo
          SizedBox(
            width: 50,
            child: Text(
              repsAlvo,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.labelSecondary.withAlpha(100),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCircle extends StatelessWidget {
  final int index;
  final String tipo;
  const _OrderCircle({required this.index, required this.tipo});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.primary;
    if (tipo == 'aquecimento') color = const Color(0xFF00B4D8);
    if (tipo == 'feeder') color = const Color(0xFFFFB703);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withAlpha(40), width: 1),
      ),
      child: Center(
        child: Text(
          index.toString(),
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}