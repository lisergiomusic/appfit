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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.premiumGradient,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: 60, 
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildStatsRow(),
              const SizedBox(height: 32),
              if (item.observacoes != null && item.observacoes!.isNotEmpty)
                _buildNotesSection(),
              const SizedBox(height: 32),
              _buildExercisesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final dateStr = DateFormat("dd MMM yyyy", 'pt_BR').format(item.dataHora).toUpperCase();
    final timeStr = DateFormat("HH:mm").format(item.dataHora);
    final sessionName = item.sessaoNome.isEmpty ? 'TREINO CONCLUÍDO' : item.sessaoNome.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.screenHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$dateStr • $timeStr',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sessionName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 24),
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
                AppAvatar(name: item.alunoNome, photoUrl: item.alunoPhotoUrl, radius: 20, showBorder: false),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.alunoNome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Ver perfil do aluno',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.3)),
              ],
            ),
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
    final effortStr = item.esforco != null && item.esforco! > 0 ? '${item.esforco}' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.screenHorizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _StatItem(value: '${item.duracaoMinutos}', label: 'MINUTOS'),
          _StatDivider(),
          _StatItem(value: '$sets', label: 'SÉRIES'),
          _StatDivider(),
          _StatItem(value: volStr, label: 'VOLUME ($volUnit)'),
          _StatDivider(),
          _StatItem(value: effortStr, label: 'ESFORÇO', valueColor: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.screenHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ANOTAÇÕES DO ALUNO',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.observacoes!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: SpacingTokens.screenHorizontalPadding),
          child: Text(
            'EXERCÍCIOS REALIZADOS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
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
        bottom: 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
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
                        errorWidget: (context, url, error) => const Icon(Icons.fitness_center, color: Colors.white24, size: 20),
                      );
                    }
                    return const Icon(Icons.fitness_center, color: Colors.white24, size: 20);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          if (series.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...series.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 64),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${s['pesoRealizado'] ?? '0'}kg × ${s['repsRealizadas'] ?? '0'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (s['alvo'] != null)
                      Text(
                        s['alvo'].toString(),
                        style: const TextStyle(
                          color: Colors.white30,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}