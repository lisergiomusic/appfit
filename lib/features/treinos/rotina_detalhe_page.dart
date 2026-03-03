import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import 'criar_rotina_page.dart';

class RotinaDetalhePage extends StatefulWidget {
  final Map<String, dynamic> rotinaData;
  final String? rotinaId;
  final String? alunoId;
  final String? alunoNome;

  const RotinaDetalhePage({
    super.key,
    required this.rotinaData,
    this.rotinaId,
    this.alunoId,
    this.alunoNome,
  });

  @override
  State<RotinaDetalhePage> createState() => _RotinaDetalhePageState();
}

class _RotinaDetalhePageState extends State<RotinaDetalhePage> {
  // --- CONTROLE DE ESTADO LOCAL ---
  late Map<String, dynamic> _rotinaDataLocal;
  late List<dynamic> _sessoes;
  bool _isReordering = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inicializa a variável local com os dados originais passados na navegação
    _rotinaDataLocal = Map<String, dynamic>.from(widget.rotinaData);
    _sessoes = List.from(_rotinaDataLocal['sessoes'] ?? []);
  }

  // --- BUSCA DADOS FRESCOS NO FIREBASE APÓS FECHAR A TELA DE EDIÇÃO ---
  Future<void> _recarregarDados() async {
    if (widget.rotinaId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('rotinas')
          .doc(widget.rotinaId)
          .get();
      if (doc.exists && doc.data() != null && mounted) {
        setState(() {
          _rotinaDataLocal = doc.data() as Map<String, dynamic>;
          // Só atualizamos a lista de sessões se não estivermos no meio de um arrastar-e-soltar
          if (!_isReordering) {
            _sessoes = List.from(_rotinaDataLocal['sessoes'] ?? []);
          }
        });
      }
    } catch (e) {
      debugPrint('Erro ao recarregar rotina: $e');
    }
  }

  // --- ATALHO CENTRALIZADO PARA EDIÇÃO (AGORA É ASSÍNCRONO!) ---
  Future<void> _navegarParaEdicao(BuildContext context) async {
    if (widget.rotinaId == null) return;

    // O comando await faz o código pausar aqui até a tela de edição ser fechada
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CriarRotinaPage(
          rotinaId: widget.rotinaId,
          rotinaData:
              _rotinaDataLocal, // Passamos sempre os dados mais recentes
          alunoId: widget.alunoId,
          alunoNome: widget.alunoNome,
        ),
      ),
    );

    // Quando a tela de edição fechar, a execução continua e disparamos o reload
    _recarregarDados();
  }

  // --- FUNÇÃO PARA SALVAR A NOVA ORDEM NO FIREBASE ---
  Future<void> _salvarNovaOrdem() async {
    if (widget.rotinaId == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('rotinas')
          .doc(widget.rotinaId)
          .update({'sessoes': _sessoes});

      // Atualiza a fonte de dados local para manter a consistência
      _rotinaDataLocal['sessoes'] = List.from(_sessoes);

      setState(() {
        _isReordering = false;
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ordem atualizada com sucesso!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar ordem: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // AGORA LÊ SEMPRE DO ESTADO LOCAL, E NÃO DO WIDGET ORIGINAL
    final titulo = _rotinaDataLocal['nome'] ?? 'Rotina';
    final objetivo = _rotinaDataLocal['objetivo'] ?? 'Sem objetivo definido';
    final bool isTemplate = _rotinaDataLocal['alunoId'] == null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Visão Geral', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        actions: [
          if (widget.rotinaId != null && !_isReordering)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
              tooltip: 'Editar Rotina',
              onPressed: () => _navegarParaEdicao(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              objetivo,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 32),

            isTemplate ? _buildTemplateBadge() : const SizedBox.shrink(),
            isTemplate ? const SizedBox(height: 24) : const SizedBox.shrink(),

            // --- AÇÕES RÁPIDAS (MODO NORMAL VS MODO REORDENAÇÃO) ---
            if (widget.rotinaId != null) ...[
              if (_isReordering) ...[
                // BOTÕES DURANTE A REORDENAÇÃO
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          // Cancela e reverte para a ordem original do estado local
                          setState(() {
                            _sessoes = List.from(
                              _rotinaDataLocal['sessoes'] ?? [],
                            );
                            _isReordering = false;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withAlpha(30),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _isLoading ? null : _salvarNovaOrdem,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.success.withAlpha(100),
                            ),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      color: AppTheme.success,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Salvar Ordem',
                                    style: TextStyle(
                                      color: AppTheme.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // BOTÕES NORMAIS (ADICIONAR / REORDENAR)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _navegarParaEdicao(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primary.withAlpha(50),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: AppTheme.primary,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Adicionar',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (_sessoes.length > 1) {
                            setState(() => _isReordering = true);
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
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withAlpha(20),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.swap_vert,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Reordenar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
            ],

            // 4. LISTA DE SESSÕES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SESSÕES DE TREINO',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                if (_isReordering)
                  const Text(
                    'Arraste para mover',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (_sessoes.isEmpty)
              const Text(
                'Nenhuma sessão cadastrada.',
                style: TextStyle(color: AppTheme.textSecondary),
              )
            else if (_isReordering)
              // MODO REORDENAÇÃO (ARRASTÁVEL)
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _sessoes.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _sessoes.removeAt(oldIndex);
                    _sessoes.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  var sessao = _sessoes[index];
                  String letra = String.fromCharCode(65 + index);
                  return Container(
                    key: ValueKey(sessao),
                    child: _buildSessaoCard(
                      context,
                      sessao,
                      letra,
                      isReordering: true,
                      index: index,
                    ),
                  );
                },
              )
            else
              // MODO NORMAL (SOMENTE LEITURA)
              ..._sessoes.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> sessao =
                    entry.value as Map<String, dynamic>;
                String letra = String.fromCharCode(65 + index);
                return _buildSessaoCard(
                  context,
                  sessao,
                  letra,
                  isReordering: false,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.collections_bookmark,
            color: AppTheme.primary.withAlpha(200),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Template de Biblioteca',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Este treino não tem data de vencimento até ser atribuído a um aluno.',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withAlpha(200),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessaoCard(
    BuildContext context,
    Map<String, dynamic> sessao,
    String letra, {
    required bool isReordering,
    int? index,
  }) {
    List<dynamic> exercicios = sessao['exercicios'] ?? [];
    String nomeSessao = sessao['nome'] ?? 'Sessão $letra';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: isReordering
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SessaoVisualizerPage(sessaoData: sessao, letra: letra),
                  ),
                );
              },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isReordering
                ? AppTheme.surfaceLight.withAlpha(100)
                : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isReordering
                  ? AppTheme.primary.withAlpha(80)
                  : Colors.white.withAlpha(13),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    letra,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
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
                      nomeSessao,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercicios.length} exercícios',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isReordering && index != null)
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.transparent,
                    child: const Icon(
                      Icons.drag_indicator,
                      color: AppTheme.primary,
                      size: 28,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary.withAlpha(150),
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================
// --- TELA: VISUALIZADOR DE SESSÃO (READ-ONLY) ---
// ==============================================================
class SessaoVisualizerPage extends StatelessWidget {
  final Map<String, dynamic> sessaoData;
  final String letra;

  const SessaoVisualizerPage({
    super.key,
    required this.sessaoData,
    required this.letra,
  });

  @override
  Widget build(BuildContext context) {
    String nomeSessao = sessaoData['nome'] ?? 'Treino $letra';
    List<dynamic> exercicios = sessaoData['exercicios'] ?? [];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          nomeSessao,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: exercicios.isEmpty
          ? const Center(
              child: Text(
                'Nenhum exercício nesta sessão.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exercicios.length,
              itemBuilder: (context, index) {
                var ex = exercicios[index];
                return _buildExercicioVisualizerCard(ex);
              },
            ),
    );
  }

  Widget _buildExercicioVisualizerCard(Map<String, dynamic> ex) {
    List<dynamic> series = ex['series'] ?? [];
    String tipoAlvo = ex['tipoAlvo'] ?? 'Reps';

    final aquecimentoSeries = series
        .where((s) => s['tipo'] == 'aquecimento')
        .toList();
    final feederSeries = series.where((s) => s['tipo'] == 'feeder').toList();
    final trabalhoSeries = series
        .where((s) => s['tipo'] == 'trabalho')
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        color: AppTheme.textSecondary.withAlpha(100),
                        size: 28,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(100),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex['nome'] ?? 'Exercício',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ex['grupoMuscular'] ?? '',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (ex['observacao'] != null &&
              ex['observacao'].toString().trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
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
                child: Text(
                  ex['observacao'],
                  style: TextStyle(
                    color: AppTheme.textSecondary.withAlpha(220),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          if (series.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 36,
                        child: Text(
                          'Série',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tipoAlvo,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
                            fontSize: 12,
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (aquecimentoSeries.isNotEmpty) ...[
                    _buildSectionTitle('Aquecimento', Colors.amber),
                    ...aquecimentoSeries.asMap().entries.map(
                      (entry) =>
                          _buildSerieReadOnlyRow(entry.value, entry.key + 1),
                    ),
                  ],
                  if (feederSeries.isNotEmpty) ...[
                    _buildSectionTitle('Feeder Sets', Colors.blueAccent),
                    ...feederSeries.asMap().entries.map(
                      (entry) =>
                          _buildSerieReadOnlyRow(entry.value, entry.key + 1),
                    ),
                  ],
                  if (trabalhoSeries.isNotEmpty) ...[
                    _buildSectionTitle(
                      'Séries de Trabalho',
                      AppTheme.textSecondary,
                    ),
                    ...trabalhoSeries.asMap().entries.map(
                      (entry) =>
                          _buildSerieReadOnlyRow(entry.value, entry.key + 1),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.subdirectory_arrow_right,
            size: 14,
            color: color.withAlpha(200),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color.withAlpha(200),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerieReadOnlyRow(Map<String, dynamic> serie, int visualNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 28,
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
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildReadonlyBox(serie['alvo'] ?? '-')),
          const SizedBox(width: 8),
          Expanded(child: _buildReadonlyBox(serie['carga'] ?? '-')),
          const SizedBox(width: 8),
          Expanded(child: _buildReadonlyBox(serie['descanso'] ?? '-')),
        ],
      ),
    );
  }

  Widget _buildReadonlyBox(String text) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
