import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/exercise_service.dart';
import '../../../../core/services/supabase_auth_service.dart';
import '../../shared/models/exercicio_model.dart';
import '../../../../core/utils/cloudinary.dart';
import 'personal_criar_exercicio_page.dart';

class PersonalExerciciosLibraryPage extends StatefulWidget {
  const PersonalExerciciosLibraryPage({super.key});

  @override
  State<PersonalExerciciosLibraryPage> createState() =>
      _PersonalExerciciosLibraryPageState();
}

class _PersonalExerciciosLibraryPageState
    extends State<PersonalExerciciosLibraryPage> {
  final ExerciseService _exerciseService = ExerciseService();
  final SupabaseAuthService _authService = SupabaseAuthService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;

  List<ExercicioItem> _listaExercicios = [];
  bool _isLoading = false;
  bool _isAdmin = false;
  bool _hasMore = true;
  dynamic _lastDoc;

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

  final Set<ExercicioItem> _selecionados = {};

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _carregarDados(reset: true);
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(() {
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

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _authService.isAdmin();
    if (mounted) {
      setState(() => _isAdmin = isAdmin);
    }
  }

  /// FUNÇÃO 1: Puxa o template e copia para o Clipboard
  Future<void> _copiarTemplateParaIA() async {
    try {
      final template = await _exerciseService.obterTemplateDeExercicio('Leg Press 45°');
      if (template == null) throw Exception('Modelo Leg Press 45° não encontrado.');

      // Remove IDs e campos nulos para ficar um JSON limpo para a IA
      template.remove('id');
      template.remove('personalId');

      final jsonString = const JsonEncoder.withIndent('  ').convert(template);
      await Clipboard.setData(ClipboardData(text: jsonString));

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Template Copiado!'),
            content: const Text('O formato JSON do Leg Press 45° foi copiado. Cole na sua IA e peça para ela gerar novos exercícios seguindo este exato padrão de campos.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  /// FUNÇÃO 2: Abre campo para colar o JSON da IA e salvar
  void _abrirDialogUploadMassa() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload em Massa'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Cole aqui o JSON (Lista) gerado pela IA...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                final List<dynamic> decoded = jsonDecode(controller.text);
                final exercicios = decoded.map((item) => ExercicioItem.fromSupabase(item)).toList();

                await _exerciseService.cadastrarExerciciosEmMassa(
                  exercicios,
                  asSystemExercises: true, // Garante que fiquem sem estrela
                );
                if (mounted) {
                  Navigator.pop(context);
                  _carregarDados(reset: true);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload concluído!')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro no JSON: $e')));
              }
            },
            child: const Text('Enviar para Firebase'),
          ),
        ],
      ),
    );
  }

  /// FUNÇÃO 3: Limpa tudo exceto o Leg Press 45°
  Future<void> _limparBibliotecaComConfirmacao() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Biblioteca?'),
        content: const Text('Isso apagará TODOS os exercícios, mantendo apenas o "Leg Press 45°" como base. Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Apagar Tudo'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _isLoading = true);
      try {
        await _exerciseService.limparColecaoExcetoModelo('Leg Press 45°');
        if (mounted) {
          _carregarDados(reset: true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biblioteca limpa com sucesso!')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
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
      backgroundColor: AppColors.surfaceDark,
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
                        color: AppColors.labelPrimary,
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
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_selecionados.length}',
                        style: const TextStyle(
                          color: AppColors.primary,
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
                          color: AppColors.surfaceLight,
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
                                      color: AppColors.textLabel,
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
                    backgroundColor: AppColors.primary,
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
      backgroundColor: AppColors.surfaceDark,
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
                      color: AppColors.surfaceLight,
                      child: ex.mediaUrl != null && ex.mediaUrl!.isNotEmpty
                          ? _buildMediaPreview(Cloudinary.thumbnail(ex.mediaUrl!))
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.videocam_off,
                                    color: AppColors.labelSecondary,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Mídia indisponível',
                                    style: TextStyle(
                                      color: AppColors.labelSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(ex.nome, style: AppTheme.title1),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ex.grupoMuscular.map((grupo) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: PillTokens.radius,
                      ),
                      child: Text(
                        grupo,
                        style: PillTokens.text.copyWith(
                          color: AppColors.labelSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (ex.instrucoes != null && ex.instrucoes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Instruções',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.3,
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        ex.instrucoes!,
                        style: const TextStyle(
                          color: AppColors.textLabel,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                if (_isAdmin) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PersonalCriarExercicioPage(
                              exercicioParaEditar: ex,
                            ),
                          ),
                        );
                        if (result != null && mounted) {
                          Navigator.pop(context); // Fecha o modal
                          _carregarDados(reset: true); // Recarrega a lista
                        }
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Editar Exercício (Admin)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
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
                        ? AppColors.surfaceLight
                        : AppColors.primary,
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
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppColors.surfaceLight,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.surfaceLight,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.labelSecondary,
            size: 40,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mapa de seções da interface desta página:
    // 1) Estrutura superior: AppBar, título e ações de navegação.
    // 2) Conteúdo principal: blocos, listas, cards e estados da tela.
    // 3) Ações finais: botões primários, confirmadores e feedbacks.
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Biblioteca de exercícios',
          style: AppTheme.pageTitle,
        ),
        centerTitle: false,
        actions: [
          if (_isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              onPressed: _limparBibliotecaComConfirmacao,
              tooltip: 'Limpar Biblioteca (Admin)',
            ),
            IconButton(
              icon: const Icon(Icons.copy_all_outlined, color: AppColors.primary),
              onPressed: _copiarTemplateParaIA,
              tooltip: 'Copiar Template (Admin)',
            ),
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
              onPressed: _abrirDialogUploadMassa,
              tooltip: 'Upload em Massa (Admin)',
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Tooltip(
              message: 'Criar novo exercício',
              child: TextButton.icon(
                onPressed: () async {
                  final dynamic result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PersonalCriarExercicioPage(),
                    ),
                  );

                  if (result != null && result is ExercicioItem && mounted) {
                    setState(() {
                      _selecionados.add(result);
                    });
                    _carregarDados(reset: true);
                  }
                },
                icon: const Icon(Icons.add, color: AppColors.primary, size: 18),
                label: const Text(
                  'Criar',
                  style: TextStyle(
                    color: AppColors.primary,
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
                      style: const TextStyle(
                        color: AppColors.labelPrimary,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar exercícios...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.labelSecondary,
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
                                        color: AppColors.labelSecondary,
                                        size: 20,
                                      ),
                                      onPressed: _limparBusca,
                                    )
                                  : const SizedBox.shrink(),
                            );
                          },
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
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
                                  color: AppColors.primary,
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
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceDark,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : AppColors.labelSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        letterSpacing: 0.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(
                          AppTheme.radiusLG,
                        ),
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
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _listaExercicios.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppColors.surfaceLight,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum exercício encontrado.',
                            style: TextStyle(color: AppColors.labelSecondary),
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
                                color: AppColors.primary,
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
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXL,
                              ),
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
                                        color: AppColors.surfaceDark,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusLG,
                                        ),
                                        border: ex.personalId != null
                                            ? Border.all(
                                                color: AppColors.accentMetrics
                                                    .withAlpha(100),
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      child: ex.personalId != null
                                          ? const Center(
                                              child: Icon(
                                                Icons.star_rounded,
                                                color: AppColors.accentMetrics,
                                                size: 28,
                                              ),
                                            )
                                          : (ex.mediaUrl != null &&
                                                ex.mediaUrl!.isNotEmpty)
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusLG,
                                                  ),
                                              child: CachedNetworkImage(
                                                imageUrl: Cloudinary.thumbnail(ex.mediaUrl!),
                                                fit: BoxFit.cover,
                                                width: 56,
                                                height: 56,
                                                placeholder: (_, _) =>
                                                    Container(
                                                      color: AppColors.surfaceLight,
                                                    ),
                                                errorWidget: (_, _, _) =>
                                                    const Center(
                                                      child: Icon(
                                                        Icons.fitness_center,
                                                        color: AppColors.labelSecondary,
                                                      ),
                                                    ),
                                              ),
                                            )
                                          : const Center(
                                              child: Icon(
                                                Icons.fitness_center,
                                                color: AppColors.primary,
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
                                              color: AppColors.labelPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 17,
                                              letterSpacing: -0.1,
                                            ),
                                          ),

                                          Text(
                                            ex.grupoMuscular.join(' • '),
                                            style: const TextStyle(
                                              color: AppColors.labelSecondary,
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
                                                  ? AppColors.primary
                                                  : AppColors.labelSecondary
                                                        .withAlpha(50),
                                              width: 2,
                                            ),
                                            color: isSelected
                                                ? AppColors.primary
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
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(
                  color: Colors.white.withAlpha(20),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
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
                        splashColor: AppColors.primary.withAlpha(
                          30,
                        ),
                        highlightColor: AppColors.primary.withAlpha(
                          20,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.space8),
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceLight,
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
                                color: AppColors.labelSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: AppColors.labelSecondary,
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
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.space12,
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                      icon: const Icon(
                        Icons.check,
                        size: 20,
                        color: Colors.black,
                      ),
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