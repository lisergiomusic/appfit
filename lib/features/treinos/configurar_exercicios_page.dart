import 'dart:ui' as ui; // Necessário para o ImageFilter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isAddFabPressed = false;
  late TextEditingController _nomeTreinoController;
  bool _isEditingTitle = false;
  late FocusNode _titleFocusNode;

  Color get _darkPrimary {
    final hsl = HSLColor.fromColor(AppTheme.primary);
    return hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();
  }

  double _fabProtectionSpace(BuildContext context) {
    return 140 + MediaQuery.of(context).padding.bottom;
  }

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
    _titleFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _nomeTreinoController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _toggleEditTitle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEditingTitle = !_isEditingTitle;
      if (_isEditingTitle) {
        _titleFocusNode.requestFocus();
      } else {
        _titleFocusNode.unfocus();
        if (_nomeTreinoController.text.trim() != widget.nomeTreino) {
          _hasChanges = true;
        }
      }
    });
  }

  int get _totalSeries =>
      _exerciciosLocais.fold(0, (sum, ex) => sum + ex.series.length);

  List<String> get _gruposMuscularesUnicos {
    final grupos = _exerciciosLocais
        .map((ex) => ex.grupoMuscular)
        .where((g) => g.trim().isNotEmpty)
        .toSet()
        .toList();
    grupos.sort();
    return grupos;
  }

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

  // --- O NOVO GLASS FAB LARANJA (ORANGE TINTED GLASS) ---
  Widget _buildOrangeGlassFAB() {
    final glowShadows = _isAddFabPressed
        ? <BoxShadow>[
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.28),
              blurRadius: 22,
              spreadRadius: 0.9,
              offset: Offset.zero,
            ),
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.15),
              blurRadius: 34,
              spreadRadius: 1.5,
              offset: Offset.zero,
            ),
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.07),
              blurRadius: 48,
              spreadRadius: 2.1,
              offset: Offset.zero,
            ),
          ]
        : <BoxShadow>[
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.20),
              blurRadius: 16,
              spreadRadius: 0.5,
              offset: Offset.zero,
            ),
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.10),
              blurRadius: 28,
              spreadRadius: 1.1,
              offset: Offset.zero,
            ),
          ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        boxShadow: [...glowShadows],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 16.0,
            sigmaY: 16.0,
          ), // Blur nativo Apple
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.52),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary.withValues(alpha: 0.88),
                  AppTheme.primary.withValues(alpha: 0.78),
                  _darkPrimary.withValues(alpha: 0.94),
                ],
                stops: const [0.0, 0.32, 1.0],
              ),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: _darkPrimary.withValues(alpha: 0.7),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.18),
                  blurRadius: 1,
                  offset: const Offset(0, -0.5),
                ),
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openLibrary,
                onHighlightChanged: (isHighlighted) {
                  if (_isAddFabPressed != isHighlighted) {
                    setState(() => _isAddFabPressed = isHighlighted);
                  }
                },
                splashColor: Colors.white.withValues(alpha: 0.2),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(0),
                        child: Icon(
                          Icons.add_circle_outline_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Adicionar Exercício',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          _buildOrangeGlassFAB(), // Chamando o FAB Laranja de Vidro
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.background.withValues(alpha: 0.9),
            surfaceTintColor: Colors.transparent,
            pinned: true,
            expandedHeight: 140.0,
            leadingWidth: 100,
            leading: TextButton.icon(
              onPressed: _onBackPressed,
              icon: Icon(Icons.chevron_left, color: AppTheme.primary, size: 28),
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
                  background: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        bottom: 8,
                        right: 16,
                      ),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isCollapsed ? 0.0 : 1.0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _isEditingTitle
                                  ? TextField(
                                      controller: _nomeTreinoController,
                                      focusNode: _titleFocusNode,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 40,
                                        letterSpacing: -0.5,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      cursorColor: AppTheme.primary,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      onSubmitted: (_) => _toggleEditTitle(),
                                    )
                                  : GestureDetector(
                                      onTap: _toggleEditTitle,
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
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _toggleEditTitle,
                              child: Icon(
                                _isEditingTitle
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.edit_note,
                                color: _isEditingTitle
                                    ? AppTheme.primary
                                    : Colors.white.withValues(alpha: 0.2),
                                size: 36,
                              ),
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

          SliverOpacity(
            opacity: _isEditingTitle ? 0.3 : 1.0,
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 0, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_exerciciosLocais.length} ${_exerciciosLocais.length == 1 ? 'exercício prescrito' : 'exercícios prescritos'}',
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
                                  '$_totalSeries SÉRIE${_totalSeries == 1 ? '' : 'S'}',
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
                  if (_gruposMuscularesUnicos.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 0,
                        bottom: 16,
                      ),
                      child: SizedBox(
                        height: 30,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _gruposMuscularesUnicos.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                    ),
                  if (_exerciciosLocais.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 100,
                      ), // Empurra suavemente para o centro da tela
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(
                                  alpha: 0.05,
                                ), // Fundo circular escuro/translúcido
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons
                                      .assignment_outlined, // Ícone de prancheta
                                  size: 40,
                                  color: AppTheme.primary, // Laranja vibrante
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Nenhum exercício adicionado',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ),
                              child: Text(
                                'Comece a montar o treino do seu aluno\nadicionando o primeiro exercício abaixo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                  height:
                                      1.4, // Line-height elegante para leitura
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (_exerciciosLocais.isNotEmpty)
            SliverOpacity(
              opacity: _isEditingTitle ? 0.3 : 1.0,
              sliver: SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverReorderableList(
                  itemCount: _exerciciosLocais.length,
                  onReorder: _onReorder,
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      elevation: 0,
                      color: Colors.transparent,
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) => _buildExercicioCard(index),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: _fabProtectionSpace(context)),
          ),
        ],
      ),
    );
  }

  // CARD DE EXERCÍCIO ORIGINAL COM GLASSMorphism PREMIUM
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
          color: AppTheme
              .glassCard, // Supondo que você tenha AppTheme.glassCard (preto translúcido)
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.04),
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
                            height: 1.2,
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
}
