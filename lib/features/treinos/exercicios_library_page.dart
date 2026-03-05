import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/appfit_simple_app_bar.dart';

class ExerciciosLibraryPage extends StatefulWidget {
  const ExerciciosLibraryPage({super.key});

  @override
  State<ExerciciosLibraryPage> createState() => _ExerciciosLibraryPageState();
}

class _ExerciciosLibraryPageState extends State<ExerciciosLibraryPage> {
  final List<String> _categorias = [
    'Todos',
    'Peito',
    'Costas',
    'Pernas',
    'Braços',
    'Ombros',
  ];
  String _categoriaSelecionada = 'Todos';

  // Mock de dados da biblioteca
  final List<Map<String, String>> _biblioteca = [
    {'nome': 'Supino Reto', 'musculo': 'Peito'},
    {'nome': 'Agachamento Livre', 'musculo': 'Pernas'},
    {'nome': 'Puxada Frontal', 'musculo': 'Costas'},
    {'nome': 'Rosca Direta', 'musculo': 'Braços'},
    {'nome': 'Desenvolvimento', 'musculo': 'Ombros'},
    {'nome': 'Leg Press 45', 'musculo': 'Pernas'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppFitSimpleAppBar(
        title: 'Biblioteca de Exercícios',
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. BARRA DE BUSCA MODERNA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Pesquisar exercício...',
                hintStyle: TextStyle(
                  color: AppTheme.textSecondary.withAlpha(128),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.textSecondary,
                ),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. FILTROS RÁPIDOS (CHIPS)
          SizedBox(
            height: 60,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    onSelected: (val) =>
                        setState(() => _categoriaSelecionada = cat),
                    selectedColor: AppTheme.primary.withAlpha(51),
                    backgroundColor: AppTheme.surfaceDark,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primary.withAlpha(128)
                          : Colors.white.withAlpha(13),
                    ),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),

          // 3. LISTA DE EXERCÍCIOS
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _biblioteca.length,
              itemBuilder: (context, index) {
                final ex = _biblioteca[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withAlpha(13)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    title: Text(
                      ex['nome']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      ex['musculo']!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.primary,
                    ),
                    onTap: () {
                      // Retorna o nome do exercício selecionado para a página anterior
                      Navigator.pop(context, ex['nome']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${ex['nome']} adicionado ao treino!'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
