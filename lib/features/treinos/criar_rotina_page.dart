import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/rotina_service.dart';
import 'configurar_exercicios_page.dart';

class _TreinoData {
  final TextEditingController nomeController;
  String? diaSemana;
  String? orientacoes;
  List<ExercicioItem> exercicios;

  _TreinoData({
    required this.nomeController,
    this.diaSemana,
    this.orientacoes,
    List<ExercicioItem>? exercicios,
  }) : exercicios = exercicios ?? [];
}

class CriarRotinaPage extends StatefulWidget {
  final String? alunoId;
  final String? alunoNome;

  const CriarRotinaPage({super.key, this.alunoId, this.alunoNome});

  @override
  State<CriarRotinaPage> createState() => _CriarRotinaPageState();
}

class _CriarRotinaPageState extends State<CriarRotinaPage> {
  final _nomeController = TextEditingController();
  final _objetivoController = TextEditingController();

  int _duracaoSemanas = 4; // <-- NOVO: Controle de Duração
  final List<_TreinoData> _treinos = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _objetivoController.dispose();
    for (var t in _treinos) {
      t.nomeController.dispose();
    }
    super.dispose();
  }

  Future<Map<String, String?>?> _showTreinoForm({
    String? initialNome,
    String? initialDia,
    String? initialOrient,
  }) {
    final nomeCtr = TextEditingController(text: initialNome);
    String? diaSemana = initialDia;
    final orientacoesCtr = TextEditingController(text: initialOrient);

    return showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
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
                initialNome == null ? 'Nova Sessão de Treino' : 'Editar Sessão',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nomeCtr,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Ex: Treino A - Costas e Bíceps',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary.withAlpha(128),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: diaSemana,
                dropdownColor: AppTheme.surfaceLight,
                style: const TextStyle(color: Colors.white),
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
                decoration: InputDecoration(
                  labelText: 'Dia da semana (opcional)',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: orientacoesCtr,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Orientações gerais',
                  hintText: 'Ex: Foco no tempo sob tensão...',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary.withAlpha(128),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'nome': nomeCtr.text,
                        'diaSemana': diaSemana,
                        'orientacoes': orientacoesCtr.text,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      initialNome == null ? 'Adicionar' : 'Salvar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editarTreino(int index) async {
    final current = _treinos[index];
    final result = await _showTreinoForm(
      initialNome: current.nomeController.text,
      initialDia: current.diaSemana,
      initialOrient: current.orientacoes,
    );
    if (result != null) {
      setState(() {
        current.nomeController.text =
            result['nome'] ?? current.nomeController.text;
        current.diaSemana = result['diaSemana'];
        current.orientacoes = result['orientacoes'];
      });
    }
  }

  void _excluirTreino(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Excluir sessão?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Tem certeza que deseja remover esta sessão e todos os exercícios nela configurados?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _treinos.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text(
              'Excluir',
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

  Future<void> _adicionarTreino() async {
    final result = await _showTreinoForm();
    if (result != null) {
      final name = (result['nome']?.isEmpty ?? true)
          ? 'Treino ${String.fromCharCode(65 + _treinos.length)}'
          : result['nome']!;
      setState(() {
        _treinos.add(
          _TreinoData(
            nomeController: TextEditingController(text: name),
            diaSemana: result['diaSemana'],
            orientacoes: result['orientacoes'],
            exercicios: [],
          ),
        );
      });
    }
  }

  Future<void> _salvarRotina() async {
    if (_nomeController.text.trim().isEmpty) {
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
          content: Text('Adicione pelo menos uma sessão de treino!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> sessoesJson = _treinos.map((treino) {
        return {
          'nome': treino.nomeController.text.trim(),
          'diaSemana': treino.diaSemana,
          'orientacoes': treino.orientacoes,
          'exercicios': treino.exercicios.map((ex) {
            return {
              'nome': ex.nome,
              'grupoMuscular': ex.grupoMuscular,
              'observacao': ex.observacao,
              'tipoAlvo': ex.tipoAlvo,
              'imagemUrl': ex.imagemUrl,
              'series': ex.series.map((serie) {
                return {
                  'tipo': serie.tipo.name,
                  'alvo': serie.alvo,
                  'carga': serie.carga,
                  'descanso': serie.descanso,
                };
              }).toList(),
            };
          }).toList(),
        };
      }).toList();

      await RotinaService().criarRotina(
        alunoId: widget.alunoId,
        nome: _nomeController.text.trim(),
        objetivo: _objetivoController.text.trim(),
        sessoes: sessoesJson,
        duracaoDias:
            _duracaoSemanas * 7, // <-- Passa a duração exata para o backend!
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rotina salva com sucesso!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Nova Rotina',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.alunoNome != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withAlpha(77)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Criando para: ${widget.alunoNome}',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text(
              'INFORMAÇÕES BÁSICAS',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _nomeController,
              label: 'Nome da Rotina',
              hint: 'Ex: Projeto Hipertrofia Mês 1',
              icon: Icons.title,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _objetivoController,
              label: 'Objetivo Principal',
              hint: 'Ex: Ganho de massa e força',
              icon: Icons.track_changes,
            ),
            const SizedBox(height: 16),

            // <-- NOVO: DROPDOWN DE DURAÇÃO -->
            DropdownButtonFormField<int>(
              value: _duracaoSemanas,
              dropdownColor: AppTheme.surfaceLight,
              style: const TextStyle(color: Colors.white),
              items: [4, 5, 6, 8, 10, 12]
                  .map(
                    (w) =>
                        DropdownMenuItem(value: w, child: Text('$w semanas')),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _duracaoSemanas = v!),
              decoration: InputDecoration(
                labelText: 'Duração da Rotina',
                prefixIcon: const Icon(
                  Icons.date_range,
                  color: AppTheme.textSecondary,
                ),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DIVISÃO DE TREINOS',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  '${_treinos.length} sessões',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_treinos.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(40),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(10)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 48,
                      color: AppTheme.textSecondary.withAlpha(100),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhuma sessão adicionada',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Clique em "Adicionar nova sessão" para começar.',
                      style: TextStyle(
                        color: AppTheme.textSecondary.withAlpha(150),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (BuildContext context, Widget? child) {
                      final double animValue = Curves.easeInOut.transform(
                        animation.value,
                      );
                      final double elevation = lerpDouble(0, 6, animValue)!;
                      return Material(
                        elevation: elevation,
                        color: Colors.transparent,
                        shadowColor: Colors.black.withAlpha(100),
                        borderRadius: BorderRadius.circular(16),
                        child: Transform.scale(scale: 1.02, child: child),
                      );
                    },
                    child: child,
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _treinos.removeAt(oldIndex);
                    _treinos.insert(newIndex, item);
                  });
                },
                children: List.generate(_treinos.length, (index) {
                  final treino = _treinos[index];
                  return Container(
                    key: ValueKey(treino),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: AppTheme.surfaceDark,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withAlpha(15)),
                      ),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConfigurarExerciciosPage(
                                nomeTreino: treino.nomeController.text,
                                exercicios: treino.exercicios,
                              ),
                            ),
                          );
                          setState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 16),
                                  child: Icon(
                                    Icons.drag_indicator,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
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
                                      treino.nomeController.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      treino.exercicios.isEmpty
                                          ? 'Toque para configurar exercícios'
                                          : '${treino.exercicios.length} ${treino.exercicios.length == 1 ? 'exercício configurado' : 'exercícios configurados'}',
                                      style: TextStyle(
                                        color: treino.exercicios.isEmpty
                                            ? AppTheme.textSecondary
                                            : AppTheme.primary,
                                        fontSize: 13,
                                        fontWeight: treino.exercicios.isEmpty
                                            ? FontWeight.normal
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: AppTheme.textSecondary,
                                ),
                                color: AppTheme.surfaceLight,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (value) async {
                                  if (value == 'edit') _editarTreino(index);
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
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Editar dados',
                                          style: TextStyle(color: Colors.white),
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
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Excluir sessão',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _adicionarTreino,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Adicionar nova sessão',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.white.withAlpha(50), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 48),

            ElevatedButton(
              onPressed: _isLoading ? null : _salvarRotina,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size(double.infinity, 56),
                elevation: _isLoading ? 0 : 8,
                shadowColor: AppTheme.primary.withAlpha(128),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'Salvar Rotina Completa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.textSecondary.withAlpha(128)),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
