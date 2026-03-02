import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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

  // Agora usamos uma lista de Controllers para que cada treino possa ter seu nome editado dinamicamente
  final List<TextEditingController> _treinoControllers = [
    TextEditingController(text: 'Treino A'),
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _objetivoController.dispose();
    for (var controller in _treinoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _adicionarTreino() {
    setState(() {
      final proximasLetras = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
      final proximaLetra =
          proximasLetras[_treinoControllers.length % proximasLetras.length];
      _treinoControllers.add(
        TextEditingController(text: 'Treino $proximaLetra'),
      );
    });
  }

  void _removerTreino(int index) {
    setState(() {
      _treinoControllers[index]
          .dispose(); // Boa prática: descartar o controller da memória
      _treinoControllers.removeAt(index);
    });
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
                  '${_treinoControllers.length} sessões',
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _treinoControllers.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withAlpha(13)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Campo de Texto Editável para o Nome do Treino
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _treinoControllers[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Nome do treino',
                                    hintStyle: TextStyle(
                                      color: AppTheme.textSecondary.withAlpha(
                                        128,
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '0 exercícios adicionados',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Menu de opções (Editar / Excluir)
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: AppTheme.textSecondary,
                            ),
                            onSelected: (value) {
                              if (value == 'editar') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Editar ${_treinoControllers[index].text}',
                                    ),
                                  ),
                                );
                              } else if (value == 'excluir') {
                                _removerTreino(index);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'editar',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: AppTheme.textSecondary,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'excluir',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Colors.redAccent,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Excluir',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Colors.white10, height: 1),
                      ),

                      // Botão claro para abrir a lista de exercícios daquele treino específico
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'UI: Abrir construtor de exercícios para "${_treinoControllers[index].text}"',
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fitness_center,
                                color: AppTheme.primary.withAlpha(204),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Configurar Exercícios',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

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
