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
  int? _expandedExIndex;

  // --- CONTROLE DE ESTADO E RASCUNHO ---
  late List<ExercicioItem> _exerciciosLocais;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Fazemos um "Deep Clone" (cópia exata) para o rascunho.
    // Assim, se o utilizador descartar, a lista original do pai fica intocada!
    _exerciciosLocais = widget.exercicios.map((ex) {
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
    }).toList();
  }

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
                _exerciciosLocais.removeAt(exIndex);
                _hasChanges = true; // Marca como modificado

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
      text: _exerciciosLocais[exIndex].observacao,
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
              const Row(
                children: [
                  Icon(Icons.notes, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text(
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
                    _exerciciosLocais[exIndex].observacao = controller.text
                        .trim();
                    _hasChanges = true; // Marca como modificado
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Salvar Nota',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.withAlpha(50)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.whatshot,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  ),
                  title: const Text(
                    'Série de Aquecimento',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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
                const SizedBox(height: 4),

                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.blueAccent.withAlpha(50),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.flash_on,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                    ),
                  ),
                  title: const Text(
                    'Feeder Set',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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
                const SizedBox(height: 4),

                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  title: const Text(
                    'Série de Trabalho',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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

        if (_exerciciosLocais[exIndex].series.isNotEmpty) {
          final ultimaSerie = _exerciciosLocais[exIndex].series.lastWhere(
            (s) => s.tipo == tipoEscolhido,
            orElse: () => _exerciciosLocais[exIndex].series.last,
          );
          alvoToClone = ultimaSerie.alvo;
          cargaToClone = ultimaSerie.carga;
          descansoToClone = ultimaSerie.descanso;
        }

        _exerciciosLocais[exIndex].series.add(
          SerieItem(
            tipo: tipoEscolhido,
            alvo: alvoToClone,
            carga: cargaToClone,
            descanso: descansoToClone,
          ),
        );
        _hasChanges = true; // Marca como modificado
      });
    }
  }

  void _removerSerie(int exIndex, int realIndex) {
    setState(() {
      _exerciciosLocais[exIndex].series.removeAt(realIndex);
      _hasChanges = true; // Marca como modificado
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _exerciciosLocais.removeAt(oldIndex);
      _exerciciosLocais.insert(newIndex, item);
      _hasChanges = true; // Marca como modificado

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
        _exerciciosLocais.add(ExercicioItem(nome: nome, series: []));
        _expandedExIndex = _exerciciosLocais.length - 1;
        _hasChanges = true; // Marca como modificado
      });
    }
  }

  // --- FUNÇÃO PARA SALVAR DE FATO ---
  void _concluirEdicao() {
    // Apaga a lista original e injeta o rascunho
    widget.exercicios.clear();
    widget.exercicios.addAll(_exerciciosLocais);
    // Volta indicando que houve edição
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Se nada foi alterado, sai normalmente
        if (!_hasChanges) return true;

        // Se tem alteração, mostra o alerta!
        final sair = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Descartar alterações?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Você fez modificações nesta sessão. Se voltar agora sem clicar em "Concluir", todas elas serão perdidas.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), // Fica na tela
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, true), // Sai e perde as alterações
                child: const Text(
                  'Descartar',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
        return sair ?? false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: _concluirEdicao,
                icon: const Icon(
                  Icons.check,
                  color: AppTheme.primary,
                  size: 20,
                ),
                label: const Text(
                  'Concluir',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =====================================
            // HEADER ESTILO "APPLE HEALTH / NOTION"
            // =====================================
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nomeTreino,
                    style: const TextStyle(
                      fontSize: 32, // Fonte gigante editorial
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_exerciciosLocais.length} ${_exerciciosLocais.length == 1 ? 'exercício' : 'exercícios'} configurados',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // =====================================
            // LISTA DE EXERCÍCIOS (REORDERABLE)
            // =====================================
            Expanded(
              child: _exerciciosLocais.isEmpty
                  ? _buildEmptyState()
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount:
                          _exerciciosLocais.length +
                          1, // +1 para o botão adicionar
                      onReorder: (oldIndex, newIndex) {
                        if (oldIndex == _exerciciosLocais.length ||
                            newIndex > _exerciciosLocais.length)
                          return;
                        _onReorder(oldIndex, newIndex);
                      },
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          elevation: 8,
                          color: Colors.transparent,
                          shadowColor: Colors.black.withAlpha(150),
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        if (index == _exerciciosLocais.length) {
                          return Container(
                            key: const ValueKey('ghost_add_button'),
                            margin: const EdgeInsets.only(top: 8),
                            child: _buildGhostAddButton(),
                          );
                        }
                        return _buildExercicioCard(index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BOTÃO FANTASMA (MINIMALISTA) ---
  Widget _buildGhostAddButton() {
    return InkWell(
      onTap: _openLibrary,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withAlpha(50), width: 1.5),
          color: AppTheme.primary.withAlpha(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: AppTheme.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Adicionar Exercício',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
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
            size: 64,
            color: Colors.white.withAlpha(20),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sessão vazia.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openLibrary,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Explorar Biblioteca'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercicioCard(int exIndex) {
    final ex = _exerciciosLocais[exIndex];
    final bool isExpanded = _expandedExIndex == exIndex;

    final aquecimentoSeries = ex.series
        .where((s) => s.tipo == TipoSerie.aquecimento)
        .toList();
    final feederSeries = ex.series
        .where((s) => s.tipo == TipoSerie.feeder)
        .toList();
    final trabalhoSeries = ex.series
        .where((s) => s.tipo == TipoSerie.trabalho)
        .toList();

    return Container(
      key: ObjectKey(ex),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(10)),
        boxShadow: [
          if (isExpanded)
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. CABEÇALHO ANIMADO
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
                duration: const Duration(milliseconds: 200),
                child: isExpanded
                    ? _buildExpandedHeader(ex, exIndex)
                    : _buildCollapsedHeader(ex, exIndex),
              ),
            ),
          ),

          // 2. CORPO DO CARTÃO (ACORDEÃO)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topCenter,
            child: !isExpanded
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (ex.series.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 32,
                                child: Text(
                                  'Série',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
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
                                            if (RegExp(
                                              r'\d$',
                                            ).hasMatch(serie.alvo.trim()))
                                              serie.alvo =
                                                  '${serie.alvo.trim()}s';
                                          }
                                        } else {
                                          ex.tipoAlvo = 'Reps';
                                          for (var serie in ex.series) {
                                            serie.alvo = serie.alvo
                                                .trim()
                                                .replaceAll(RegExp(r's$'), '');
                                          }
                                        }
                                        _hasChanges =
                                            true; // Marca como modificado
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
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Icon(
                                            Icons.swap_vert,
                                            color: ex.tipoAlvo == 'Reps'
                                                ? AppTheme.textSecondary
                                                : AppTheme.primary,
                                            size: 12,
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
                                    fontSize: 11,
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
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 32),
                            ],
                          ),
                        ),

                      if (aquecimentoSeries.isNotEmpty) ...[
                        _buildSectionTitle('Aquecimento', Colors.amber),
                        ...ex.series
                            .asMap()
                            .entries
                            .where((e) => e.value.tipo == TipoSerie.aquecimento)
                            .map(
                              (entry) => _buildSerieRow(
                                exIndex,
                                entry.key,
                                entry.value,
                                aquecimentoSeries.indexOf(entry.value) + 1,
                              ),
                            ),
                      ],
                      if (feederSeries.isNotEmpty) ...[
                        _buildSectionTitle('Feeder Sets', Colors.blueAccent),
                        ...ex.series
                            .asMap()
                            .entries
                            .where((e) => e.value.tipo == TipoSerie.feeder)
                            .map(
                              (entry) => _buildSerieRow(
                                exIndex,
                                entry.key,
                                entry.value,
                                feederSeries.indexOf(entry.value) + 1,
                              ),
                            ),
                      ],
                      if (trabalhoSeries.isNotEmpty) ...[
                        _buildSectionTitle(
                          'Séries de Trabalho',
                          AppTheme.textSecondary,
                        ),
                        ...ex.series
                            .asMap()
                            .entries
                            .where((e) => e.value.tipo == TipoSerie.trabalho)
                            .map(
                              (entry) => _buildSerieRow(
                                exIndex,
                                entry.key,
                                entry.value,
                                trabalhoSeries.indexOf(entry.value) + 1,
                              ),
                            ),
                      ],

                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: InkWell(
                          onTap: () => _editarObservacao(context, exIndex),
                          borderRadius: BorderRadius.circular(8),
                          child: ex.observacao.isEmpty
                              ? Row(
                                  children: [
                                    Icon(
                                      Icons.add_comment_outlined,
                                      color: AppTheme.textSecondary.withAlpha(
                                        100,
                                      ),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Adicionar nota...',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary.withAlpha(
                                          150,
                                        ),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
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

                      TextButton(
                        onPressed: () => _adicionarSerie(exIndex),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                          ),
                          backgroundColor: Colors.white.withAlpha(5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              color: AppTheme.textSecondary.withAlpha(200),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Adicionar Série',
                              style: TextStyle(
                                color: AppTheme.textSecondary.withAlpha(200),
                                fontSize: 13,
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

  Widget _buildExpandedHeader(ExercicioItem ex, int exIndex) {
    return Padding(
      key: const ValueKey('expanded_header'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        ),
                      ),
                    ),
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
                        if (value == 'remover') _removerExercicio(exIndex);
                      },
                      itemBuilder: (context) => [
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
                                'Remover Exercício',
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
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
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
                                  size: 24,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(60),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                const Icon(
                                  Icons.play_circle_fill,
                                  color: AppTheme.primary,
                                  size: 24,
                                ),
                              ],
                            )
                          : const SizedBox(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MÚSCULO ALVO',
                            style: TextStyle(
                              color: AppTheme.textSecondary.withAlpha(150),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
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

  Widget _buildCollapsedHeader(ExercicioItem ex, int index) {
    return Padding(
      key: const ValueKey('collapsed_header'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Icon(
              Icons.drag_indicator,
              color: AppTheme.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
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
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.keyboard_arrow_down,
            color: AppTheme.textSecondary.withAlpha(150),
            size: 22,
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
            size: 12,
            color: color.withAlpha(200),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: color.withAlpha(200),
              fontSize: 11,
              fontWeight: FontWeight.w700,
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
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withAlpha(100),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$visualNumber',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildCleanInput(
              serie.alvo,
              (val) {
                serie.alvo = val;
                _hasChanges = true; // Marca como modificado
              },
              autoSuffix: _exerciciosLocais[exIndex].tipoAlvo == 'Tempo'
                  ? 's'
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildCleanInput(serie.carga, (val) {
              serie.carga = val;
              _hasChanges = true; // Marca como modificado
            }, autoSuffix: 'kg'),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildCleanInput(serie.descanso, (val) {
              serie.descanso = val;
              _hasChanges = true; // Marca como modificado
            }, autoSuffix: 's'),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removerSerie(exIndex, realIndex),
            child: SizedBox(
              width: 28,
              height: 30,
              child: Icon(
                Icons.close,
                color: AppTheme.textSecondary.withAlpha(150),
                size: 16,
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
}

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
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
