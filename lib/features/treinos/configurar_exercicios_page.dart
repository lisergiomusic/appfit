import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'exercicios_library_page.dart';
import 'exercicio_detalhe_page.dart';
import 'models/exercicio_model.dart';

class ConfigurarExerciciosPage extends StatefulWidget {
  final String nomeTreino;
  final List<ExercicioItem> exercicios;

  const ConfigurarExerciciosPage({
    super.key,
    required this.nomeTreino,
    required this.exercicios,
  });

  @override
  State<ConfigurarExerciciosPage> createState() =>
      _ConfigurarExerciciosPageState();
}

class _ConfigurarExerciciosPageState extends State<ConfigurarExerciciosPage> {
  late List<ExercicioItem> _exerciciosLocais;
  bool _hasChanges = false;
  late TextEditingController _nomeTreinoController;

  @override
  void initState() {
    super.initState();
    _exerciciosLocais = widget.exercicios.isNotEmpty
        ? widget.exercicios.map((ex) {
            return ExercicioItem(
              nome: ex.nome,
              grupoMuscular: ex.grupoMuscular,
              observacao: ex.observacao,
              tipoAlvo: ex.tipoAlvo,
              imagemUrl: ex.imagemUrl,
              series: ex.series
                  .map(
                    (s) => SerieItem(
                      tipo: s.tipo,
                      alvo: s.alvo,
                      carga: s.carga,
                      descanso: s.descanso,
                    ),
                  )
                  .toList(),
            );
          }).toList()
        : [];
    _nomeTreinoController = TextEditingController(text: widget.nomeTreino);
  }

  @override
  void dispose() {
    _nomeTreinoController.dispose();
    super.dispose();
  }

  int get _totalSeries =>
      _exerciciosLocais.fold(0, (sum, ex) => sum + ex.series.length);

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _exerciciosLocais.removeAt(oldIndex);
      _exerciciosLocais.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  Future<void> _openLibrary() async {
    final String? nome = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ExerciciosLibraryPage()),
    );

    if (nome != null && nome.isNotEmpty) {
      setState(() {
        _exerciciosLocais.add(ExercicioItem(nome: nome, series: []));
        _hasChanges = true;
      });
    }
  }

  void _concluirEdicao() {
    widget.exercicios.clear();
    widget.exercicios.addAll(_exerciciosLocais);
    Navigator.pop(context, _nomeTreinoController.text.trim());
  }

  Future<void> _onBackPressed() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }
    final sair = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Descartar alterações?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'As modificações nesta sessão não foram salvas.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.primary, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Descartar',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (sair == true) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // MAIN COM EFEITO APPLE RESTAURADO
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                backgroundColor: AppTheme.background.withOpacity(0.9),
                surfaceTintColor: Colors.transparent,
                pinned: true,
                expandedHeight: 140.0,
                leadingWidth: 100,
                leading: TextButton.icon(
                  onPressed: _onBackPressed,
                  icon: Icon(
                    Icons.chevron_left,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                  label: Text(
                    'Voltar',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: TextButton(
                      onPressed: _concluirEdicao,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Concluir',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double collapsedHeight =
                        MediaQuery.of(context).padding.top + kToolbarHeight;
                    final bool isCollapsed =
                        constraints.biggest.height <= collapsedHeight + 20;

                    return FlexibleSpaceBar(
                      centerTitle: true,
                      titlePadding: const EdgeInsets.only(bottom: 14),
                      // Título pequeno ao rolar
                      title: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isCollapsed ? 1.0 : 0.0,
                        child: Text(
                          _nomeTreinoController.text.isEmpty
                              ? widget.nomeTreino
                              : _nomeTreinoController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      // Título gigante à esquerda
                      background: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            bottom: 8,
                            right: 16,
                          ),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isCollapsed ? 0.0 : 1.0,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _nomeTreinoController.text.isEmpty
                                        ? widget.nomeTreino
                                        : _nomeTreinoController.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 40,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.edit_note,
                                  color: Colors.white.withOpacity(0.2),
                                  size: 36,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // O seu Row de exercícios e séries
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 0, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_exerciciosLocais.length} exercícios prescritos',
                              style: TextStyle(
                                color: AppTheme.textSecondary.withAlpha(180),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_totalSeries > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(15),
                                  borderRadius: BorderRadius.circular(12),
                                  // Removida a borda laranja
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'TOTAL DE SÉRIES: ',
                                      style: TextStyle(
                                        color: AppTheme.primary.withAlpha(200),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      '$_totalSeries SÉRIES',
                                      style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Os seus Pills com a ListView.separated
                      if (_gruposMuscularesUnicos.isNotEmpty)
                        SizedBox(
                          height: 30,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _gruposMuscularesUnicos.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final grupo = _gruposMuscularesUnicos[i];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(20),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(25),
                                    width: 0.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    grupo.toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(220),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      if (_exerciciosLocais.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: _buildEmptyState(),
                        ),
                    ],
                  ),
                ),
              ),

              if (_exerciciosLocais.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverReorderableList(
                    itemCount: _exerciciosLocais.length + 1,
                    onReorder: _onReorder,
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        elevation: 0,
                        color: Colors.transparent,
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      if (index == _exerciciosLocais.length) {
                        return Container(
                          key: const ValueKey('add_button'),
                          // AQUI ESTÁ A CORREÇÃO DE PADDING
                          margin: const EdgeInsets.only(top: 16, bottom: 120),
                          child: _buildAddExercicioButton(),
                        );
                      }
                      return _buildExercicioCard(index);
                    },
                  ),
                ),
            ],
          ),
          // FOOTER
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.background.withOpacity(0.92),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: ElevatedButton(
                  onPressed: _concluirEdicao,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.iosGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.18),
                  ),
                  child: const Text('Salvar Prescrição'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddExercicioButton() {
    return InkWell(
      onTap: _openLibrary,
      borderRadius: BorderRadius.circular(24),
      child: CustomPaint(
        painter: _DashedRectPainter(
          color: AppTheme.textSecondary.withAlpha(80),
          strokeWidth: 1.5,
          gap: 6,
          radius: 24,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primary.withAlpha(80)),
                ),
                child: const Icon(Icons.add, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'ADICIONAR EXERCÍCIO',
                style: TextStyle(
                  color: AppTheme.textSecondary.withAlpha(220),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 60,
            color: Colors.white.withAlpha(20),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum exercício',
            style: TextStyle(
              color: AppTheme.textSecondary.withAlpha(150),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: _buildAddExercicioButton(),
          ),
        ],
      ),
    );
  }

  // =======================================================
  // O SEU CARD ORIGINAL INTATO
  // =======================================================
  Widget _buildExercicioCard(int exIndex) {
    final ex = _exerciciosLocais[exIndex];

    return Dismissible(
      key: ValueKey('${ex.nome}_$exIndex'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.redAccent.withAlpha(200),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        setState(() {
          _exerciciosLocais.removeAt(exIndex);
          _hasChanges = true;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.glassCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withAlpha(8), width: 0.3),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExercicioDetalhePage(
                    exercicio: ex,
                    onChanged: () => setState(() => _hasChanges = true),
                  ),
                ),
              );
              setState(() {});
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ReorderableDragStartListener(
                    index: exIndex,
                    child: Icon(
                      Icons.drag_indicator,
                      color: Colors.grey[600],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.nome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${ex.series.length} SÉRIES',
                          style: TextStyle(
                            color: AppTheme.primary.withAlpha(220),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.chevron_right, color: Colors.grey[600], size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> get _gruposMuscularesUnicos {
    final grupos = _exerciciosLocais
        .map((ex) => ex.grupoMuscular)
        .where((g) => g.trim().isNotEmpty)
        .toSet()
        .toList();
    grupos.sort();
    return grupos;
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    Path path = Path()..addRRect(rrect);
    Path dashPath = Path();
    double distance = 0.0;
    for (ui.PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
      distance = 0.0;
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
