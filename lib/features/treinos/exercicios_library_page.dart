import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;

  // Estado da lista
  List<ExercicioItem> _listaExercicios = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;

  final List<String> _categorias = [
    'Tudo',
    'Peito',
    'Costas',
    'Pernas',
    'Deltóides',
    'Bíceps',
    'Tríceps',
    'Glúteos',
    'Panturrilhas',
    'Abdômen',
    'Meus Exercícios',
  ];
  String _categoriaSelecionada = 'Tudo';
  String _termoBusca = '';

  // Seleção baseada no ID ou Nome (Identidade Única)
  final Set<ExercicioItem> _selecionados = {};

  @override
  void initState() {
    super.initState();
    _carregarDados(reset: true);
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(() {
      // Força rebuild para mostrar/esconder o botão Cancelar
      setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _carregarDados();
      }
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_termoBusca != value) {
        setState(() {
          _termoBusca = value;
        });
        _carregarDados(reset: true);
      }
    });
  }

  void _limparBusca() {
    if (_searchController.text.isEmpty && _termoBusca.isEmpty) return;

    _searchController.clear();
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    if (_termoBusca.isNotEmpty) {
      setState(() {
        _termoBusca = '';
      });
      _carregarDados(reset: true);
    }
  }

  Future<void> _carregarDados({bool reset = false}) async {
    if (_isLoading && !reset) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        _listaExercicios = [];
        _lastDoc = null;
        _hasMore = true;
      }
    });

    try {
      final result = await _exerciseService.buscarBibliotecaPaginada(
        categoria: _categoriaSelecionada,
        busca: _termoBusca.isEmpty ? null : _termoBusca,
        lastDoc: _lastDoc,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _listaExercicios.addAll(result.items);
          _lastDoc = result.lastDoc;
          _hasMore = result.hasMore;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    }
  }

  void _confirmarSelecao() {
    Navigator.pop(context, _selecionados.toList());
  }

  void _alternarSelecao(ExercicioItem ex) {
    setState(() {
      if (_selecionados.contains(ex)) {
        _selecionados.remove(ex);
      } else {
        _selecionados.add(ex);
      }
    });
  }

  void _abrirResumoSelecao() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final selecionadosList = _selecionados.toList();

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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
                        color: AppTheme.textPrimary,
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
                      final ex = selecionadosList[idx];

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
                                    ex.grupoMuscular.join(' • '),
                                    style: const TextStyle(
                                      color: AppTheme.textLabel,
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
                                  _selecionados.remove(ex);
                                });
                                setState(() {});
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
                    Navigator.pop(context);
                    _confirmarSelecao();
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

  void _mostrarPreviewExercicio(ExercicioItem ex) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isSelected = _selecionados.contains(ex);

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: AppTheme.surfaceLight,
                      child: ex.imagemUrl != null && ex.imagemUrl!.isNotEmpty
                          ? _buildMediaPreview(ex.imagemUrl!)
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
                                    'Mídia indisponível',
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
                  ex.grupoMuscular.join(' • '),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    _alternarSelecao(ex);
                    if (!isSelected) {
                      Navigator.of(context).pop(true);
                    } else {
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


  }

  Widget _buildMediaPreview(String url) {
    final videoId = _getYoutubeId(url);
    if (videoId != null) {
      final thumbUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(thumbUrl, fit: BoxFit.cover),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(150),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
            ),
          ),
        ],
      );
    }
    // Para GIFs, Image.network anima normalmente
    return Image.network(url, fit: BoxFit.cover);
  }

  String? _getYoutubeId(String url) {
    final RegExp regExp = RegExp(
      r"(?<=vi/|v/|vi=|/v/|youtu\.be/|/embed/|v=).+?(?=\?|#|&|$)",
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Biblioteca de exercícios',
          style: AppTheme.pageTitle,
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Tooltip(
              message: 'Criar novo exercício',
              child: TextButton.icon(
                onPressed: () async {
                  final dynamic result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CriarExercicioPage(),
                    ),
                  );

                  if (result != null && result is ExercicioItem && mounted) {
                    setState(() {
                      _selecionados.add(result);
                    });
                    _carregarDados(reset: true);
                  }
                },
                icon: const Icon(Icons.add, color: AppTheme.primary, size: 18),
                label: const Text(
                  'Criar',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),

              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Buscar exercícios...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),

                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, value, _) {
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: value.text.isNotEmpty
                                ? IconButton(
                                    key: const ValueKey('clear_search'),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: AppTheme.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: _limparBusca,
                                  )
                                : const SizedBox.shrink(),
                          );
                        },
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceDark,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axis: Axis.horizontal,
                        child: child,
                      ),
                    );
                  },
                  child: _searchFocusNode.hasFocus
                      ? Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: TextButton(
                            onPressed: () {
                              _searchFocusNode.unfocus();
                              _limparBusca();
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
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
                    onSelected: (val) {
                      if (val) {
                        setState(() => _categoriaSelecionada = cat);
                        _carregarDados(reset: true);
                      }
                    },
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.surfaceDark,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      letterSpacing: 0.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(AppTheme.radiusLG),
                    ),
                    side: BorderSide.none,
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _listaExercicios.isEmpty && _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _listaExercicios.isEmpty
                ? const Center(
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
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _listaExercicios.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _listaExercicios.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }

                      final ex = _listaExercicios[index];
                      final isSelected = _selecionados.contains(ex);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                            onTap: () => _mostrarPreviewExercicio(ex),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceDark,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                                      border: ex.personalId != null
                                          ? Border.all(
                                              color: AppTheme.accentMetrics
                                                  .withAlpha(100),
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: ex.personalId != null
                                        ? const Center(
                                            child: Icon(
                                              Icons.star_rounded,
                                              color: AppTheme.accentMetrics,
                                              size: 28,
                                            ),
                                          )
                                        : (ex.imagemUrl != null &&
                                              ex.imagemUrl!.isNotEmpty)
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                                            child: _StaticImage(url: ex.imagemUrl!),
                                          )
                                        : const Center(
                                            child: Icon(
                                              Icons.fitness_center,
                                              color: AppTheme.primary,
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
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 17,
                                            letterSpacing: -0.1,
                                          ),
                                        ),

                                        Text(
                                          ex.grupoMuscular.join(' • '),
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _alternarSelecao(ex),
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
                  ),
          ),
        ],
      ),
    ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selecionados.isNotEmpty
          ? Container(
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(
                  color: Colors.white.withAlpha(20), // ~8% opacity
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25), // ~10% opacity
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Material(
                      color: Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      child: InkWell(
                        onTap: _abrirResumoSelecao,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                        splashColor: AppTheme.primary.withAlpha(30), // ~12% opacity
                        highlightColor: AppTheme.primary.withAlpha(20), // ~8% opacity
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.space8),
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
                            const SizedBox(width: AppTheme.space8),
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
                  ),

                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      onPressed: _confirmarSelecao,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.black,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.space12),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                      icon: const Icon(Icons.check, size: 20, color: Colors.black),
                      label: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _StaticImage extends StatefulWidget {
  final String url;
  const _StaticImage({required this.url});

  @override
  State<_StaticImage> createState() => _StaticImageState();
}

class _StaticImageState extends State<_StaticImage> {
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;
  ImageStreamListener? _listener;
  bool _hasError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getImage();
  }

  @override
  void didUpdateWidget(_StaticImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _getImage();
  }

  void _getImage() {
    _cleanup();
    if (widget.url.isEmpty) return;

    _hasError = false;
    _imageInfo = null;

    final videoId = _getYoutubeIdStatic(widget.url);
    final finalUrl = videoId != null
        ? 'https://img.youtube.com/vi/$videoId/0.jpg'
        : widget.url;

    _imageStream = CachedNetworkImageProvider(finalUrl).resolve(createLocalImageConfiguration(context));

    _listener = ImageStreamListener(
      (info, _) {
        if (mounted && _imageInfo == null) {
          setState(() => _imageInfo = info);
          _cleanup(); // Congela o GIF após o primeiro frame
        }
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        if (mounted) setState(() => _hasError = true);
      },
    );
    _imageStream!.addListener(_listener!);
  }

  String? _getYoutubeIdStatic(String url) {
    final RegExp regExp = RegExp(
      r"(?<=vi/|v/|vi=|/v/|youtu\.be/|/embed/|v=).+?(?=\?|#|&|$)",
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(0);
  }

  void _cleanup() {
    if (_imageStream != null && _listener != null) {
      _imageStream!.removeListener(_listener!);
    }
    _imageStream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        width: 56,
        height: 56,
        color: AppTheme.surfaceLight,
        child: const Icon(Icons.fitness_center, color: AppTheme.textSecondary),
      );
    }

    if (_imageInfo == null) {
      return Container(
        width: 56,
        height: 56,
        color: AppTheme.surfaceLight,
      );
    }

    return RawImage(
      image: _imageInfo!.image,
      fit: BoxFit.cover,
      width: 56,
      height: 56,
    );
  }
}