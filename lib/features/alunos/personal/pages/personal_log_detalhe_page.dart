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
        title: Text(
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
            const SizedBox(height: SpacingTokens.sectionGap),
            _buildStatsRow(),
            const SizedBox(height: SpacingTokens.sectionGap),
            if ((item.observacoes != null && item.observacoes!.isNotEmpty) || (item.esforco != null && item.esforco! > 0)) ...[
              _buildNotesSection(),
              const SizedBox(height: SpacingTokens.sectionGap),
            ],
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
                          fontWeight: FontWeight.w600,
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
                            fontWeight: FontWeight.w600,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.screenHorizontalPadding),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              value: '${item.duracaoMinutos}',
              label: 'MINUTOS',
            ),
          ),
          Expanded(
            child: _StatItem(
              value: '$sets',
              label: 'SÉRIES',
            ),
          ),
          Expanded(
            child: _StatItem(
              value: volStr,
              label: 'VOLUME ($volUnit)',
              showSeparator: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    final effortVal = item.esforco != null && item.esforco! > 0 ? '${item.esforco}' : null;
    final hasObservacoes = item.observacoes != null && item.observacoes!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.screenHorizontalPadding),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rail (Industrial Neutral Stripe)
            Container(
              width: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SpacingTokens.xs),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título da Seção
                  Text(
                    'FEEDBACK DO ALUNO',
                    style: AppTheme.sectionHeader,
                  ),
                  const SizedBox(height: 16),

                  // Observações
                  if (hasObservacoes) ...[
                    Text(
                      item.observacoes!,
                      style: TextStyle(
                        color: AppColors.labelPrimary,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],

                  if (effortVal != null) ...[
                    if (hasObservacoes) ...[
                      const SizedBox(height: 16),
                      Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                      const SizedBox(height: 16),
                    ],

                    // Métrica de Intensidade
                    Row(
                      children: [
                        _buildIntensityTag('PERCEPÇÃO DE ESFORÇO'),
                        const Spacer(),
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
                              '/ 10 RPE',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.2),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensityTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(SpacingTokens.xs),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.primary.withValues(alpha: 0.7),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildExercisesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.screenHorizontalPadding),
          child: Text(
            'DESEMPENHO POR EXERCÍCIO',
            style: AppTheme.sectionHeader,
          ),
        ),
        const SizedBox(height: SpacingTokens.xxl),
        ...item.exercicios.map((ex) => _ExerciseListItem(exercicio: ex)),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool showSeparator;

  const _StatItem({
    required this.label,
    required this.value,
    this.showSeparator = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTheme.title1.copyWith(
                  fontSize: 24,
                  color: Colors.white,
                  height: 1.0,
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
        ),
        if (showSeparator)
          Container(
            height: 24,
            width: 1,
            color: Colors.white10,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withValues(alpha: 0.12),
      margin: const EdgeInsets.symmetric(horizontal: 12),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho do Exercício (Minimalista)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.screenHorizontalPadding),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
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
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.fitness_center, color: Colors.white10, size: 14),
                      );
                    }
                    return const Icon(Icons.fitness_center, color: Colors.white10, size: 14);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nome.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: SpacingTokens.lg),

        // Feed de Performance (Sem Cards)
        Stack(
          children: [
            // Linha Vertical (Régua/Timeline)
            Positioned(
              left: SpacingTokens.screenHorizontalPadding + 15, // Centralizado sob o ícone (32px / 2 = 16, -1 do stroke)
              top: 0,
              bottom: 20, // Termina um pouco antes do final do último item
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),

            Column(
              children: series.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                final peso = s['pesoRealizado']?.toString() ?? '0';
                final reps = s['repsRealizadas']?.toString() ?? '0';
                final alvo = s['alvo']?.toString() ?? '-';
                final tipo = s['tipo']?.toString().toLowerCase() ?? 'trabalho';
                final isWarmup = tipo == 'aquecimento';

                return Padding(
                  padding: const EdgeInsets.only(
                    left: SpacingTokens.screenHorizontalPadding + 44, // Alinhado com o texto do nome
                    right: SpacingTokens.screenHorizontalPadding,
                    bottom: 12,
                  ),
                  child: Row(
                    children: [
                      // Index da Série
                      SizedBox(
                        width: 28,
                        child: Text(
                          isWarmup ? 'A${i + 1}' : '${(i + 1).toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: isWarmup
                                ? Colors.amber.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.15),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Separador Industrial
                      Text(
                        '—',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.05)),
                      ),

                      const SizedBox(width: 16),

                      // Peso
                      Text(
                        '${peso}kg',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Operador
                      Text(
                        '×',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.1),
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Repetições
                      Text(
                        reps,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const Spacer(),

                      // Meta/Alvo
                      if (alvo != '-')
                        Text(
                          '[ALVO: $alvo]',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.1),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        const SizedBox(height: SpacingTokens.sectionGap),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  _BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);

    // Borda sutil no tail para alinhar com o corpo
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final borderPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}