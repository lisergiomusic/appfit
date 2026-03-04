import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/rotina_service.dart';
import 'configurar_exercicios_page.dart';
import 'models/exercicio_model.dart';

// Modelo local para gerir as sessões durante a edição
class _TreinoData {
  String nome;
  String? diaSemana;
  String? orientacoes;
  List<ExercicioItem> exercicios;

  _TreinoData({
    required this.nome,
    this.diaSemana,
    this.orientacoes,
    List<ExercicioItem>? exercicios,
  }) : exercicios = exercicios ?? [];
}

class RotinaDetalhePage extends StatefulWidget {
  final Map<String, dynamic>? rotinaData; // Nulo se for nova rotina!
  final String? rotinaId;
  final String? alunoId;
  final String? alunoNome;

  const RotinaDetalhePage({
    super.key,
    this.rotinaData,
    this.rotinaId,
    this.alunoId,
    this.alunoNome,
  });

  @override
  State<RotinaDetalhePage> createState() => _RotinaDetalhePageState();
}

class _RotinaDetalhePageState extends State<RotinaDetalhePage> {
  // --- ESTADO GERAL DA ROTINA ---
  String _nome = '';
  String _objetivo = '';
  int _duracaoSemanas = 4;
  List<_TreinoData> _treinos = [];

  bool _isReordering = false;
  bool _isLoading = false;
  bool _foiModificado = false; // Controla se o botão de Salvar aparece

  @override
  void initState() {
    super.initState();
    _preencherDados();
  }

  void _preencherDados() {
    if (widget.rotinaData != null) {
      _nome = widget.rotinaData!['nome'] ?? '';
      _objetivo = widget.rotinaData!['objetivo'] ?? '';

      if (widget.rotinaData!['dataCriacao'] != null &&
          widget.rotinaData!['dataVencimento'] != null) {
        DateTime criacao = (widget.rotinaData!['dataCriacao'] as Timestamp)
            .toDate();
        DateTime vencimento =
            (widget.rotinaData!['dataVencimento'] as Timestamp).toDate();
        int dias = vencimento.difference(criacao).inDays;
        if (dias > 0) _duracaoSemanas = (dias / 7).round();
      }

      List<dynamic> sessoesRaw = widget.rotinaData!['sessoes'] ?? [];
      for (var sessao in sessoesRaw) {
        List<ExercicioItem> exerciciosList = [];
        for (var ex in (sessao['exercicios'] ?? [])) {
          List<SerieItem> seriesList = [];
          for (var s in (ex['series'] ?? [])) {
            seriesList.add(
              SerieItem(
                tipo: _parseTipoSerie(s['tipo']),
                alvo: s['alvo'] ?? '10',
                carga: s['carga'] ?? '-',
                descanso: s['descanso'] ?? '60s',
              ),
            );
          }
          exerciciosList.add(
            ExercicioItem(
              nome: ex['nome'] ?? 'Exercício',
              grupoMuscular: ex['grupoMuscular'] ?? '',
              observacao: ex['observacao'] ?? '',
              tipoAlvo: ex['tipoAlvo'] ?? 'Reps',
              imagemUrl: ex['imagemUrl'],
              series: seriesList,
            ),
          );
        }
        _treinos.add(
          _TreinoData(
            nome: sessao['nome'],
            diaSemana: sessao['diaSemana'],
            orientacoes: sessao['orientacoes'],
            exercicios: exerciciosList,
          ),
        );
      }
    } else {
      // Se for uma rotina nova, abre logo o modal de informações no início
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _exibirModalInfo(context);
      });
    }
  }

  TipoSerie _parseTipoSerie(String? tipo) {
    if (tipo == 'aquecimento' || tipo == 'TipoSerie.aquecimento') {
      return TipoSerie.aquecimento;
    }
    if (tipo == 'feeder' || tipo == 'TipoSerie.feeder') return TipoSerie.feeder;
    return TipoSerie.trabalho;
  }

  // --- WIDGET AUXILIAR PARA INPUTS (APPLE NATIVE) ---
  Widget _buildModernInput({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 0, bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }

  // --- BUILD CUSTOM INPUT DECORATION (APPLE NATIVE) ---
  InputDecoration _buildInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppTheme.textSecondary.withAlpha(80),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white.withAlpha(8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withAlpha(20), width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withAlpha(20), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: AppTheme.primary.withAlpha(150),
          width: 1,
        ),
      ),
    );
  }

  // --- MODAL PARA EDITAR CABEÇALHO (REFINADO) ---
  void _exibirModalInfo(BuildContext context) {
    final nomeCtrl = TextEditingController(text: _nome);
    final objCtrl = TextEditingController(text: _objetivo);
    int semanasSelecionadas = _duracaoSemanas;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HANDLE DE ARRASTAR
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

              const Text(
                'Configurar Rotina',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 28),

              _buildModernInput(
                label: 'NOME DA ROTINA',
                icon: Icons.title,
                child: TextField(
                  controller: nomeCtrl,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.3,
                  ),
                  decoration: _buildInputDecoration(
                    hintText: 'Ex: Projeto Hipertrofia Mês 1',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildModernInput(
                label: 'OBJETIVO PRINCIPAL',
                icon: Icons.track_changes,
                child: TextField(
                  controller: objCtrl,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.3,
                  ),
                  decoration: _buildInputDecoration(
                    hintText: 'Ex: Ganho de massa e força',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildModernInput(
                label: 'DURAÇÃO PLANEJADA',
                icon: Icons.schedule,
                child: DropdownButtonFormField<int>(
                  value: semanasSelecionadas,
                  dropdownColor: AppTheme.surfaceLight,
                  icon: Icon(
                    Icons.expand_more_rounded,
                    color: AppTheme.primary.withAlpha(150),
                    size: 18,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  items: [4, 5, 6, 8, 10, 12]
                      .map(
                        (w) => DropdownMenuItem(
                          value: w,
                          child: Text('$w semanas'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setStateModal(() => semanasSelecionadas = v!),
                  decoration: _buildInputDecoration(
                    hintText: 'Escolha a duração',
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _nome = nomeCtrl.text.trim();
                    _objetivo = objCtrl.text.trim();
                    _duracaoSemanas = semanasSelecionadas;
                    _foiModificado = true;
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Text(
                  'Concluir',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODAL PARA ADICIONAR/EDITAR SESSÃO (REFINADO) ---
  void _exibirModalSessao({int? index}) {
    final bool isEditing = index != null;
    final nomeCtrl = TextEditingController(
      text: isEditing ? _treinos[index].nome : null,
    );
    String? diaSemana = isEditing ? _treinos[index].diaSemana : null;
    final orientCtrl = TextEditingController(
      text: isEditing ? _treinos[index].orientacoes : null,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 12,
        ),
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

            Text(
              isEditing ? 'Editar Sessão' : 'Nova Sessão',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 28),

            _buildModernInput(
              label: 'NOME DO TREINO',
              icon: Icons.fitness_center,
              child: TextField(
                controller: nomeCtrl,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.3,
                ),
                decoration: _buildInputDecoration(
                  hintText: 'Ex: Push, Pull, Costas...',
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildModernInput(
              label: 'DIA DA SEMANA (OPCIONAL)',
              icon: Icons.calendar_today,
              child: DropdownButtonFormField<String>(
                initialValue: diaSemana,
                dropdownColor: AppTheme.surfaceLight,
                icon: Icon(
                  Icons.expand_more_rounded,
                  color: AppTheme.primary.withAlpha(150),
                  size: 18,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                items:
                    <String>[
                          'Segunda',
                          'Terça',
                          'Quarta',
                          'Quinta',
                          'Sexta',
                          'Sábado',
                          'Domingo',
                        ]
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                onChanged: (v) => diaSemana = v,
                decoration: _buildInputDecoration(hintText: 'Sem dia fixo'),
              ),
            ),
            const SizedBox(height: 24),

            _buildModernInput(
              label: 'NOTAS GERAIS DA SESSÃO',
              icon: Icons.notes,
              child: TextField(
                controller: orientCtrl,
                maxLines: 3,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                decoration: _buildInputDecoration(
                  hintText: 'Ex: Aquecer manguito rotador antes...',
                ),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                final newName = nomeCtrl.text.trim().isEmpty
                    ? 'Treino ${String.fromCharCode(65 + _treinos.length)}'
                    : nomeCtrl.text.trim();
                setState(() {
                  if (isEditing) {
                    _treinos[index].nome = newName;
                    _treinos[index].diaSemana = diaSemana;
                    _treinos[index].orientacoes = orientCtrl.text.trim();
                  } else {
                    _treinos.add(
                      _TreinoData(
                        nome: newName,
                        diaSemana: diaSemana,
                        orientacoes: orientCtrl.text.trim(),
                      ),
                    );
                  }
                  _foiModificado = true;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: Text(
                isEditing ? 'Salvar' : 'Adicionar',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _excluirTreino(int index) {
    setState(() {
      _treinos.removeAt(index);
      _foiModificado = true;
    });
  }

  // --- SALVAR TUDO NO FIREBASE ---
  Future<void> _salvarRotinaCompleta() async {
    if (_nome.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dê um nome à rotina!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_treinos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos uma sessão!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> sessoesJson = _treinos
          .map(
            (t) => {
              'nome': t.nome,
              'diaSemana': t.diaSemana,
              'orientacoes': t.orientacoes,
              'exercicios': t.exercicios
                  .map(
                    (ex) => {
                      'nome': ex.nome,
                      'grupoMuscular': ex.grupoMuscular,
                      'observacao': ex.observacao,
                      'tipoAlvo': ex.tipoAlvo,
                      'imagemUrl': ex.imagemUrl,
                      'series': ex.series
                          .map(
                            (s) => {
                              'tipo': s.tipo.name,
                              'alvo': s.alvo,
                              'carga': s.carga,
                              'descanso': s.descanso,
                            },
                          )
                          .toList(),
                    },
                  )
                  .toList(),
            },
          )
          .toList();

      if (widget.rotinaId != null) {
        await RotinaService().atualizarRotina(
          rotinaId: widget.rotinaId!,
          nome: _nome,
          objetivo: _objetivo,
          sessoes: sessoesJson,
          duracaoDias: _duracaoSemanas * 7,
          dataCriacaoOriginal: widget.rotinaData?['dataCriacao'] as Timestamp?,
        );
      } else {
        await RotinaService().criarRotina(
          alunoId: widget.alunoId,
          nome: _nome,
          objetivo: _objetivo,
          sessoes: sessoesJson,
          duracaoDias: _duracaoSemanas * 7,
        );
      }

      setState(() => _foiModificado = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rotina salva com sucesso!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTemplate =
        widget.rotinaData != null && widget.rotinaData!['alunoId'] == null;

    return WillPopScope(
      onWillPop: () async {
        if (!_foiModificado) return true;
        final sair = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text(
              'Descartar alterações?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Você fez mudanças nesta rotina. Se voltar agora, elas não serão salvas no banco de dados.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Ficar',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
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
        // --- NOVO APPLE LARGE TITLE COM CUSTOM SCROLL VIEW ---
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar.large(
              backgroundColor: AppTheme.background,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              leadingWidth: 60,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: AppTheme.primary,
                ),
                onPressed: () {
                  if (!_foiModificado) {
                    Navigator.pop(context);
                  } else {
                    showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppTheme.surfaceDark,
                        title: const Text(
                          'Descartar alterações?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: const Text(
                          'Você fez mudanças nesta rotina. Se voltar agora, elas não serão salvas no banco de dados.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'Ficar',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                              Navigator.pop(context);
                            },
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
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => _exibirModalInfo(context),
                  child: const Text(
                    'Editar',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              title: Text(
                _nome.isEmpty ? 'Nova Rotina' : _nome,
                style: const TextStyle(
                  fontFamily: '.SF UI Display',
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),

            // O Resto da tela
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _objetivo.isEmpty ? 'Defina o objetivo' : _objetivo,
                      style: TextStyle(
                        color: AppTheme.textSecondary.withAlpha(180),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppTheme.textSecondary.withAlpha(150),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_duracaoSemanas semanas',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withAlpha(150),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    isTemplate
                        ? _buildTemplateBadge()
                        : const SizedBox.shrink(),
                    isTemplate
                        ? const SizedBox(height: 24)
                        : const SizedBox.shrink(),

                    // --- CABEÇALHO DA LISTA DE SESSÕES ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sessões',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (_treinos.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              if (_treinos.length > 1) {
                                setState(() => _isReordering = !_isReordering);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Precisas de pelo menos 2 sessões para reordenar.',
                                    ),
                                    backgroundColor: AppTheme.surfaceLight,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _isReordering
                                    ? AppTheme.primary.withAlpha(30)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isReordering
                                        ? Icons.check_rounded
                                        : Icons.swap_vert_outlined,
                                    size: 16,
                                    color: _isReordering
                                        ? AppTheme.primary
                                        : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isReordering ? 'Concluir' : 'Reordenar',
                                    style: TextStyle(
                                      color: _isReordering
                                          ? AppTheme.primary
                                          : AppTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_treinos.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          child: Column(
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 60,
                                color: Colors.white.withAlpha(20),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhuma sessão',
                                style: TextStyle(
                                  color: AppTheme.textSecondary.withAlpha(180),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_isReordering)
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: _treinos.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = _treinos.removeAt(oldIndex);
                            _treinos.insert(newIndex, item);
                            _foiModificado = true;
                          });
                        },
                        proxyDecorator: (child, index, animation) {
                          return Transform.scale(
                            scale: 1.0,
                            child: Material(
                              elevation: 0,
                              color: Colors.transparent,
                              child: child,
                            ),
                          );
                        },
                        itemBuilder: (context, index) {
                          var sessao = _treinos[index];
                          return Container(
                            key: ValueKey(sessao),
                            child: _buildSessaoCard(
                              sessao,
                              index,
                              isReordering: true,
                            ),
                          );
                        },
                      )
                    else
                      ..._treinos.asMap().entries.map(
                        (entry) => _buildSessaoCard(
                          entry.value,
                          entry.key,
                          isReordering: false,
                        ),
                      ),

                    const SizedBox(height: 8),

                    if (!_isReordering) _buildAddSessaoButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: (_foiModificado || widget.rotinaId == null)
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _salvarRotinaCompleta,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34C759),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              26,
                            ), // Pílula Perfeita
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                _isLoading ? 'Salvando...' : 'Salvar',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  // BOTÃO ADICIONAR SESSÃO - REFINADO (OUTLINE PILL)
  Widget _buildAddSessaoButton() {
    return InkWell(
      onTap: () => _exibirModalSessao(),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primary.withAlpha(120),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Nova Sessão',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(24), // Ajustado para Pill Style
        border: Border.all(color: AppTheme.primary.withAlpha(30)),
      ),
      child: const Row(
        children: [
          Icon(Icons.collections_bookmark, color: AppTheme.primary, size: 18),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Template de Biblioteca',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Sem data de vencimento até ser atribuído.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessaoCard(
    _TreinoData sessao,
    int index, {
    required bool isReordering,
  }) {
    String letra = String.fromCharCode(65 + index);

    // Widget que contém o conteúdo do card
    final cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24), // Pill Style
        border: Border.all(color: Colors.white.withAlpha(15), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              shape: BoxShape.circle, // Avatar agora é 100% redondo
            ),
            child: Center(
              child: Text(
                letra,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sessao.nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${sessao.exercicios.length} ${sessao.exercicios.length == 1 ? 'exercício' : 'exercícios'}${sessao.diaSemana != null ? ' • ${sessao.diaSemana}' : ''}',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withAlpha(180),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: isReordering
                ? ReorderableDragStartListener(
                    index: index,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.drag_indicator, // Ícone elegante de drag
                        color: AppTheme.textSecondary.withAlpha(80),
                        size: 20,
                      ),
                    ),
                  )
                : PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    color: AppTheme.surfaceLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    position: PopupMenuPosition.under,
                    icon: Icon(
                      Icons.chevron_right,
                      color: AppTheme.textSecondary.withAlpha(100),
                      size: 22,
                    ),
                    onSelected: (value) {
                      if (value == 'edit') _exibirModalSessao(index: index);
                      if (value == 'delete') _excluirTreino(index);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: AppTheme.textSecondary.withAlpha(200),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Editar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
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
                              'Excluir',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
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

    return isReordering
        ? Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: cardContent,
          )
        : Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () async {
                final String? novoNomeTreino = await Navigator.push<String?>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConfigurarExerciciosPage(
                      nomeTreino: sessao.nome,
                      exercicios: sessao.exercicios,
                    ),
                  ),
                );
                if (!mounted) return;
                setState(() {
                  _foiModificado = true;
                  final novoNomeTrim = novoNomeTreino?.trim() ?? '';
                  if (novoNomeTrim.isNotEmpty && novoNomeTrim != sessao.nome) {
                    sessao.nome = novoNomeTrim;
                  }
                });
              },
              borderRadius: BorderRadius.circular(24), // Pill Style
              child: cardContent,
            ),
          );
  }
}
