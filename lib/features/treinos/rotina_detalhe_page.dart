import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/rotina_service.dart';
import 'configurar_exercicios_page.dart';

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
    if (tipo == 'aquecimento' || tipo == 'TipoSerie.aquecimento')
      return TipoSerie.aquecimento;
    if (tipo == 'feeder' || tipo == 'TipoSerie.feeder') return TipoSerie.feeder;
    return TipoSerie.trabalho;
  }

  // --- MODAL PARA EDITAR CABEÇALHO ---
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
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Informações da Rotina',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nomeCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nome da Rotina',
                  hintText: 'Ex: Projeto Hipertrofia Mês 1',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: objCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Objetivo Principal',
                  hintText: 'Ex: Ganho de massa e força',
                  prefixIcon: Icon(Icons.track_changes),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: semanasSelecionadas,
                dropdownColor: AppTheme.surfaceLight,
                style: const TextStyle(color: Colors.white),
                items: [4, 5, 6, 8, 10, 12]
                    .map(
                      (w) =>
                          DropdownMenuItem(value: w, child: Text('$w semanas')),
                    )
                    .toList(),
                onChanged: (v) => setStateModal(() => semanasSelecionadas = v!),
                decoration: const InputDecoration(
                  labelText: 'Duração da Rotina',
                  prefixIcon: Icon(Icons.date_range),
                ),
              ),
              const SizedBox(height: 24),
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
                child: const Text('Concluir'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODAL PARA ADICIONAR/EDITAR SESSÃO ---
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
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Editar Sessão' : 'Nova Sessão de Treino',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nomeCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Ex: Treino A - Costas e Bíceps',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: diaSemana,
              dropdownColor: AppTheme.surfaceLight,
              style: const TextStyle(color: Colors.white),
              items: <String>[
                'Segunda',
                'Terça',
                'Quarta',
                'Quinta',
                'Sexta',
                'Sábado',
                'Domingo',
              ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => diaSemana = v,
              decoration: const InputDecoration(
                labelText: 'Dia da semana (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: orientCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Orientações gerais (opcional)',
              ),
            ),
            const SizedBox(height: 24),
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
              child: Text(isEditing ? 'Salvar Sessão' : 'Adicionar Sessão'),
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            widget.rotinaId == null ? 'Nova Rotina' : 'Visão Geral',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          elevation: 0,
        ),

        // --- NOVO FAB FLUTUANTE (PREMIUM E COMPACTO) ---
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: (_foiModificado || widget.rotinaId == null)
            ? FloatingActionButton.extended(
                onPressed: _isLoading ? null : _salvarRotinaCompleta,
                backgroundColor: AppTheme.success,
                elevation: 4,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check, color: Colors.white, size: 20),
                label: Text(
                  _isLoading ? 'Salvando...' : 'Salvar Alterações',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              )
            : null,

        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER DA ROTINA (MAIS DENSO E ELEGANTE) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nome.isEmpty ? 'Defina um Nome' : _nome,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _nome.isEmpty
                                ? AppTheme.textSecondary
                                : Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _objetivo.isEmpty
                              ? 'Toque no lápis para adicionar um objetivo'
                              : _objetivo,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_duracaoSemanas semanas',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppTheme.textSecondary,
                      size: 22,
                    ),
                    onPressed: () => _exibirModalInfo(context),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              isTemplate ? _buildTemplateBadge() : const SizedBox.shrink(),
              isTemplate ? const SizedBox(height: 24) : const SizedBox.shrink(),

              // --- CABEÇALHO DA LISTA DE SESSÕES ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SESSÕES DE TREINO',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.5,
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
                          borderRadius: BorderRadius.circular(8),
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Nenhuma sessão cadastrada. Adicione uma sessão abaixo para começar.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
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

              // --- BOTÃO ADICIONAR "FANTASMA" (FINO E ELEGANTE) ---
              if (!_isReordering) _buildAddSessaoButton(),

              // Espaço extra no fundo para o botão FAB flutuante não cobrir o último item
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // BOTÃO FANTASMA SUTIL
  Widget _buildAddSessaoButton() {
    return InkWell(
      onTap: () => _exibirModalSessao(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withAlpha(50), width: 1.0),
          color: Colors
              .transparent, // Fundo invisível para não competir com os cards reais
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: AppTheme.primary, size: 18),
            SizedBox(width: 8),
            Text(
              'Nova Sessão',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
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
        borderRadius: BorderRadius.circular(12),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isReordering
            ? null
            : () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConfigurarExerciciosPage(
                      nomeTreino: sessao.nome,
                      exercicios: sessao.exercicios,
                    ),
                  ),
                );
                setState(() => _foiModificado = true);
              },
        borderRadius: BorderRadius.circular(12), // Mais sutil
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ), // Reduzido
          decoration: BoxDecoration(
            color: isReordering
                ? AppTheme.surfaceLight.withAlpha(80)
                : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isReordering
                  ? AppTheme.primary.withAlpha(80)
                  : Colors.white.withAlpha(10),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36, // Reduzido, mais circular
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  shape: BoxShape
                      .circle, // Ficou redondo (premium) em vez de quadrado!
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
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${sessao.exercicios.length} exercícios',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isReordering)
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.transparent,
                    child: const Icon(
                      Icons.drag_indicator,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                )
              else ...[
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  color: AppTheme.surfaceLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') _exibirModalSessao(index: index);
                    if (value == 'delete') _excluirTreino(index);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Editar Título',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Excluir Sessão',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
