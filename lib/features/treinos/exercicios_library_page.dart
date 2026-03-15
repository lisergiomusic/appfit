import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/exercise_service.dart';
import 'models/exercicio_model.dart';
import 'criar_exercicio_page.dart';

class ExerciciosLibraryPage extends StatefulWidget {
  const ExerciciosLibraryPage({super.key});

  @override
  State<ExerciciosLibraryPage> createState() => _ExerciciosLibraryPageState();
}

class _ExerciciosLibraryPageState extends State<ExerciciosLibraryPage> {
  final ExerciseService _exerciseService = ExerciseService();
  late Future<List<ExercicioItem>> _futureExercicios;

  final List<String> _categorias = [
    'Tudo',
    'Peito',
    'Costas',
    'Pernas',
    'Glúteos',
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

  // Finaliza a seleção e volta para a tela de Rotina
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

  // --- 2. NOVO MODAL: RESUMO DOS SELECIONADOS (O "CARRINHO") ---
  void _abrirResumoSelecao() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        // Usamos StatefulBuilder para atualizar a aba ao remover itens
        builder: (context, setModalState) {
          // Pega a lista real baseada nos índices
          final selecionadosList = _selecionados.toList();

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Exercícios Selecionados',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_selecionados.length}',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: selecionadosList.length,
                    itemBuilder: (context, idx) {
                      final realIndex = selecionadosList[idx];
                      final ex = _listaTotalDaCloud[realIndex];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex.nome,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ex.grupoMuscular,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                setModalState(() {
                                  _selecionados.remove(realIndex);
                                  selecionadosList.removeAt(idx);
                                });
                                // Atualiza a tela de trás também!
                                setState(() {});

                                // Se esvaziar tudo, fecha a aba automaticamente
                                if (_selecionados.isEmpty) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Fecha a aba
                    _confirmarSelecao(); // Salva e volta para a tela de rotina
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Adicionar ao Treino',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- 3. NOVO MODAL: PREVIEW DO EXERCÍCIO ---
  void _mostrarPreviewExercicio(ExercicioItem ex, int realIndex) async {
    final exercicioFoiAdicionado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isSelected = _selecionados.contains(realIndex);

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle de arrastar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Pré-visualização do Vídeo/GIF
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: AppTheme.surfaceLight,
                      child: ex.imagemUrl != null && ex.imagemUrl!.isNotEmpty
                          ? Image.network(ex.imagemUrl!, fit: BoxFit.cover)
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.videocam_off,
                                    color: AppTheme.textSecondary,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Vídeo indisponível',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Textos
                Text(
                  ex.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ex.grupoMuscular,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),

                // Botão de Ação Dinâmico
                ElevatedButton(
                  onPressed: () {
                    // Alterna a seleção
                    _alternarSelecao(realIndex);

                    // `isSelected` reflete o estado ANTES de `_alternarSelecao` ser chamado.
                    if (!isSelected) {
                      // Fecha o modal e retorna `true` para disparar o SnackBar
                      Navigator.of(context).pop(true);
                    } else {
                      // Se já estava selecionado, o usuário clicou em "Remover".
                      // Apenas atualizamos o estado do modal.
                      setModalState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? AppTheme.surfaceLight
                        : AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isSelected ? 'Remover do Treino' : 'Adicionar ao Treino',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? Colors.redAccent : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (exercicioFoiAdicionado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${ex.nome}" adicionado à lista.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          'Biblioteca',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: () async {
                // Aqui está o segredo: Usamos 'dynamic' (ou deixamos sem tipo)
                // porque agora a página devolve um objeto ExercicioItem, e não um bool!
                final dynamic result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CriarExercicioPage(),
                  ),
                );

                // Se voltou um ExercicioItem, a criação foi um sucesso!
                if (result != null && result is ExercicioItem && mounted) {
                  // 1. Busca a lista atualizada da Nuvem
                  final novaLista = await _exerciseService
                      .buscarBibliotecaCompleta();

                  setState(() {
                    // 2. Atualiza os dados da tela
                    _futureExercicios = Future.value(novaLista);
                    _listaTotalDaCloud = novaLista;

                    // 3. Procura o "Index" (posição) do exercício que acabou de ser criado
                    final novoIndex = _listaTotalDaCloud.indexWhere(
                      (ex) => ex.nome == result.nome && ex.personalId != null,
                    );

                    // 4. Mágica: Adiciona automaticamente ao carrinho!
                    if (novoIndex != -1) {
                      _selecionados.add(novoIndex);
                    }
                  });
                }
              },
              icon: const Icon(Icons.add, color: AppTheme.primary, size: 20),
              label: const Text(
                'Novo Exercício',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      color: isSelected ? Colors.black : AppTheme.textSecondary,
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
                    child: CircularProgressIndicator(color: AppTheme.primary),
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
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppTheme.surfaceLight,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum exercício encontrado.',
                          style: TextStyle(color: AppTheme.textSecondary),
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

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          // 1. ZONA ESQUERDA (O CARD): ABRE O PREVIEW
                          onTap: () => _mostrarPreviewExercicio(ex, realIndex),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // O AVATAR DO EXERCÍCIO (Estrela, Imagem ou Halter)
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceLight,
                                    shape: BoxShape.circle,
                                    border: ex.personalId != null
                                        ? Border.all(
                                      color: AppTheme.accentMetrics.withAlpha(100),
                                      width: 2,
                                    )
                                        : null,
                                  ),
                                  // MÁGICA DA RENDERIZAÇÃO AQUI
                                  child: ex.personalId != null
                                  // Condição 1: É personalizado (Estrela)
                                      ? Center(
                                    child: Icon(
                                      Icons.star_rounded,
                                      color: AppTheme.accentMetrics,
                                      size: 28,
                                    ),
                                  )
                                      : (ex.imagemUrl != null && ex.imagemUrl!.isNotEmpty)
                                  // Condição 2: Tem Imagem (Thumbnail circular)
                                      ? ClipOval(
                                    child: Image.network(
                                      ex.imagemUrl!,
                                      fit: BoxFit.cover,
                                      // Se a imagem no link quebrar/sair do ar, volta pro halter!
                                      errorBuilder: (context, error, stackTrace) => const Center(
                                        child: Icon(Icons.fitness_center, color: AppTheme.textSecondary),
                                      ),
                                    ),
                                  )
                                  // Condição 3: Padrão sem imagem (Halter)
                                      : const Center(
                                    child: Icon(
                                      Icons.fitness_center,
                                      color: AppTheme.textSecondary,
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

                                // 2. ZONA DIREITA (A BOLINHA): SELECIONA O EXERCÍCIO
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _alternarSelecao(realIndex),
                                  child: Container(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      top: 8,
                                      bottom: 8,
                                    ),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppTheme.primary
                                              : AppTheme.textSecondary
                                                    .withAlpha(50),
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
                                  ),
                                ),
                              ],
                            ),
                          ),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selecionados.isNotEmpty
          ? Container(
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppTheme.primary.withAlpha(40),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(180),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // LADO ESQUERDO: VER LISTA
                  Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: _abrirResumoSelecao,
                      borderRadius: BorderRadius.circular(28),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.surfaceLight,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_selecionados.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Ver lista',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // LADO DIREITO: ADICIONAR DIRETO
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: _confirmarSelecao,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Salvar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
