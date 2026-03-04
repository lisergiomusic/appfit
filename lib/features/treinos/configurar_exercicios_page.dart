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
        : [
            // Mocked data
            ExercicioItem(
              nome: 'Supino Reto',
              grupoMuscular: 'Peito',
              observacao: 'Aquecimento',
              tipoAlvo: 'Reps',
              series: [
                SerieItem(
                  tipo: TipoSerie.aquecimento,
                  alvo: '15',
                  carga: '20kg',
                  descanso: '60s',
                ),
                SerieItem(
                  tipo: TipoSerie.trabalho,
                  alvo: '10',
                  carga: '40kg',
                  descanso: '90s',
                ),
              ],
            ),
            ExercicioItem(
              nome: 'Rosca Direta',
              grupoMuscular: 'Bíceps',
              observacao: 'Foco na execução',
              tipoAlvo: 'Reps',
              series: [
                SerieItem(
                  tipo: TipoSerie.trabalho,
                  alvo: '12',
                  carga: '15kg',
                  descanso: '60s',
                ),
              ],
            ),
            ExercicioItem(
              nome: 'Agachamento Livre',
              grupoMuscular: 'Pernas',
              observacao: 'Cuidado com a postura',
              tipoAlvo: 'Reps',
              series: [
                SerieItem(
                  tipo: TipoSerie.trabalho,
                  alvo: '8',
                  carga: '60kg',
                  descanso: '120s',
                ),
              ],
            ),
          ];
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
        backgroundColor: Colors.black, // Mantido o preto que escolheste
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // --- O MAGNÍFICO SLIVER APP BAR NATIVO (COM MORPHING PERFEITO) ---
            SliverAppBar(
              backgroundColor: Colors.black,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              expandedHeight: 140.0,
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
                    const Text(
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
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  // Calcula a altura colapsada exata (Status Bar + Toolbar padrão)
                  final double collapsedHeight =
                      MediaQuery.of(context).padding.top + kToolbarHeight;
                  // Ocorre a transição de opacidade quando está a 20px de fechar totalmente
                  final bool isCollapsed =
                      constraints.biggest.height <= collapsedHeight + 20;

                  return FlexibleSpaceBar(
                    centerTitle: true,
                    titlePadding: const EdgeInsets.only(bottom: 14),
                    // --- TÍTULO PEQUENO (Aparece centralizado no topo) ---
                    title: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: isCollapsed ? 1.0 : 0.0,
                      child: Text(
                        widget.nomeTreino,
                        style: const TextStyle(
                          fontFamily: '.SF UI Display',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    // --- TÍTULO GIGANTE (Fica ancorado à esquerda em baixo) ---
                    background: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20, bottom: 16),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: isCollapsed ? 0.0 : 1.0,
                          child: Text(
                            widget.nomeTreino,
                            style: const TextStyle(
                              fontFamily: '.SF UI Display',
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 48,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- O CORPO DA PÁGINA (SUBTÍTULO E LISTA) ---
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // O subtítulo fica logo abaixo do título gigante, mas sobe com o scroll
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Text(
                      '${_exerciciosLocais.length} exercícios configurados',
                      style: TextStyle(
                        color: AppTheme.textSecondary.withAlpha(180),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // --- NOVA SEÇÃO: PILLS DE MÚSCULOS ---
                  if (_gruposMuscularesUnicos.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _gruposMuscularesUnicos.map((grupo) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.primary.withAlpha(60),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              grupo.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  // --- FIM DA NOVA SEÇÃO ---

                  // Se estiver vazio, mostra o empty state
                  if (_exerciciosLocais.isEmpty)
                    SizedBox(
                      height:
                          400, // Altura fixa para centralizar o empty state no scroll
                      child: _buildEmptyState(),
                    ),
                ],
              ),
            ),

            // --- A LISTA REORDENÁVEL COMO UM SLIVER ---
            if (_exerciciosLocais.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverReorderableList(
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
  // O CARD PREMIUM (ESTÁTICO E LIMPO - PUSH NAVIGATION)
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
            setState(() {}); // Atualiza a contagem de séries na lista ao voltar
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

