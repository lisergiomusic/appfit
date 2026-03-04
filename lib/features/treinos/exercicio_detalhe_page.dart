import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'models/exercicio_model.dart';
import 'widgets/modern_input_widget.dart';

class ExercicioDetalhePage extends StatefulWidget {
  final ExercicioItem exercicio;
  final VoidCallback onChanged;

  const ExercicioDetalhePage({
    super.key,
    required this.exercicio,
    required this.onChanged,
  });

  @override
  State<ExercicioDetalhePage> createState() => _ExercicioDetalhePageState();
}

class _ExercicioDetalhePageState extends State<ExercicioDetalhePage> {
  late ExercicioItem ex;

  @override
  void initState() {
    super.initState();
    ex = widget.exercicio;
  }

  void _removerSerie(int realIndex) {
    setState(() {
      ex.series.removeAt(realIndex);
      widget.onChanged();
    });
  }

  Future<void> _adicionarSerie() async {
    final TipoSerie? tipoEscolhido = await showModalBottomSheet<TipoSerie>(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const Text(
                  'Adicionar Nova Série',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildModalOption(
                        title: 'Série de Aquecimento',
                        icon: Icons.whatshot,
                        color: Colors.amber,
                        onTap: () =>
                            Navigator.pop(context, TipoSerie.aquecimento),
                        showDivider: true,
                        subtitle: 'Preparação leve e articular.',
                      ),
                      _buildModalOption(
                        title: 'Feeder Set',
                        icon: Icons.flash_on,
                        color: Colors.blueAccent,
                        onTap: () => Navigator.pop(context, TipoSerie.feeder),
                        showDivider: true,
                        subtitle: 'Aproximação sem gerar fadiga.',
                      ),
                      _buildModalOption(
                        title: 'Série de Trabalho',
                        icon: Icons.tag,
                        color: Colors.white,
                        onTap: () => Navigator.pop(context, TipoSerie.trabalho),
                        showDivider: false,
                        subtitle: 'Série principal até a falha.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );

    if (tipoEscolhido != null) {
      setState(() {
        String alvoToClone = '10';
        String cargaToClone = '-';
        String descansoToClone = '60s';

        if (ex.series.isNotEmpty) {
          final ultimaSerie = ex.series.lastWhere(
            (s) => s.tipo == tipoEscolhido,
            orElse: () => ex.series.last,
          );
          alvoToClone = ultimaSerie.alvo;
          cargaToClone = ultimaSerie.carga;
          descansoToClone = ultimaSerie.descanso;
        }

        ex.series.add(
          SerieItem(
            tipo: tipoEscolhido,
            alvo: alvoToClone,
            carga: cargaToClone,
            descanso: descansoToClone,
          ),
        );
        widget.onChanged();
      });
    }
  }

  Widget _buildModalOption({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool showDivider,
    required String subtitle,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.textSecondary.withAlpha(160),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.black45,
            indent: 0,
          ),
      ],
    );
  }

  void _editarObservacao(BuildContext context) {
    final controller = TextEditingController(text: ex.observacao);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const Text(
                'Nota do Exercício',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 4,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Ex: Focar na contração de pico...',
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondary.withAlpha(120),
                      fontSize: 15,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    ex.observacao = controller.text.trim();
                    widget.onChanged();
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Salvar Nota',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _confirmarRemocaoNota(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Remover nota?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        content: const Text(
          'A anotação será removida permanentemente.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                ex.observacao = '';
                widget.onChanged();
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Remover',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _sectionHeaderStyle() {
    return TextStyle(
      color: AppTheme.textSecondary.withAlpha(120),
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    );
  }

  Widget _buildBadgeTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerieRow(int realIndex, SerieItem serie, int visualNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 36,
            child: Center(
              child: Text(
                '$visualNumber',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ModernInputWidget(
              initialValue: serie.alvo,
              onChanged: (val) {
                serie.alvo = val;
                widget.onChanged();
              },
              autoSuffix: ex.tipoAlvo == 'Tempo' ? 's' : null,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ModernInputWidget(
              initialValue: serie.carga,
              onChanged: (val) {
                serie.carga = val;
                widget.onChanged();
              },
              autoSuffix: 'kg',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ModernInputWidget(
              initialValue: serie.descanso,
              onChanged: (val) {
                serie.descanso = val;
                widget.onChanged();
              },
              autoSuffix: 's',
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            height: 36,
            child: Center(
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                color: AppTheme.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                position: PopupMenuPosition.under,
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppTheme.textSecondary.withAlpha(120),
                  size: 20,
                ),
                onSelected: (value) {
                  if (value == 'duplicate') {
                    setState(() {
                      final novaSerie = SerieItem(
                        tipo: serie.tipo,
                        alvo: serie.alvo,
                        carga: serie.carga,
                        descanso: serie.descanso,
                      );
                      ex.series.insert(realIndex + 1, novaSerie);
                      widget.onChanged();
                    });
                  } else if (value == 'delete') {
                    _removerSerie(realIndex);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          color: AppTheme.textSecondary.withAlpha(200),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Duplicar série',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Excluir série',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aquecimentoSeries = ex.series
        .where((s) => s.tipo == TipoSerie.aquecimento)
        .toList();
    final feederSeries = ex.series
        .where((s) => s.tipo == TipoSerie.feeder)
        .toList();
    final trabalhoSeries = ex.series
        .where((s) => s.tipo == TipoSerie.trabalho)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 16),
              const Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                'Voltar',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                ex.nome,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Abrindo vídeo explicativo de ${ex.nome}...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      backgroundColor: AppTheme.primary,
                      duration: const Duration(milliseconds: 1500),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(
                        ex.imagemUrl ??
                            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&h=280&fit=crop',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha(0),
                              Colors.black.withAlpha(80),
                            ],
                          ),
                        ),
                      ),
                      ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withAlpha(60),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.play_circle_fill,
                              color: Colors.white.withAlpha(200),
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (ex.series.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        'SÉRIE',
                        style: _sectionHeaderStyle(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (ex.tipoAlvo == 'Reps') {
                              ex.tipoAlvo = 'Tempo';
                              for (var serie in ex.series) {
                                if (RegExp(
                                  r'\d$',
                                ).hasMatch(serie.alvo.trim())) {
                                  serie.alvo = '${serie.alvo.trim()}s';
                                }
                              }
                            } else {
                              ex.tipoAlvo = 'Reps';
                              for (var serie in ex.series) {
                                serie.alvo = serie.alvo.trim().replaceAll(
                                  RegExp(r's$'),
                                  '',
                                );
                              }
                            }
                            widget.onChanged();
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ex.tipoAlvo.toUpperCase(),
                              style: _sectionHeaderStyle(),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.swap_vert,
                              color: AppTheme.textSecondary.withAlpha(150),
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: Text('CARGA', style: _sectionHeaderStyle()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: Text('PAUSA', style: _sectionHeaderStyle()),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            if (aquecimentoSeries.isNotEmpty) ...[
              _buildBadgeTitle('Aquecimento', Colors.amber),
              ...ex.series
                  .asMap()
                  .entries
                  .where((e) => e.value.tipo == TipoSerie.aquecimento)
                  .map(
                    (entry) => _buildSerieRow(
                      entry.key,
                      entry.value,
                      aquecimentoSeries.indexOf(entry.value) + 1,
                    ),
                  ),
            ],
            if (feederSeries.isNotEmpty) ...[
              _buildBadgeTitle('Feeder Sets', Colors.blueAccent),
              ...ex.series
                  .asMap()
                  .entries
                  .where((e) => e.value.tipo == TipoSerie.feeder)
                  .map(
                    (entry) => _buildSerieRow(
                      entry.key,
                      entry.value,
                      feederSeries.indexOf(entry.value) + 1,
                    ),
                  ),
            ],
            if (trabalhoSeries.isNotEmpty) ...[
              _buildBadgeTitle('Trabalho', Colors.white),
              ...ex.series
                  .asMap()
                  .entries
                  .where((e) => e.value.tipo == TipoSerie.trabalho)
                  .map(
                    (entry) => _buildSerieRow(
                      entry.key,
                      entry.value,
                      trabalhoSeries.indexOf(entry.value) + 1,
                    ),
                  ),
            ],
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: () => _editarObservacao(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withAlpha(15),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            ex.observacao.isEmpty
                                ? Icons.edit_note
                                : Icons.sticky_note_2,
                            color: ex.observacao.isEmpty
                                ? Colors.white
                                : AppTheme.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ex.observacao.isEmpty
                                  ? 'Adicionar nota'
                                  : ex.observacao,
                              style: TextStyle(
                                color: ex.observacao.isEmpty
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                                fontSize: 15,
                                fontWeight: ex.observacao.isEmpty
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                height: 1.3,
                              ),
                              maxLines: ex.observacao.isEmpty ? 1 : 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (ex.observacao.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => _confirmarRemocaoNota(context),
                              child: Icon(
                                Icons.close,
                                color: AppTheme.textSecondary.withAlpha(150),
                                size: 18,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Colors.white.withAlpha(20),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _adicionarSerie,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withAlpha(15),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_circle,
                            color: AppTheme.success,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Adicionar Série',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
