import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'models/exercicio_model.dart';

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

  TextStyle _microLabelStyle() {
    return const TextStyle(
      color: Color.fromARGB(150, 255, 255, 255),
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.25,
    );
  }

  Widget _buildMinimalInput({
    required String fieldKey,
    required String initialValue,
    required TextAlign textAlign,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      key: ValueKey(fieldKey),
      initialValue: initialValue,
      onChanged: onChanged,
      textAlign: textAlign,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w400,
      ),
      cursorColor: AppTheme.primary,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        fillColor: Colors.transparent, // Ensure no background color
        filled: false, // Disable filling
      ),
    );
  }

  Widget _buildSerieRow(
    MapEntry<int, SerieItem> entry,
    int visualNumber,
    bool showDivider,
  ) {
    final realIndex = entry.key;
    final serie = entry.value;

    return GestureDetector(
      onLongPress: () => _removerSerie(realIndex),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 28,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '$visualNumber',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('REPS', style: _microLabelStyle()),
                            _buildMinimalInput(
                              fieldKey: 'alvo_${realIndex}_${serie.alvo}',
                              initialValue: serie.alvo,
                              textAlign: TextAlign.center,
                              onChanged: (val) {
                                serie.alvo = val;
                                widget.onChanged();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('CARGA', style: _microLabelStyle()),
                            _buildMinimalInput(
                              fieldKey: 'carga_${realIndex}_${serie.carga}',
                              initialValue: serie.carga,
                              textAlign: TextAlign.center,
                              onChanged: (val) {
                                serie.carga = val;
                                widget.onChanged();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('DESCANSO', style: _microLabelStyle()),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Icon(
                                  Icons.timer,
                                  color: AppTheme.primary,
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 44,
                                  child: _buildMinimalInput(
                                    fieldKey:
                                        'descanso_${realIndex}_${serie.descanso}',
                                    initialValue: serie.descanso,
                                    textAlign: TextAlign.right,
                                    onChanged: (val) {
                                      serie.descanso = val;
                                      widget.onChanged();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 0.5,
              color: Colors.white.withAlpha(20),
            ),
        ],
      ),
    );
  }

  Widget _buildSeriesSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<MapEntry<int, SerieItem>> entries,
  }) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 17),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withAlpha(150),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...entries.asMap().entries.map((mapped) {
          final isLast = mapped.key == entries.length - 1;
          return _buildSerieRow(mapped.value, mapped.key + 1, !isLast);
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final warmupEntries = ex.series
        .asMap()
        .entries
        .where((e) => e.value.tipo == TipoSerie.aquecimento)
        .toList();
    final workEntries = ex.series
        .asMap()
        .entries
        .where((e) => e.value.tipo != TipoSerie.aquecimento)
        .toList();
    final muscleGroupsText = ex.grupoMuscular.trim().isEmpty
        ? 'EXERCÍCIO'
        : ex.grupoMuscular
              .toUpperCase()
              .replaceAll(RegExp(r'\s*,\s*'), ' • ')
              .replaceAll(RegExp(r'\s+/\s+'), ' • ');
    final instructionsText = ex.observacao.trim().isEmpty
        ? 'Foco na profundidade e controle. Mantenha o tronco ereto e os joelhos alinhados com os pés. Empurre com os calcanhares.'
        : ex.observacao;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: 44,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leadingWidth: 108,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.chevron_left,
            color: AppTheme.primary,
            size: 18,
          ),
          label: const Text(
            'Voltar',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primary,
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.only(left: 4, right: 8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text(
              'Concluir',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ex.nome,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.14,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                muscleGroupsText,
                style: TextStyle(
                  color: Colors.white.withAlpha(150),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.25,
                ),
              ),
              const SizedBox(height: 36),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Abrindo vídeo explicativo de ${ex.nome}...',
                      ),
                      backgroundColor: AppTheme.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withAlpha(20),
                        width: 0.5,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(
                          ex.imagemUrl ??
                              'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&h=280&fit=crop',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(80),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withAlpha(30),
                                width: 0.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'INSTRUÇÕES',
                style: TextStyle(
                  color: Colors.white.withAlpha(150),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                instructionsText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 32),
              _buildSeriesSection(
                icon: Icons.local_fire_department,
                iconColor: const Color(0xFFFFB300),
                title: 'AQUECIMENTO',
                entries: warmupEntries,
              ),
              const SizedBox(height: 12),
              _buildSeriesSection(
                icon: Icons.label,
                iconColor: Colors.white,
                title: 'SÉRIES DE TRABALHO',
                entries: workEntries,
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _adicionarSerie,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                ),
                icon: const Icon(Icons.add, size: 24),
                label: const Text(
                  'ADICIONAR SÉRIE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
