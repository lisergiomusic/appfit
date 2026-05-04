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
    final dataFormatada = DateFormat("d 'de' MMM 'de' yyyy, HH:mm", 'pt_BR')
        .format(item.dataHora);

    return Container(
      padding: CardTokens.padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                name: item.alunoNome,
                photoUrl: item.alunoPhotoUrl,
                radius: AvatarTokens.lg,
                showBorder: false,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.alunoNome, style: AppTheme.cardTitle.copyWith(
                      fontSize: 20,
                    )),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      item.sessaoNome.isEmpty
                          ? 'Concluiu um treino'
                          : 'Concluiu o treino "${item.sessaoNome}"',
                      style: AppTheme.cardSubtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.md),
          Divider(height: 1, thickness: 0.5, color: AppColors.separator),
          const SizedBox(height: SpacingTokens.md),
          Row(
            children: [
              _MetaChip(
                icon: Icons.calendar_today_rounded,
                label: dataFormatada,
              ),
              if (item.duracaoMinutos > 0) ...[
                const SizedBox(width: SpacingTokens.sm),
                _MetaChip(
                  icon: Icons.timer_rounded,
                  label: '${item.duracaoMinutos} min',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.labelSecondary),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.caption),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Feedback do aluno', style: AppTheme.sectionHeader),
        const SizedBox(height: SpacingTokens.labelToField),
        Container(
          width: double.infinity,
          padding: CardTokens.padding,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: Colors.white.withAlpha(8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (esforco != null && esforco! > 0) ...[
                Row(
                  children: [
                    _EsforcoBar(valor: esforco!),
                    const SizedBox(width: SpacingTokens.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$esforco/10',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _color(esforco!),
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.xs),
                        Text(
                          _label(esforco!),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _color(esforco!).withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (observacoes != null && observacoes!.isNotEmpty)
                  const SizedBox(height: SpacingTokens.md),
              ],
              if (observacoes != null && observacoes!.isNotEmpty) ...[
                if (esforco != null && esforco! > 0)
                  Divider(
                      height: 1,
                      thickness: 0.5,
                      color: AppColors.separator),
                if (esforco != null && esforco! > 0)
                  const SizedBox(height: SpacingTokens.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.format_quote_rounded,
                        size: 16, color: AppColors.labelTertiary),
                    const SizedBox(width: SpacingTokens.sm),
                    Expanded(
                      child: Text(
                        observacoes!,
                        style: AppTheme.bodyText.copyWith(
                          color: AppColors.labelSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EsforcoBar extends StatelessWidget {
  final int valor;
  const _EsforcoBar({required this.valor});

  Color _color(int v) {
    if (v <= 5) return AppColors.primary;
    if (v <= 7) return AppColors.accentMetrics;
    if (v <= 9) return const Color(0xFFFF6B35);
    return AppColors.systemRed;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(valor);
    return SizedBox(
      width: 8,
      height: 48,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(color: AppColors.surfaceLight),
            FractionallySizedBox(
              heightFactor: valor / 10,
              child: Container(color: color),
            ),
          ],
        ),
      ),
    );
  }
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