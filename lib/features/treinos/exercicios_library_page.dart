import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/exercise_service.dart';
import 'models/exercicio_model.dart';

class ExerciciosLibraryPage extends StatefulWidget {
  const ExerciciosLibraryPage({super.key});

  @override
  State<ExerciciosLibraryPage> createState() => _ExerciciosLibraryPageState();
}

class _ExerciciosLibraryPageState extends State<ExerciciosLibraryPage> {
  final ExerciseService _exerciseService = ExerciseService();
  late Future<List<ExercicioItem>> _futureExercicios;

  // ABAS ATUALIZADAS COM BÍCEPS E TRÍCEPS
  final List<String> _categorias = [
    'Tudo',
    'Peito',
    'Costas',
    'Pernas',
    'Glúteos',
    'Ombros',
    'Bíceps',
    'Tríceps',
    'Abdômen',
    'Meus Exercícios',
  ];
  String _categoriaSelecionada = 'Tudo';
  final Set<int> _selecionados = {};
  List<ExercicioItem> _listaTotalDaCloud = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() {
    setState(() {
      _futureExercicios = _exerciseService.buscarBibliotecaCompleta();
    });
  }

  void _confirmarSelecao() {
    final selecionadosList = _selecionados
        .map((i) => _listaTotalDaCloud[i])
        .toList();
    Navigator.pop(context, selecionadosList);
  }

  void _alternarSelecao(int index) {
    setState(() {
      if (_selecionados.contains(index)) {
        _selecionados.remove(index);
      } else {
        _selecionados.add(index);
      }
    });
  }

  void _exibirModalCriarExercicio() {
    final nomeCtrl = TextEditingController();
    final musculoCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
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
            const Text(
              'Criar Novo Exercício',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nomeCtrl,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nome do Exercício (Ex: Supino Reto Barra)',
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: musculoCtrl,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Grupo Muscular (Ex: Pernas, Glúteos)',
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (nomeCtrl.text.trim().isEmpty) return;

                final novoEx = ExercicioItem(
                  nome: nomeCtrl.text.trim(),
                  grupoMuscular: musculoCtrl.text.trim().isEmpty
                      ? 'Geral'
                      : musculoCtrl.text.trim(),
                  series: [],
                );

                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                navigator.pop();

                try {
                  await _exerciseService.criarExercicioCustomizado(novoEx);
                  if (!mounted) return;
                  _carregarDados();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Exercício criado com sucesso!'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Erro: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Salvar e Adicionar à Biblioteca',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Biblioteca',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          // BOTÃO VARINHA MÁGICA: Popula o banco de dados
          IconButton(
            icon: const Icon(Icons.auto_fix_high, color: Colors.amber),
            tooltip: 'Semear Banco de Dados',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('A injetar a biomecânica na Cloud...'),
                ),
              );
              try {
                await _exerciseService.semearExerciciosBase();
                if (!mounted) return; // Fix do Async Gap!
                _carregarDados();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Biblioteca Padrão criada com sucesso!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Erro: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.add_box_outlined,
              color: AppTheme.primary,
              size: 28,
            ),
            tooltip: 'Criar Exercício',
            onPressed: _exibirModalCriarExercicio,
          ),
          Padding(
            padding: const EdgeInsets.only(
              right: 16,
              top: 8,
              bottom: 8,
              left: 8,
            ),
            child: ElevatedButton(
              onPressed: _selecionados.isEmpty ? null : _confirmarSelecao,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                disabledBackgroundColor: AppTheme.surfaceLight,
                shape: const StadiumBorder(),
                elevation: _selecionados.isEmpty ? 0 : 8,
                shadowColor: AppTheme.primary.withAlpha(100),
              ),
              child: Text(
                'Adicionar (${_selecionados.length})',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar exercícios...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categorias.length,
                  itemBuilder: (context, index) {
                    final cat = _categorias[index];
                    final isSelected = _categoriaSelecionada == cat;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (val) =>
                            setState(() => _categoriaSelecionada = cat),
                        selectedColor: AppTheme.primary,
                        backgroundColor: AppTheme.surfaceDark,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : AppTheme.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: const StadiumBorder(),
                        side: BorderSide.none,
                        showCheckmark: false,
                      ),
                    );
                  },
                ),
              ),

              Expanded(
                child: FutureBuilder<List<ExercicioItem>>(
                  future: _futureExercicios,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erro: ${snapshot.error}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      );
                    }

                    _listaTotalDaCloud = snapshot.data ?? [];

                    List<ExercicioItem> listaFiltrada = _listaTotalDaCloud;
                    if (_categoriaSelecionada == 'Meus Exercícios') {
                      listaFiltrada = _listaTotalDaCloud
                          .where((ex) => ex.personalId != null)
                          .toList();
                    } else if (_categoriaSelecionada != 'Tudo') {
                      listaFiltrada = _listaTotalDaCloud
                          .where(
                            (ex) => ex.grupoMuscular.toLowerCase().contains(
                              _categoriaSelecionada.toLowerCase(),
                            ),
                          )
                          .toList();
                    }

                    if (listaFiltrada.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.fitness_center,
                              size: 64,
                              color: AppTheme.surfaceLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _categoriaSelecionada == 'Meus Exercícios'
                                  ? 'Você ainda não criou nenhum exercício.'
                                  : 'Nenhum exercício encontrado. Clique na varinha mágica no topo!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                      itemCount: listaFiltrada.length,
                      itemBuilder: (context, index) {
                        final ex = listaFiltrada[index];
                        final realIndex = _listaTotalDaCloud.indexOf(ex);
                        final isSelected = _selecionados.contains(realIndex);

                        return GestureDetector(
                          onTap: () => _alternarSelecao(realIndex),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceLight,
                                    shape: BoxShape.circle,
                                    border: ex.personalId != null
                                        ? Border.all(
                                            color: AppTheme.accentMetrics
                                                .withAlpha(100),
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      ex.personalId != null
                                          ? Icons.star_rounded
                                          : Icons.fitness_center,
                                      color: ex.personalId != null
                                          ? AppTheme.accentMetrics
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ex.nome,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ex.grupoMuscular,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : AppTheme.textSecondary.withAlpha(
                                              50,
                                            ),
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? AppTheme.primary
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.black,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          if (_selecionados.isNotEmpty)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(color: AppTheme.primary.withAlpha(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(150),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_selecionados.length}',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Exercícios\nselecionados',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
