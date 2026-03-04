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

  late List<ExercicioItem> _exerciciosLocais;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
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
    setState(() {
      _exerciciosLocais.removeAt(exIndex);
      _hasChanges = true;
      if (_expandedExIndex == exIndex) {
        _expandedExIndex = null;
      } else if (_expandedExIndex != null && _expandedExIndex! > exIndex) {
        _expandedExIndex = _expandedExIndex! - 1;
      }
    });
  }

  void _confirmarRemocaoExercicio(BuildContext context, int exIndex) {
    final nomeExercicio = _exerciciosLocais[exIndex].nome;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Remover exercício?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        content: Text(
          nomeExercicio,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
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
              Navigator.pop(context);
              _removerExercicio(exIndex);
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

  void _confirmarRemocaoNota(BuildContext context, int exIndex) {
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
                _exerciciosLocais[exIndex].observacao = '';
                _hasChanges = true;
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

  void _editarObservacao(BuildContext context, int exIndex) {
    final controller = TextEditingController(
      text: _exerciciosLocais[exIndex].observacao,
    );

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
                    _exerciciosLocais[exIndex].observacao = controller.text
                        .trim();
                    _hasChanges = true;
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

  Future<void> _adicionarSerie(int exIndex) async {
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
        _hasChanges = true;
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

  void _removerSerie(int exIndex, int realIndex) {
    setState(() {
      _exerciciosLocais[exIndex].series.removeAt(realIndex);
      _hasChanges = true;
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _exerciciosLocais.removeAt(oldIndex);
      _exerciciosLocais.insert(newIndex, item);
      _hasChanges = true;

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
        _hasChanges = true;
      });
    }
  }

  void _concluirEdicao() {
    widget.exercicios.clear();
    widget.exercicios.addAll(_exerciciosLocais);
    Navigator.pop(context, true);
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!_hasChanges) {
          Navigator.maybePop(context);
          return;
        }
        final sair = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Text(
              'Descartar alterações?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
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
        // ignore: use_build_context_synchronously
        if (sair == true) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 100,
          leading: GestureDetector(
            onTap: _onBackPressed,
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
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _concluirEdicao,
                child: const Text(
                  'Concluir',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER GIGANTE APPLE STYLE ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nomeTreino,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_exerciciosLocais.length} exercícios configurados',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withAlpha(180),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // --- LISTA DE EXERCÍCIOS ---
            Expanded(
              child: _exerciciosLocais.isEmpty
                  ? _buildEmptyState()
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: _exerciciosLocais.length + 1,
                      onReorder: (oldIndex, newIndex) {
                        if (oldIndex == _exerciciosLocais.length ||
                            newIndex > _exerciciosLocais.length) {
                          return;
                        }
                        _onReorder(oldIndex, newIndex);
                      },
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
                            margin: const EdgeInsets.only(top: 8),
                            child: _buildAddExercicioButton(),
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

  Widget _buildAddExercicioButton() {
    return InkWell(
      onTap: _openLibrary,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withAlpha(25),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primary.withAlpha(100),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Adicionar Exercício',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.2,
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
  // O CARD PREMIUM (CABEÇALHO UNIFICADO E ACORDEÃO SUAVE)
  // =======================================================
  Widget _buildExercicioCard(int exIndex) {
    final ex = _exerciciosLocais[exIndex];

    return Container(
      key: ObjectKey(ex),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(15), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            FocusScope.of(context).unfocus();
            setState(() {
              _expandedExIndex = _expandedExIndex == exIndex ? null : exIndex;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: exIndex,
                  child: Icon(
                    Icons.drag_indicator,
                    color: AppTheme.textSecondary.withAlpha(80),
                    size: 24,
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
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ex.series.length} ${ex.series.length == 1 ? 'série' : 'séries'} • ${ex.grupoMuscular}',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withAlpha(180),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary.withAlpha(150),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- COMPONENTES AUXILIARES DO CARD ---

  TextStyle _sectionHeaderStyle() {
    return TextStyle(
      color: AppTheme.textSecondary.withAlpha(120),
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    );
  }

  // BADGES MINIMALISTAS: Só um micro-ponto de cor, texto cinza
  Widget _buildBadgeTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ), // Ponto minúsculo
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

  Widget _buildSerieRow(
    int exIndex,
    int realIndex,
    SerieItem serie,
    int visualNumber,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 44, // Acompanha a largura da palavra SÉRIE
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
            child: _buildCleanInput(
              serie.alvo,
              (val) {
                serie.alvo = val;
                _hasChanges = true;
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
              _hasChanges = true;
            }, autoSuffix: 'kg'),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildCleanInput(serie.descanso, (val) {
              serie.descanso = val;
              _hasChanges = true;
            }, autoSuffix: 's'),
          ),
          const SizedBox(width: 8),

          // Menu de ações da série (duplicar e excluir)
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
                      _exerciciosLocais[exIndex].series.insert(
                        realIndex + 1,
                        novaSerie,
                      );
                      _hasChanges = true;
                    });
                  } else if (value == 'delete') {
                    _removerSerie(exIndex, realIndex);
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

  Widget _buildCleanInput(
    String initialValue,
    ValueChanged<String> onChanged, {
    String? autoSuffix,
  }) {
    return _ModernInputWidget(
      initialValue: initialValue,
      onChanged: onChanged,
      autoSuffix: autoSuffix,
    );
  }

  Widget _buildCardAction({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    required bool showDivider,
    bool isNote = false,
    VoidCallback? onRemoveNote,
    Color? iconColor,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: isNote
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: iconColor ?? (isNote ? AppTheme.textSecondary : color),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isNote ? AppTheme.textSecondary : color,
                      fontSize: 15,
                      fontWeight: isNote ? FontWeight.w400 : FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: isNote ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isNote && onRemoveNote != null) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onRemoveNote,
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
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.white.withAlpha(20),
            indent: 48,
          ),
      ],
    );
  }
}

// --- CONTROLE DE INPUT ELEGANTE ---
class _ModernInputWidget extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? autoSuffix;

  const _ModernInputWidget({
    required this.initialValue,
    required this.onChanged,
    this.autoSuffix,
  });

  @override
  State<_ModernInputWidget> createState() => _ModernInputWidgetState();
}

class _ModernInputWidgetState extends State<_ModernInputWidget> {
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
    setState(() {}); // Força a atualização da cor instantaneamente
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
  void didUpdateWidget(covariant _ModernInputWidget oldWidget) {
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
    final isFocused = _focusNode.hasFocus;

    return SizedBox(
      height: 36,
      child: Center(
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.text,
          cursorColor: AppTheme.primary,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isFocused
                ? AppTheme.primary.withAlpha(35)
                : Colors.white.withAlpha(15),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withAlpha(30),
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppTheme.primary.withAlpha(150),
                width: 0.5,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
