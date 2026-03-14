import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/exercise_service.dart'; // Importamos o serviço novo
import 'models/exercicio_model.dart';

class ExerciciosLibraryPage extends StatefulWidget {
  const ExerciciosLibraryPage({super.key});

  @override
  State<ExerciciosLibraryPage> createState() => _ExerciciosLibraryPageState();
}

class _ExerciciosLibraryPageState extends State<ExerciciosLibraryPage> {
  // Criamos uma instância do serviço
  final ExerciseService _exerciseService = ExerciseService();

  // Variável para guardar o "futuro" dos dados
  late Future<List<ExercicioItem>> _futureExercicios;

  final List<String> _categorias = [
    'Tudo',
    'Peito',
    'Costas',
    'Pernas',
    'Ombros',
    'Braços',
  ];
  String _categoriaSelecionada = 'Tudo';
  final Set<int> _selecionados = {};

  @override
  void initState() {
    super.initState();
    // Assim que a tela abre, disparamos a busca na Cloud
    _futureExercicios = _exerciseService.buscarTodos();
  }

  void _confirmarSelecao(List<ExercicioItem> listaTotal) {
    // Pegamos os objetos ExercicioItem reais que foram marcados
    final selecionadosList = _selecionados.map((i) => listaTotal[i]).toList();
    Navigator.pop(context, selecionadosList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      // ... (AppBar e botões permanecem iguais, apenas passamos a lista real no confirmarSelecao)
      body: Column(
        children: [
          // ... (Barra de busca e Chips permanecem iguais)

          // 3. A MÁGICA ACONTECE AQUI: O FutureBuilder
          Expanded(
            child: FutureBuilder<List<ExercicioItem>>(
              future: _futureExercicios,
              builder: (context, snapshot) {
                // ESTADO 1: Carregando
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                // ESTADO 2: Erro (Cloud offline ou falha de rede)
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                // ESTADO 3: Sucesso (Os dados chegaram!)
                final exerciciosDaApi = snapshot.data ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  itemCount: exerciciosDaApi.length,
                  itemBuilder: (context, index) {
                    final ex = exerciciosDaApi[index];
                    final isSelected = _selecionados.contains(index);

                    return GestureDetector(
                      onTap: () => setState(() {
                        if (isSelected)
                          _selecionados.remove(index);
                        else
                          _selecionados.add(index);
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // GIF vindo da Cloud
                            ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.network(
                                ex.imagemUrl ?? '',
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                // Placeholder enquanto o GIF carrega da internet
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppTheme.surfaceLight,
                                  child: const Icon(Icons.fitness_center),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex.nome,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                            // ... (Checkmark de seleção permanece igual)
                          ],
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
    );
  }
}
