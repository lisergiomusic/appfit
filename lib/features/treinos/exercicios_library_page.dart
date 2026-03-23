import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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
    final exercicioFoiAdicionado = await showModalBottomSheet<bool>(
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
        title: const Text(
          'Biblioteca de exercícios',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: () async {
                final dynamic result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CriarExercicioPage(),
                  ),
                );

                if (result != null && result is ExercicioItem && mounted) {
                  // Ao criar um novo, adicionamos à seleção e recarregamos a lista
                  setState(() {
                    _selecionados.add(result);
                  });
                  _carregarDados(reset: true);
                }
              },
              icon: const Icon(Icons.add, color: AppTheme.primary, size: 20),
              label: const Text(
                'Criar',
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar exercícios...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surfaceDark,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onSearchChanged,
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
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
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
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _mostrarPreviewExercicio(ex),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(12),
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
                                            borderRadius: BorderRadius.circular(12),
                                            child: _StaticImage(url: ex.imagemUrl!),
                                          )
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
                                          ex.grupoMuscular.join(' • '),
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 13,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selecionados.isNotEmpty
          ? Container(
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 16),
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