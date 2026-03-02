import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'exercicios_library_page.dart';

// --- MODELOS DE DADOS REFINADOS ---
enum TipoSerie { aquecimento, feeder, trabalho }

class SerieItem {
  TipoSerie tipo;
  String alvo;
  String carga;
  String descanso;

  SerieItem({
    this.tipo = TipoSerie.trabalho,
    this.alvo = '10',
    this.carga = '-',
    this.descanso = '60s',
  });
}

class ExercicioItem {
  String nome;
  String grupoMuscular;
  String observacao;
  String tipoAlvo;
  String? imagemUrl;
  List<SerieItem> series;

  ExercicioItem({
    required this.nome,
    this.grupoMuscular = 'Peito',
    this.observacao = '',
    this.tipoAlvo = 'Reps',
    this.imagemUrl,
    required this.series,
  });
}

class ConfigurarExerciciosPage extends StatefulWidget {
  final String nomeTreino;
  final List<ExercicioItem>
  exercicios; // <-- AGORA RECEBE A LISTA DA SESSÃO PAI

  const ConfigurarExerciciosPage({
    super.key,
    required this.nomeTreino,
    required this.exercicios, // <-- PARÂMETRO OBRIGATÓRIO
  });

  @override
  State<ConfigurarExerciciosPage> createState() =>
      _ConfigurarExerciciosPageState();
}

class _ConfigurarExerciciosPageState extends State<ConfigurarExerciciosPage> {
  // Controle do Accordion: Qual exercício está aberto no momento?
  int? _expandedExIndex; // null = todos colapsados

  // O MOCK FOI REMOVIDO DAQUI. AGORA USAMOS widget.exercicios EM TUDO!

  void _removerExercicio(int exIndex) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remover Exercício?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Tem certeza que deseja remover este exercício do treino?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget.exercicios.removeAt(exIndex); // Usa a lista do widget
                if (_expandedExIndex == exIndex) {
                  _expandedExIndex = null;
                } else if (_expandedExIndex != null &&
                    _expandedExIndex! > exIndex) {
                  _expandedExIndex = _expandedExIndex! - 1;
                }
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Remover',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editarObservacao(BuildContext context, int exIndex) {
    final controller = TextEditingController(
      text: widget.exercicios[exIndex].observacao,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.notes, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Notas do Exercício',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ex: Focar na contração de pico...',
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary.withAlpha(128),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    widget.exercicios[exIndex].observacao = controller.text
                        .trim();
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Salvar Nota',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _adicionarSerie(int exIndex) async {
    final TipoSerie? tipoEscolhido = await showModalBottomSheet<TipoSerie>(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Adicionar Nova Série',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withAlpha(50)),
                    ),
                    child: const Center(
                      child: Icon(Icons.whatshot, color: Colors.amber),
                    ),
                  ),
                  title: const Text(
                    'Série de Aquecimento',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Preparação com carga reduzida',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, TipoSerie.aquecimento),
                ),
                const SizedBox(height: 8),

                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blueAccent.withAlpha(50),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.flash_on, color: Colors.blueAccent),
                    ),
                  ),
                  title: const Text(
                    'Feeder Set',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Aproximação de carga sem gerar fadiga',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, TipoSerie.feeder),
                ),
                const SizedBox(height: 8),

                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  title: const Text(
                    'Série de Trabalho',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Série principal para o volume do treino',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, TipoSerie.trabalho),
                ),
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

        if (widget.exercicios[exIndex].series.isNotEmpty) {
          final ultimaSerie = widget.exercicios[exIndex].series.lastWhere(
            (s) => s.tipo == tipoEscolhido,
            orElse: () => widget.exercicios[exIndex].series.last,
          );
          alvoToClone = ultimaSerie.alvo;
          cargaToClone = ultimaSerie.carga;
          descansoToClone = ultimaSerie.descanso;
        }

        widget.exercicios[exIndex].series.add(
          SerieItem(
            tipo: tipoEscolhido,
            alvo: alvoToClone,
            carga: cargaToClone,
            descanso: descansoToClone,
          ),
        );
      });
    }
  }

  void _removerSerie(int exIndex, int realIndex) {
    setState(() {
      widget.exercicios[exIndex].series.removeAt(realIndex);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = widget.exercicios.removeAt(oldIndex);
      widget.exercicios.insert(newIndex, item);

      // Ajusta o índice expandido para acompanhar o item movido
      if (_expandedExIndex != null) {
        if (_expandedExIndex == oldIndex) {
          _expandedExIndex = newIndex;
        } else if (oldIndex < _expandedExIndex! &&
            newIndex >= _expandedExIndex!) {
          _expandedExIndex = _expandedExIndex! - 1;
        } else if (oldIndex > _expandedExIndex! &&
            newIndex <= _expandedExIndex!) {
          _expandedExIndex = _expandedExIndex! + 1;
        }
      }
    });
  }

  Future<void> _openLibrary() async {
    final String? nome = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ExerciciosLibraryPage()),
    );

    if (nome != null && nome.isNotEmpty) {
      setState(() {
        widget.exercicios.add(ExercicioItem(nome: nome, series: []));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.nomeTreino,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.primary),
            tooltip: 'Finalizar treino',
            onPressed: () {
              Navigator.pop(
                context,
              ); // Os dados já estão salvos na lista do pai
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.exercicios.isEmpty
                ? _buildEmptyState()
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: widget.exercicios.length,
                    onReorder: _onReorder,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (BuildContext context, Widget? child) {
                          final double animValue = Curves.easeInOut.transform(
                            animation.value,
                          );
                          final double elevation = lerpDouble(0, 6, animValue)!;
                          return Material(
                            elevation: elevation,
                            color: Colors.transparent,
                            shadowColor: Colors.black.withAlpha(100),
                            borderRadius: BorderRadius.circular(16),
                            child: Transform.scale(scale: 1.02, child: child),
                          );
                        },
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) => _buildExercicioCard(index),
                  ),
          ),
          if (widget.exercicios.isNotEmpty) _buildBottomBar(),
        ],
      ),
      floatingActionButton: _buildFloatingAddButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFloatingAddButton() {
    return FloatingActionButton(
      onPressed: _openLibrary,
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primary.withAlpha(50), width: 1),
      ),
      heroTag: 'fab_add_exercicio',
      child: const Icon(Icons.add, size: 28),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: Colors.white.withAlpha(26),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum exercício adicionado',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openLibrary,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Adicionar exercício'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercicioCard(int exIndex) {
    final ex = widget.exercicios[exIndex];
    final bool isExpanded = _expandedExIndex == exIndex;

    final aquecimentoSeries = ex.series
        .asMap()
        .entries
        .where((e) => e.value.tipo == TipoSerie.aquecimento)
        .toList();
    final feederSeries = ex.series
        .asMap()
        .entries
        .where((e) => e.value.tipo == TipoSerie.feeder)
        .toList();
    final trabalhoSeries = ex.series
        .asMap()
        .entries
        .where((e) => e.value.tipo == TipoSerie.trabalho)
        .toList();

    return Container(
      key: ObjectKey(ex),
      margin: const EdgeInsets.only(bottom: 8), // Mais compacto
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(10)),
        boxShadow: [
          if (isExpanded)
            BoxShadow(
              color: Colors.black.withAlpha(40), // softer shadow when expanded
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =====================================
          // 1. CABEÇALHO ANIMADO (HEADER)
          // =====================================
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                FocusScope.of(context).unfocus();
                setState(() {
                  _expandedExIndex = isExpanded ? null : exIndex;
                });
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: isExpanded
                    ? _buildExpandedHeader(ex, exIndex)
                    : _buildCollapsedHeader(ex, exIndex), // Versão Intuitiva
              ),
            ),
          ),

          // =====================================
          // 2. CORPO DO CARTÃO (ACORDEÃO)
          // =====================================
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topCenter,
            child: !isExpanded
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // TABELA DE SÉRIES (CABEÇALHO)
                      if (ex.series.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 36,
                                child: Text(
                                  'Série',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Center(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (ex.tipoAlvo == 'Reps') {
                                          ex.tipoAlvo = 'Tempo';
                                          for (var serie in ex.series) {
                                            String val = serie.alvo.trim();
                                            if (RegExp(r'\d$').hasMatch(val)) {
                                              serie.alvo = '${val}s';
                                            }
                                          }
                                        } else {
                                          ex.tipoAlvo = 'Reps';
                                          for (var serie in ex.series) {
                                            serie.alvo = serie.alvo
                                                .trim()
                                                .replaceAll(RegExp(r's$'), '');
                                          }
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            ex.tipoAlvo,
                                            style: TextStyle(
                                              color: ex.tipoAlvo == 'Reps'
                                                  ? AppTheme.textSecondary
                                                  : AppTheme.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Icon(
                                            Icons.swap_vert,
                                            color: ex.tipoAlvo == 'Reps'
                                                ? AppTheme.textSecondary
                                                : AppTheme.primary,
                                            size: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Carga',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Pausa',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 40),
                            ],
                          ),
                        ),

                      // SUBDIVISÕES
                      if (aquecimentoSeries.isNotEmpty) ...[
                        _buildSectionTitle('Aquecimento', Colors.amber),
                        ...aquecimentoSeries.asMap().entries.map(
                          (entry) => _buildSerieRow(
                            exIndex,
                            entry.value.key,
                            entry.value.value,
                            entry.key + 1,
                            Colors.amber,
                          ),
                        ),
                      ],
                      if (feederSeries.isNotEmpty) ...[
                        _buildSectionTitle('Feeder Sets', Colors.blueAccent),
                        ...feederSeries.asMap().entries.map(
                          (entry) => _buildSerieRow(
                            exIndex,
                            entry.value.key,
                            entry.value.value,
                            entry.key + 1,
                            Colors.blueAccent,
                          ),
                        ),
                      ],
                      if (trabalhoSeries.isNotEmpty) ...[
                        _buildSectionTitle(
                          'Séries de Trabalho',
                          AppTheme.textSecondary,
                        ),
                        ...trabalhoSeries.asMap().entries.map(
                          (entry) => _buildSerieRow(
                            exIndex,
                            entry.value.key,
                            entry.value.value,
                            entry.key + 1,
                            Colors.white,
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),

                      // CAMPO DE OBSERVAÇÃO movido para baixo das séries
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: InkWell(
                          onTap: () => _editarObservacao(context, exIndex),
                          borderRadius: BorderRadius.circular(8),
                          child: ex.observacao.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.add_comment_outlined,
                                        color: AppTheme.textSecondary.withAlpha(
                                          150,
                                        ),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Adicionar nota...',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary
                                              .withAlpha(150),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border(
                                      left: BorderSide(
                                        color: AppTheme.primary.withAlpha(150),
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ex.observacao,
                                          style: TextStyle(
                                            color: AppTheme.textSecondary
                                                .withAlpha(220),
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.edit_outlined,
                                        color: AppTheme.textSecondary.withAlpha(
                                          100,
                                        ),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),

                      // BOTÃO ADICIONAR SÉRIE
                      TextButton(
                        onPressed: () => _adicionarSerie(exIndex),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: AppTheme.primary, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Adicionar Série',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET DO CABEÇALHO EXPANDIDO (Rico em opções) ---
  Widget _buildExpandedHeader(ExercicioItem ex, int exIndex) {
    return Padding(
      key: const ValueKey('expanded_header'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LINHA 1: Título e Ações
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        ex.nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_horiz,
                        color: AppTheme.textSecondary,
                        size: 22,
                      ),
                      color: AppTheme.surfaceLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      position: PopupMenuPosition.under,
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'substituir') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Em breve: Abrir biblioteca'),
                            ),
                          );
                        } else if (value == 'remover') {
                          _removerExercicio(exIndex);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'substituir',
                          child: Row(
                            children: [
                              Icon(
                                Icons.swap_horiz,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Substituir exercício',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'remover',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Remover',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: 0.5,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppTheme.textSecondary.withAlpha(150),
                        size: 24,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // LINHA 2: Thumbnail e Info Complementar
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        image: ex.imagemUrl != null
                            ? DecorationImage(
                                image: NetworkImage(ex.imagemUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        border: Border.all(
                          color: Colors.white.withAlpha(10),
                          width: 1,
                        ),
                      ),
                      child: ex.imagemUrl == null
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  color: AppTheme.textSecondary.withAlpha(80),
                                  size: 28,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(60),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                const Icon(
                                  Icons.play_circle_fill,
                                  color: AppTheme.primary,
                                  size: 32,
                                ),
                              ],
                            )
                          : const SizedBox(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GRUPO MUSCULAR',
                            style: TextStyle(
                              color: AppTheme.textSecondary.withAlpha(150),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ex.grupoMuscular,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET DO CABEÇALHO COLAPSADO ---
  Widget _buildCollapsedHeader(ExercicioItem ex, int index) {
    return Padding(
      key: const ValueKey('collapsed_header'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Icon(
              Icons.drag_indicator,
              color: AppTheme.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // COLUNA COM NOME E SÉRIES
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
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${ex.series.length} ${ex.series.length == 1 ? 'série' : 'séries'} • ${ex.grupoMuscular.split('•').first.trim()}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.keyboard_arrow_down,
            color: AppTheme.textSecondary.withAlpha(150),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.subdirectory_arrow_right,
            size: 14,
            color: color.withAlpha(200),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color.withAlpha(200),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerieRow(
    int exIndex,
    int realIndex,
    SerieItem serie,
    int visualNumber,
    Color themeColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withAlpha(100),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$visualNumber',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: _buildCleanInput(
              serie.alvo,
              (val) => serie.alvo = val,
              autoSuffix: widget.exercicios[exIndex].tipoAlvo == 'Tempo'
                  ? 's'
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCleanInput(
              serie.carga,
              (val) => serie.carga = val,
              autoSuffix: 'kg',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCleanInput(
              serie.descanso,
              (val) => serie.descanso = val,
              autoSuffix: 's',
            ),
          ),

          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _removerSerie(exIndex, realIndex),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                Icons.close,
                color: AppTheme.textSecondary.withAlpha(150),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanInput(
    String initialValue,
    ValueChanged<String> onChanged, {
    String? autoSuffix,
  }) {
    return _CleanInputWidget(
      initialValue: initialValue,
      onChanged: onChanged,
      autoSuffix: autoSuffix,
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white.withAlpha(13))),
      ),
      child: ElevatedButton.icon(
        onPressed: _openLibrary,
        icon: const Icon(Icons.add),
        label: const Text(
          'Adicionar Exercício',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET SÊNIOR PARA CONTROLE DE ESTADO DO INPUT
// ==========================================
class _CleanInputWidget extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? autoSuffix;

  const _CleanInputWidget({
    required this.initialValue,
    required this.onChanged,
    this.autoSuffix,
  });

  @override
  State<_CleanInputWidget> createState() => _CleanInputWidgetState();
}

class _CleanInputWidgetState extends State<_CleanInputWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && widget.autoSuffix != null) {
      final text = _controller.text.trim();
      if (RegExp(r'\d$').hasMatch(text)) {
        final newText = '$text${widget.autoSuffix}';
        setState(() => _controller.text = newText);
        widget.onChanged(newText);
      }
    }
  }

  @override
  void didUpdateWidget(covariant _CleanInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      if (!_focusNode.hasFocus) _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 9),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
