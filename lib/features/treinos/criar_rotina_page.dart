import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'configurar_exercicios_page.dart';

// estrutura de dados usada internamente pela página
class _TreinoData {
  final TextEditingController nomeController;
  String? diaSemana;
  String? orientacoes;

  _TreinoData({required this.nomeController, this.diaSemana, this.orientacoes});
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

  final List<_TreinoData> _treinos = [];

  @override
  void dispose() {
    _nomeController.dispose();
    _objetivoController.dispose();
    for (var t in _treinos) {
      t.nomeController.dispose();
    }
    super.dispose();
  }

  // helper sheet for both adding and editing a treino
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                initialNome == null ? 'Nova Sessão' : 'Editar Sessão',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nomeCtr,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Ex: Treino A',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: diaSemana,
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
                decoration: const InputDecoration(
                  labelText: 'Dia da semana (opcional)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: orientacoesCtr,
                decoration: const InputDecoration(
                  labelText: 'Orientações gerais',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'nome': nomeCtr.text,
                        'diaSemana': diaSemana,
                        'orientacoes': orientacoesCtr.text,
                      });
                    },
                    child: Text(initialNome == null ? 'Adicionar' : 'Salvar'),
                  ),
                ],
              ),
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
        title: const Text('Excluir sessão?'),
        content: const Text('Tem certeza que deseja remover esta sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _treinos.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Excluir'),
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
          ),
        );
      });
    }
  }

  void _salvarRotina() {
    // Modo Front-end First: apenas exibe o feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('UI: Rotina salva com sucesso!'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
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

            // LISTA DINÂMICA DE TREINOS EDITÁVEIS
            if (_treinos.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(40),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 48,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma sessão adicionada',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Clique em "Adicionar nova sessão" para começar',
                      style: TextStyle(
                        color: AppTheme.textSecondary.withAlpha(128),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _treinos.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        // NAVEGAÇÃO PARA CONFIGURAR EXERCÍCIOS
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConfigurarExerciciosPage(
                              nomeTreino: _treinos[index].nomeController.text,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withAlpha(13)),
                        ),
                        child: Row(
                          children: [
                            // Badge de Letra (A, B, C...)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Título e Contador
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _treinos[index].nomeController.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Toque para configurar exercícios',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
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
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    _editarTreino(index);
                                    break;
                                  case 'config':
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ConfigurarExerciciosPage(
                                              nomeTreino: _treinos[index]
                                                  .nomeController
                                                  .text,
                                            ),
                                      ),
                                    );
                                    break;
                                  case 'delete':
                                    _excluirTreino(index);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Editar informações'),
                                ),
                                const PopupMenuItem(
                                  value: 'config',
                                  child: Text('Configurar exercícios'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Excluir'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            // BOTÃO DE ADICIONAR NOVA SESSÃO
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _adicionarTreino,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Adicionar nova sessão',
                style: TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.white.withAlpha(51)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(
              height: 100,
            ), // Espaço para não ficar embaixo do botão flutuante
          ],
        ),
      ),

      // Botão Principal de Salvar
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ElevatedButton(
          onPressed: _salvarRotina,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            minimumSize: const Size(double.infinity, 56),
            elevation: 8,
            shadowColor: AppTheme.primary.withAlpha(128),
          ),
          child: const Text(
            'Salvar Rotina Completa',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para os inputs ficarem bonitos e padronizados
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
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }
}
