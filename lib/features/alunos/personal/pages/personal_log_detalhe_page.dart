import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/aluno_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../alunos/shared/widgets/aluno_avatar.dart';

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
              AlunoAvatar(
                alunoNome: item.alunoNome,
                photoUrl: item.alunoPhotoUrl,
                radius: AvatarTokens.md,
                showBorder: false,
              ),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.alunoNome, style: AppTheme.cardTitle),
                    const SizedBox(height: SpacingTokens.xs),
                    Text('Concluiu ${item.sessaoNome}',
                        style: AppTheme.cardSubtitle),
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
        Text('Exercícios', style: AppTheme.sectionHeader),
        const SizedBox(height: SpacingTokens.labelToField),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(color: Colors.white.withAlpha(8)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < exercicios.length; i++) ...[
                _ExercicioTile(exercicio: exercicios[i]),
                if (i < exercicios.length - 1)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: SpacingTokens.cardPaddingH,
                    color: AppColors.separator,
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
  bool _expandido = false;

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

    final seriesConcluidas =
        series.where((s) => s['concluida'] == true).length;

    return InkWell(
      onTap: series.isNotEmpty
          ? () => setState(() => _expandido = !_expandido)
          : null,
      child: Padding(
        padding: CardTokens.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome, style: AppTheme.cardTitle),
                      if (grupos.isNotEmpty) ...[
                        const SizedBox(height: SpacingTokens.xs),
                        Text(
                          grupos.join(' · '),
                          style: AppTheme.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                _SeriesCounter(
                    concluidas: seriesConcluidas, total: series.length),
                if (series.isNotEmpty) ...[
                  const SizedBox(width: SpacingTokens.xs),
                  Icon(
                    _expandido
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.labelSecondary,
                  ),
                ],
              ],
            ),
            if (_expandido && series.isNotEmpty) ...[
              const SizedBox(height: SpacingTokens.md),
              _SeriesTable(series: series),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeriesCounter extends StatelessWidget {
  final int concluidas;
  final int total;
  const _SeriesCounter({required this.concluidas, required this.total});

  @override
  Widget build(BuildContext context) {
    final completo = concluidas == total && total > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: completo
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        '$concluidas/$total séries',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: completo ? AppColors.primary : AppColors.labelSecondary,
        ),
      ),
    );
  }
}

class _SeriesTable extends StatelessWidget {
  final List<Map<String, dynamic>> series;
  const _SeriesTable({required this.series});

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'aquecimento':
        return 'Aq';
      case 'feeder':
        return 'F';
      default:
        return 'T';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(28),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
        3: FixedColumnWidth(24),
      },
      children: [
        TableRow(
          children: [
            _HeaderCell(''),
            _HeaderCell('Realizado'),
            _HeaderCell('Alvo'),
            _HeaderCell(''),
          ],
        ),
        for (var i = 0; i < series.length; i++)
          _buildSerieRow(series[i], i + 1),
      ],
    );
  }

  TableRow _buildSerieRow(Map<String, dynamic> serie, int numero) {
    final tipo = serie['tipo']?.toString() ?? 'trabalho';
    final concluida = serie['concluida'] == true;
    final peso = serie['pesoRealizado']?.toString() ?? '';
    final reps = serie['repsRealizadas']?.toString() ?? '';
    final pesoAlvo = serie['cargaAlvo']?.toString() ?? '';
    final alvo = serie['alvo']?.toString() ?? '';

    final realizado =
        peso.isNotEmpty && reps.isNotEmpty ? '$peso kg × $reps' : '—';
    final alvotxt =
        pesoAlvo.isNotEmpty ? '$pesoAlvo kg × $alvo' : alvo.isNotEmpty ? alvo : '—';

    return TableRow(
      children: [
        _Cell(
          child: Text(
            _tipoLabel(tipo),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.labelTertiary,
            ),
          ),
        ),
        _Cell(
          child: Text(
            realizado,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: concluida ? AppColors.labelPrimary : AppColors.labelTertiary,
            ),
          ),
        ),
        _Cell(
          child: Text(
            alvotxt,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.labelTertiary,
            ),
          ),
        ),
        _Cell(
          child: Icon(
            concluida ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: concluida ? AppColors.primary : AppColors.labelTertiary,
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.labelTertiary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final Widget child;
  const _Cell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: child,
    );
  }
}
