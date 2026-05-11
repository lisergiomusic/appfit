import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Resumo do Treino',
          style: AppTheme.pageTitle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.premiumGradient,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 60, top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            if ((item.observacoes != null && item.observacoes!.isNotEmpty) || (item.esforco != null && item.esforco! > 0)) ...[
              _buildNotesSection(),
              const SizedBox(height: 32),
            ],
            _buildStatsRow(),
            const SizedBox(height: 32),
            _buildExercisesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final dateStr = DateFormat("dd MMM yyyy", 'pt_BR').format(item.dataHora).toUpperCase();
    final timeStr = DateFormat("HH:mm").format(item.dataHora);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.screenHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PersonalAlunoPerfilPage(
                    alunoId: item.alunoId,
                    alunoNome: item.alunoNome,
                    photoUrl: item.alunoPhotoUrl,
                  ),
                ),
              );
            },
            child: Row(
              children: [
                AppAvatar(name: item.alunoNome, photoUrl: item.alunoPhotoUrl, radius: 24, showBorder: false),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.alunoNome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'VER PERFIL DO ALUNO',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.2)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(SpacingTokens.xs),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'TREINO REALIZADO',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 10),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$dateStr • $timeStr',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.sessaoNome.isEmpty ? 'Sessão Individual' : item.sessaoNome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    double volume = 0;
    int sets = 0;
    for (var ex in item.exercicios) {
      final s = (ex['series'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      sets += s.length;
      for (var sItem in s) {
        final p = double.tryParse(sItem['pesoRealizado']?.toString() ?? '0') ?? 0;
        final r = int.tryParse(sItem['repsRealizadas']?.toString() ?? '0') ?? 0;
        volume += p * r;
      }
    }

    final volStr = volume >= 1000 ? (volume / 1000).toStringAsFixed(1) : volume.toInt().toString();
    final volUnit = volume >= 1000 ? 't' : 'kg';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.screenHorizontalPadding),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(SpacingTokens.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _StatItem(value: '${item.duracaoMinutos}', label: 'MINUTOS'),
          _StatDivider(),
          _StatItem(value: '$sets', label: 'SÉRIES'),
          _StatDivider(),
          _StatItem(value: volStr, label: 'VOLUME ($volUnit)'),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    final effortVal = item.esforco != null && item.esforco! > 0 ? '${item.esforco}' : null;
    final hasObservacoes = item.observacoes != null && item.observacoes!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.screenHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FEEDBACK DO ALUNO',
            style: AppTheme.sectionHeader,
          ),
          const SizedBox(height: SpacingTokens.labelToField),
          if (hasObservacoes) ...[
            Container(

              padding: const EdgeInsets.only( top: 4, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    color: AppColors.labelSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.observacoes!,
                      style: TextStyle(
                        color: AppColors.labelPrimary,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpacingTokens.sectionGap),
          ],
          if (effortVal != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INTENSIDADE RELATADA',
                      style: AppTheme.microLabelTextStyle.copyWith(
                        color: AppColors.primary.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Percepção de Esforço (RPE)',
                      style: AppTheme.caption.copyWith(
                        color: AppColors.labelTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      effortVal,
                      style: AppTheme.bigTitle.copyWith(
                        fontSize: 32,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ 10',
                      style: AppTheme.microLabelTextStyle.copyWith(
                        color: AppColors.labelQuaternary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildExercisesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SpacingTokens.screenHorizontalPadding),
          child: Text(
            'EXERCÍCIOS REALIZADOS',
            style: AppTheme.sectionHeader,
          ),
        ),
        const SizedBox(height: SpacingTokens.labelToField + 4),
        ...item.exercicios.map((ex) => _ExerciseListItem(exercicio: ex)),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatItem({
    required this.value,
    required this.label,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }
}

class _ExerciseListItem extends StatefulWidget {
  final Map<String, dynamic> exercicio;

  const _ExerciseListItem({required this.exercicio});

  @override
  State<_ExerciseListItem> createState() => _ExerciseListItemState();
}

class _ExerciseListItemState extends State<_ExerciseListItem> {
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
          .then((e) => e?.mediaUrl != null ? Cloudinary.thumbnail(e!.mediaUrl!) : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = widget.exercicio['nome']?.toString() ?? '';
    final series = (widget.exercicio['series'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Padding(
      padding: const EdgeInsets.only(
        left: SpacingTokens.screenHorizontalPadding,
        right: SpacingTokens.screenHorizontalPadding,
        bottom: 24,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(SpacingTokens.sm),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FutureBuilder<String?>(
                    future: _thumbnailFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return CachedNetworkImage(
                          imageUrl: snapshot.data!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const SizedBox(),
                          errorWidget: (context, url, error) => const Icon(Icons.fitness_center, color: Colors.white24, size: 18),
                        );
                      }
                      return const Icon(Icons.fitness_center, color: Colors.white24, size: 18);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
            if (series.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    _buildTableHeader('SÉRIE', flex: 2),
                    _buildTableHeader('PESO', flex: 3),
                    _buildTableHeader('REPS', flex: 3),
                    _buildTableHeader('ALVO', flex: 3, alignment: TextAlign.right),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                ),
                child: Column(
                  children: series.asMap().entries.map((e) {
                    final i = e.key;
                    final s = e.value;
                    final peso = s['pesoRealizado']?.toString() ?? '0';
                    final reps = s['repsRealizadas']?.toString() ?? '0';
                    final alvo = s['alvo']?.toString() ?? '-';
                    final tipo = s['tipo']?.toString().toLowerCase() ?? 'trabalho';
                    final isWarmup = tipo == 'aquecimento';
                    final isLast = i == series.length - 1;

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      decoration: BoxDecoration(
                        border: isLast ? null : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: isWarmup
                              ? Tooltip(
                                  message: 'Série de Aquecimento',
                                  triggerMode: TooltipTriggerMode.tap,
                                  preferBelow: false,
                                  child: Text(
                                    'A${i + 1}',
                                    style: TextStyle(
                                      color: Colors.amber.withValues(alpha: 0.5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                )
                              : Text(
                                  '${i + 1}º',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${peso}kg',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              reps,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              alvo,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String label, {required int flex, TextAlign alignment = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: alignment,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.2),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}